import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_database_refs.dart';

/// Real-time email notification service for the Vyraal Rider app.
///
/// This service writes every email event to Realtime Database for audit/visibility
/// and also creates a Firestore `mail` document through the Firestore REST API.
/// If the Firebase Trigger Email extension is installed on the `mail` collection,
/// those documents are sent out as real emails.
class RiderEmailNotificationService {
  RiderEmailNotificationService._();

  static final RiderEmailNotificationService instance =
      RiderEmailNotificationService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final http.Client _http = http.Client();

  String? _riderId;
  String? _riderEmail;
  String? _riderName;

  void bindRider(
    String? riderId, {
    String? email,
    String? name,
  }) {
    _riderId = riderId;
    updateRiderProfile(email: email, name: name);
  }

  void updateRiderProfile({String? email, String? name}) {
    final authEmail = _auth.currentUser?.email;
    final normalizedEmail = _cleanEmail(email) ?? _cleanEmail(authEmail);
    if (normalizedEmail != null) _riderEmail = normalizedEmail;
    if (name != null && name.trim().isNotEmpty) {
      _riderName = name.trim();
    }
  }

  Future<bool> sendRiderEmail({
    required String eventType,
    required String eventKey,
    required String subject,
    required String text,
    String? html,
    String? explicitTo,
    Map<String, Object?> extra = const {},
  }) {
    return sendEmail(
      eventType: eventType,
      eventKey: eventKey,
      subject: subject,
      text: text,
      html: html,
      explicitTo: explicitTo ?? _riderEmail,
      ownerRole: 'rider',
      ownerId: _riderId,
      extra: {
        'riderId': _riderId,
        'riderName': _riderName,
        ...extra,
      },
    );
  }

  Future<bool> sendEmail({
    required String eventType,
    required String eventKey,
    required String subject,
    required String text,
    String? html,
    String? explicitTo,
    String ownerRole = 'rider',
    String? ownerId,
    Map<String, Object?> extra = const {},
  }) async {
    final riderId = _riderId;
    final resolvedOwnerId = ownerId ?? riderId ?? _auth.currentUser?.uid;

    // Check local preferences first (fast)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('vyraal_rider_user');
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is Map && data.containsKey('emailNotificationsEnabled')) {
          if (data['emailNotificationsEnabled'] == false) {
            debugPrint('Rider Email notifications disabled locally in settings.');
            return false;
          }
        }
      }
    } catch (_) {}

    // Check remote DB preferences (authoritative)
    if (resolvedOwnerId != null) {
      try {
        final snapshot = await vyraalDatabase
            .ref('users/riders/$resolvedOwnerId/emailNotificationsEnabled')
            .get()
            .timeout(const Duration(seconds: 2));
        if (snapshot.exists && snapshot.value == false) {
          debugPrint('Rider Email notifications disabled remotely in settings.');
          return false;
        }
      } catch (_) {}
    }

    final safeKey = _safeKey('${eventType}_$eventKey');
    final to =
        _cleanEmail(explicitTo) ??
        _riderEmail ??
        await _fetchSavedRiderEmail(resolvedOwnerId);

    final baseRecord = <String, Object?>{
      'id': safeKey,
      'eventType': eventType,
      'eventKey': eventKey,
      'ownerRole': ownerRole,
      'ownerId': resolvedOwnerId,
      'riderId': riderId,
      'to': to ?? '',
      'subject': subject,
      'text': text,
      'html': html ?? _plainTextToHtml(text),
      'status': to == null ? 'missing_email' : 'queued',
      'source': 'vyraal_rider_flutter',
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
      ...extra,
    };

    // Write audit record in Firebase Realtime Database
    await _writeRealtimeAudit(safeKey, baseRecord);

    if (to == null) return false;

    final alreadySent = await _isDuplicateAndMark(safeKey, baseRecord);
    if (alreadySent) return false;

    final firestoreQueued = await _writeFirestoreMail(
      to: to,
      subject: subject,
      text: text,
      html: html ?? _plainTextToHtml(text),
      metadata: {
        'eventType': eventType,
        'eventKey': eventKey,
        'ownerRole': ownerRole,
        'ownerId': resolvedOwnerId,
        'riderId': riderId,
        ...extra,
      },
    );

    final statusUpdate = <String, Object?>{
      'status': firestoreQueued ? 'firestore_queued' : 'firestore_failed',
      'firestoreQueued': firestoreQueued,
      'updatedAt': ServerValue.timestamp,
    };
    await _updateRealtimeStatus(safeKey, statusUpdate);
    return firestoreQueued;
  }

  Future<void> _writeRealtimeAudit(
    String safeKey,
    Map<String, Object?> record,
  ) async {
    try {
      final riderId = _riderId;
      final updates = <String, Object?>{
        'emailNotificationsQueue/$safeKey': record,
        'admin/emailNotifications/$safeKey': record,
      };
      if (riderId != null && riderId.isNotEmpty) {
        updates['users/riders/$riderId/emailNotifications/$safeKey'] =
            record;
      }
      await vyraalDatabase.ref().update(updates).timeout(const Duration(seconds: 4));
    } catch (error) {
      debugPrint('Rider email notification audit skipped: $error');
    }
  }

  Future<void> _updateRealtimeStatus(
    String safeKey,
    Map<String, Object?> status,
  ) async {
    try {
      final riderId = _riderId;
      final updates = <String, Object?>{
        'emailNotificationsQueue/$safeKey': status,
        'admin/emailNotifications/$safeKey': status,
      };
      if (riderId != null && riderId.isNotEmpty) {
        updates['users/riders/$riderId/emailNotifications/$safeKey'] = status;
      }
      await vyraalDatabase.ref().update(updates).timeout(const Duration(seconds: 4));
    } catch (error) {
      debugPrint('Rider email notification status update skipped: $error');
    }
  }

  Future<bool> _isDuplicateAndMark(
    String safeKey,
    Map<String, Object?> record,
  ) async {
    final riderId = _riderId ?? _auth.currentUser?.uid;
    if (riderId == null || riderId.isEmpty) return false;

    final triggerRef = vyraalDatabase.ref('emailTriggers/riders/$riderId/$safeKey');
    try {
      final snapshot = await triggerRef.get().timeout(const Duration(seconds: 3));
      if (snapshot.exists) return true;
      await triggerRef
          .set({
            'eventKey': safeKey,
            'status': 'created',
            'createdAt': ServerValue.timestamp,
            'subject': record['subject'],
          })
          .timeout(const Duration(seconds: 3));
      return false;
    } catch (error) {
      debugPrint('Rider email notification dedupe skipped: $error');
      return false;
    }
  }

  Future<bool> _writeFirestoreMail({
    required String to,
    required String subject,
    required String text,
    required String html,
    required Map<String, Object?> metadata,
  }) async {
    try {
      final projectId = Firebase.app().options.projectId;
      if (projectId.trim().isEmpty) return false;

      final token = await _auth.currentUser?.getIdToken();
      if (token == null || token.isEmpty) return false;

      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/mail',
      );

      final body = jsonEncode({
        'fields': {
          'to': {
            'arrayValue': {
              'values': [
                {'stringValue': to},
              ],
            },
          },
          'message': {
            'mapValue': {
              'fields': {
                'subject': {'stringValue': subject},
                'text': {'stringValue': text},
                'html': {'stringValue': html},
              },
            },
          },
          'source': {'stringValue': 'vyraal_rider_flutter'},
          'createdAt': {
            'timestampValue': DateTime.now().toUtc().toIso8601String(),
          },
          'metadata': {
            'mapValue': {
              'fields': _metadataToFirestoreFields(metadata),
            },
          },
        },
      });

      final response = await _http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint(
        'Rider Firestore mail queue failed: ${response.statusCode} ${response.body}',
      );
      return false;
    } catch (error) {
      debugPrint('Rider Firestore mail queue skipped: $error');
      return false;
    }
  }

  Map<String, dynamic> _metadataToFirestoreFields(Map<String, Object?> data) {
    final fields = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = _safeFirestoreField(entry.key);
      if (key.isEmpty || entry.value == null) continue;
      final value = entry.value;
      if (value is bool) {
        fields[key] = {'booleanValue': value};
      } else if (value is int) {
        fields[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        fields[key] = {'doubleValue': value};
      } else if (value is num) {
        fields[key] = {'doubleValue': value.toDouble()};
      } else {
        fields[key] = {'stringValue': value.toString()};
      }
    }
    return fields;
  }

  String _safeKey(String value) {
    return value.replaceAll(RegExp(r'[.#$\[\]/]'), '_').trim();
  }

  String _safeFirestoreField(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').trim();
  }

  String? _cleanEmail(String? value) {
    final email = value?.trim();
    if (email == null || email.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok ? email : null;
  }

  Future<String?> _fetchSavedRiderEmail(String? riderId) async {
    if (riderId == null || riderId.isEmpty) return null;
    try {
      final snapshot = await vyraalDatabase
          .ref('users/riders/$riderId/email')
          .get()
          .timeout(const Duration(seconds: 2));
      final email = _cleanEmail(snapshot.value?.toString());
      if (email != null) _riderEmail = email;
      return email;
    } catch (_) {
      return null;
    }
  }

  String _plainTextToHtml(String text) {
    final escaped = const HtmlEscape().convert(text);
    return '<div style="font-family:Arial,sans-serif;line-height:1.55;color:#222">'
        '${escaped.replaceAll('\n', '<br>')}'
        '</div>';
  }
}
