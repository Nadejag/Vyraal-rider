import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/login/models/rider_user_model.dart';
import '../firebase_database_refs.dart';

class RiderAuthService {
  static const _userKey = 'vyraal_rider_user';
  static const _otpKey = 'vyraal_rider_otp';

  Future<bool> verifyOtp(String phone, String enteredOtp) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_otpKey);
    if (stored == null) return false;
    if (stored == enteredOtp) {
      await prefs.remove(_otpKey);
      return true;
    }
    return false;
  }

  /// Restores the saved rider session. This is the one-time auth entry point:
  /// if FirebaseAuth still has a user or SharedPreferences has a rider profile,
  /// the rider stays logged in until logout() is called.
  Future<RiderUserModel?> restoreSavedSession({bool refreshRemote = true}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final local = await getSavedUser();
    final uid = firebaseUser?.uid ?? local?.id;
    if (uid == null || uid.isEmpty) return null;

    if (refreshRemote) {
      final remote = await _fetchRemoteUser(uid);
      if (remote != null) {
        await _saveLocalOnly(remote);
        return remote;
      }
    }

    if (local != null) return local;
    final phone = firebaseUser?.phoneNumber ?? '';
    if (phone.isEmpty) return null;
    return createOrFetchUser(phone, uid: uid);
  }

  Future<bool> hasActiveSession() async => (await restoreSavedSession(refreshRemote: false)) != null;

  Future<RiderUserModel> createOrFetchUser(String phone, {String? uid}) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final effectiveUid = (uid?.trim().isNotEmpty == true ? uid!.trim() : firebaseUid) ??
        'rider_${DateTime.now().millisecondsSinceEpoch}';

    final raw = (await SharedPreferences.getInstance()).getString(_userKey);
    if (raw != null) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final user = RiderUserModel.fromJson(json);
      if (user.phone == phone && user.id == effectiveUid) {
        unawaited(_saveRemoteUser(user));
        return user;
      }
    }

    final remoteUser = await _fetchRemoteUser(effectiveUid);
    if (remoteUser != null && (remoteUser.phone == phone || phone.isEmpty)) {
      await _saveLocalOnly(remoteUser);
      return remoteUser;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newUser = RiderUserModel(
      id: effectiveUid,
      phone: phone,
      name: 'Rider',
      createdAt: now,
      updatedAt: now,
    );
    await saveUser(newUser);
    return newUser;
  }

  Future<void> saveUser(RiderUserModel user) async {
    await _saveLocalOnly(user);
    unawaited(_saveRemoteUser(user));
  }

  Future<void> _saveLocalOnly(RiderUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<RiderUserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return RiderUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_userKey);
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await getSavedUser();
    if (user != null) {
      unawaited(updateWorkStatus(user.id, 'offline'));
    }
    await prefs.remove(_userKey);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Phone auth may not be available on every platform during local testing.
    }
  }

  Stream<RiderUserModel?> watchUser(String? uid) {
    if (uid == null || uid.isEmpty) return const Stream.empty();

    return vyraalDatabase.ref('users/riders/$uid').onValue.map<RiderUserModel?>(
      (event) {
        final value = event.snapshot.value;
        if (value is! Map) return null;
        final rider = RiderUserModel.fromJson(Map<String, dynamic>.from(value));
        unawaited(_saveLocalOnly(rider));
        return rider;
      },
    ).handleError((Object error, StackTrace stackTrace) {
      debugPrint('Rider profile watch skipped: $error');
    });
  }

  Future<void> saveProfileSetup({
    required String riderId,
    required String phone,
    required String name,
    required String city,
    required String address,
    required String cnicNumber,
    required String licenseNumber,
    required String vehicleType,
    required String vehicleNumber,
    String jazzCashNumber = '',
    String easyPaisaNumber = '',
    String profilePhotoUrl = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{
      'id': riderId,
      'uid': riderId,
      'riderId': riderId,
      'phone': phone,
      'name': name.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'cnicNumber': cnicNumber.trim(),
      'licenseNumber': licenseNumber.trim(),
      'vehicleType': vehicleType.trim().isEmpty ? 'Bike' : vehicleType.trim(),
      'vehicleNumber': vehicleNumber.trim(),
      'jazzCashNumber': jazzCashNumber.trim(),
      'easyPaisaNumber': easyPaisaNumber.trim(),
      'profilePhotoUrl': profilePhotoUrl.trim(),
      'profilePhotoBase64': profilePhotoUrl.trim(),
      'role': 'rider',
      'status': 'active',
      'workStatus': 'offline',
      'isOnline': false,
      'isVerified': false,
      'canReceiveOrders': false,
      'verificationStatus': 'pending',
      'profileStatus': 'completed',
      'profileCompleted': true,
      'updatedAt': ServerValue.timestamp,
      'profileUpdatedAt': ServerValue.timestamp,
    };

    final existing = await _fetchRemoteUser(riderId);
    if (existing == null || existing.createdAt == 0) updates['createdAt'] = now;

    await _multiUpdateRider(riderId, updates);
    final latest = await _fetchRemoteUser(riderId);
    if (latest != null) await _saveLocalOnly(latest);
  }

  Future<void> submitDocumentVerification({
    required String riderId,
    required String phone,
    required String name,
    required String cnicNumber,
    required String licenseNumber,
    required String vehicleType,
    required String vehicleNumber,
    required String cnicFrontUrl,
    required String cnicBackUrl,
    required String licenseFrontUrl,
    required String vehiclePhotoUrl,
    required String profilePhotoUrl,
  }) async {
    final request = <String, dynamic>{
      'id': riderId,
      'riderId': riderId,
      'uid': riderId,
      'phone': phone,
      'name': name.trim(),
      'cnicNumber': cnicNumber.trim(),
      'licenseNumber': licenseNumber.trim(),
      'vehicleType': vehicleType.trim().isEmpty ? 'Bike' : vehicleType.trim(),
      'vehicleNumber': vehicleNumber.trim(),
      'cnicFrontUrl': cnicFrontUrl.trim(),
      'cnicBackUrl': cnicBackUrl.trim(),
      'licenseFrontUrl': licenseFrontUrl.trim(),
      'vehiclePhotoUrl': vehiclePhotoUrl.trim(),
      'profilePhotoUrl': profilePhotoUrl.trim(),
      'cnicFrontBase64': cnicFrontUrl.trim(),
      'cnicBackBase64': cnicBackUrl.trim(),
      'licenseFrontBase64': licenseFrontUrl.trim(),
      'vehiclePhotoBase64': vehiclePhotoUrl.trim(),
      'profilePhotoBase64': profilePhotoUrl.trim(),
      'profilePhotoBase64': profilePhotoUrl.trim(),
      'status': 'pending',
      'verificationStatus': 'pending',
      'documentStatus': 'pending',
      'profileStatus': 'completed',
      'isVerified': false,
      'canReceiveOrders': false,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    };

    await vyraalDatabase.ref().update({
      'riderVerifications/$riderId': request,
      'riderDocuments/$riderId': request,
      'riderVerificationDocuments/$riderId': request,
      'admin/riderVerifications/$riderId': request,
      'admin/riderDocuments/$riderId': request,
      'users/riders/$riderId/verificationStatus': 'pending',
      'users/riders/$riderId/documentStatus': 'pending',
      'users/riders/$riderId/isVerified': false,
      'users/riders/$riderId/canReceiveOrders': false,
      'users/riders/$riderId/workStatus': 'offline',
      'users/riders/$riderId/profilePhotoUrl': profilePhotoUrl.trim(),
      'users/riders/$riderId/profilePhotoBase64': profilePhotoUrl.trim(),
      'users/riders/$riderId/updatedAt': ServerValue.timestamp,
      'riders/$riderId/verificationStatus': 'pending',
      'riders/$riderId/documentStatus': 'pending',
      'riders/$riderId/isVerified': false,
      'riders/$riderId/canReceiveOrders': false,
      'riders/$riderId/workStatus': 'offline',
      'riders/$riderId/profilePhotoUrl': profilePhotoUrl.trim(),
      'riders/$riderId/profilePhotoBase64': profilePhotoUrl.trim(),
      'riders/$riderId/updatedAt': ServerValue.timestamp,
    }).timeout(const Duration(seconds: 8));
  }

  Future<void> updateWorkStatus(String riderId, String status) async {
    final user = await _fetchRemoteUser(riderId);
    final verified = user?.isVerified == true || user?.verificationStatus == 'approved';
    final normalized = status == 'online' && verified ? 'online' : 'offline';
    final isOnline = normalized == 'online';
    await vyraalDatabase.ref().update({
      'users/riders/$riderId/workStatus': normalized,
      'users/riders/$riderId/isOnline': isOnline,
      'users/riders/$riderId/canReceiveOrders': verified,
      'users/riders/$riderId/updatedAt': ServerValue.timestamp,
      'riders/$riderId/workStatus': normalized,
      'riders/$riderId/isOnline': isOnline,
      'riders/$riderId/canReceiveOrders': verified,
      'riders/$riderId/updatedAt': ServerValue.timestamp,
      'riderWorkStatus/$riderId/workStatus': normalized,
      'riderWorkStatus/$riderId/isOnline': isOnline,
      'riderWorkStatus/$riderId/canReceiveOrders': verified,
      'riderWorkStatus/$riderId/updatedAt': ServerValue.timestamp,
      'riderLiveLocations/$riderId/isOnline': isOnline,
      'riderLiveLocations/$riderId/workStatus': normalized,
      'riderLiveLocations/$riderId/canReceiveOrders': verified,
      'riderLiveLocations/$riderId/updatedAt': ServerValue.timestamp,
      'liveRiderLocations/$riderId/isOnline': isOnline,
      'liveRiderLocations/$riderId/workStatus': normalized,
      'liveRiderLocations/$riderId/canReceiveOrders': verified,
      'liveRiderLocations/$riderId/updatedAt': ServerValue.timestamp,
    }).timeout(const Duration(seconds: 5));
  }

  Future<RiderUserModel?> _fetchRemoteUser(String? uid) async {
    if (uid == null || uid.isEmpty) return null;
    try {
      final snapshot = await vyraalDatabase.ref('users/riders/$uid').get().timeout(const Duration(milliseconds: 2200));
      final value = snapshot.value;
      if (value is! Map) return null;
      return RiderUserModel.fromJson(Map<String, dynamic>.from(value));
    } catch (error) {
      debugPrint('Rider profile fetch skipped: $error');
      return null;
    }
  }

  Future<void> _saveRemoteUser(RiderUserModel user) async {
    final data = {
      ...user.toJson(),
      'id': user.id,
      'uid': user.id,
      'riderId': user.id,
      'role': 'rider',
      'updatedAt': ServerValue.timestamp,
    };
    try {
      await _multiUpdateRider(user.id, data).timeout(const Duration(seconds: 4));
    } catch (error) {
      debugPrint('Rider profile save skipped: $error');
    }
  }

  Future<void> _multiUpdateRider(String riderId, Map<String, dynamic> data) {
    return vyraalDatabase.ref().update({
      'users/riders/$riderId': data,
      'riders/$riderId': data,
      'riderProfiles/$riderId': data,
    });
  }
}