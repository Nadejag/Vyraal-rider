import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../features/withdraw/models/withdraw_model.dart';
import '../firebase_database_refs.dart';

class RiderWithdrawalRepository {
  RiderWithdrawalRepository({FirebaseDatabase? database}) : _database = database;

  final FirebaseDatabase? _database;

  bool get isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<WithdrawalSummary> watchSummary() {
    final database = _database ?? _maybeDatabase();
    final riderId = _riderId;
    if (database == null || riderId == null) {
      return Stream.value(WithdrawalSummary.empty());
    }

    return database.ref('users/riders/$riderId').onValue.map((event) {
      final root = _mapValue(event.snapshot.value);
      if (root == null) return WithdrawalSummary.empty();

      final earnings = _children(root['earnings']);
      final completedOrders = _children(root['completedOrders']);
      final withdrawals = _children(root['withdrawals'])
          .map((entry) => WithdrawalRequestModel.fromJson(entry.value, entry.key))
          .toList()
        ..sort((a, b) {
          final left = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final right = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return right.compareTo(left);
        });

      var totalEarned = 0;
      var todayEarnings = 0;
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      for (final entry in earnings) {
        final earning = entry.value;
        final amount = _intValue(
          earning['amount'] ?? earning['earning'] ?? earning['riderEarning'],
        );
        if (amount <= 0) continue;
        totalEarned += amount;

        final createdAt = _dateValue(earning['createdAt'] ?? earning['completedAt']);
        if (createdAt != null && !createdAt.isBefore(startOfToday)) {
          todayEarnings += amount;
        }
      }

      var pendingAmount = 0;
      var approvedAmount = 0;
      var paidAmount = 0;
      for (final request in withdrawals) {
        final amount = request.amount;
        switch (request.status) {
          case PayoutStatus.pending:
            pendingAmount += amount;
          case PayoutStatus.approved:
            approvedAmount += amount;
          case PayoutStatus.paid:
            paidAmount += amount;
          case PayoutStatus.draft:
          case PayoutStatus.rejected:
            break;
        }
      }

      final blockedAmount = pendingAmount + approvedAmount + paidAmount;
      final availableBalance = (totalEarned - blockedAmount).clamp(0, 1 << 31).toInt();
      final latestStatus = withdrawals.isEmpty
          ? PayoutStatus.draft
          : withdrawals.first.status;

      return WithdrawalSummary(
        availableBalance: availableBalance,
        totalEarned: totalEarned,
        pendingAmount: pendingAmount,
        approvedAmount: approvedAmount,
        paidAmount: paidAmount,
        todayEarnings: todayEarnings,
        completedTrips: completedOrders.isNotEmpty
            ? completedOrders.length
            : earnings.length,
        history: withdrawals,
        latestStatus: latestStatus,
        accountTitle: _stringValue(
          root['accountTitle'] ?? root['fullName'] ?? root['name'] ?? _riderName,
        ),
        easypaisaNumber: _stringValue(
          root['easypaisaNumber'] ??
              root['easypaisa'] ??
              root['wallets/easypaisa'] ??
              _riderPhone,
        ),
        jazzCashNumber: _stringValue(
          root['jazzCashNumber'] ??
              root['jazzcashNumber'] ??
              root['jazzCash'] ??
              _riderPhone,
        ),
      );
    }).handleError((_) => WithdrawalSummary.empty());
  }

  Future<bool> requestWithdrawal(WithdrawModel model) async {
    final database = _database ?? _maybeDatabase();
    final riderId = _riderId;
    if (database == null || riderId == null) return false;
    if (!model.canRequest) return false;

    final requestRef = database.ref('riderWithdrawalRequests').push();
    final requestId = requestRef.key;
    if (requestId == null) return false;

    final accountNumber = model.selectedAccountNumber.trim();
    final accountTitle = model.accountTitle.trim().isEmpty
        ? _riderName
        : model.accountTitle.trim();
    final now = ServerValue.timestamp;
    final method = model.selectedMethod.label;

    final request = <String, Object?>{
      'id': requestId,
      'type': 'rider',
      'role': 'rider',
      'userId': riderId,
      'riderId': riderId,
      'riderName': _riderName,
      'riderPhone': _riderPhone,
      'amount': model.withdrawalAmount,
      'serviceFee': model.serviceFee,
      'finalAmount': model.finalAmount,
      'method': method,
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'status': 'pending',
      'note': 'Rider withdrawal requested from Vyraal Rider app.',
      'availableBalanceAtRequest': model.availableBalance,
      'source': 'vyraal_rider_app',
      'createdAt': now,
      'updatedAt': now,
    };

    await database.ref().update({
      'riderWithdrawalRequests/$requestId': request,
      'users/riders/$riderId/withdrawals/$requestId': request,
      'riders/$riderId/withdrawals/$requestId': request,
      'payouts/withdrawals/$requestId': request,
      'admin/withdrawRequests/$requestId': request,
      'users/riders/$riderId/accountTitle': accountTitle,
      if (model.selectedMethod == PayoutMethod.easypaisa)
        'users/riders/$riderId/easypaisaNumber': accountNumber,
      if (model.selectedMethod == PayoutMethod.jazzCash)
        'users/riders/$riderId/jazzCashNumber': accountNumber,
      'users/riders/$riderId/updatedAt': now,
      'riders/$riderId/accountTitle': accountTitle,
      if (model.selectedMethod == PayoutMethod.easypaisa)
        'riders/$riderId/easypaisaNumber': accountNumber,
      if (model.selectedMethod == PayoutMethod.jazzCash)
        'riders/$riderId/jazzCashNumber': accountNumber,
      'riders/$riderId/updatedAt': now,
    });
    return true;
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return vyraalDatabase;
    } catch (_) {
      return null;
    }
  }

  String? get _riderId {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;
      return uid;
    } catch (_) {
      return null;
    }
  }

  String get _riderName {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName?.trim();
      if (name != null && name.isNotEmpty) return name;
      final phone = user?.phoneNumber?.trim();
      if (phone != null && phone.isNotEmpty) return phone;
    } catch (_) {}
    return 'Vyraal Rider';
  }

  String get _riderPhone {
    try {
      return FirebaseAuth.instance.currentUser?.phoneNumber?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}

class _MapEntry {
  const _MapEntry(this.key, this.value);

  final String key;
  final Map<String, dynamic> value;
}

Map<String, dynamic>? _mapValue(Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

List<_MapEntry> _children(Object? value) {
  final map = _mapValue(value);
  if (map == null) return const [];
  final entries = <_MapEntry>[];
  for (final entry in map.entries) {
    final child = _mapValue(entry.value);
    if (child == null) continue;
    entries.add(_MapEntry(entry.key.toString(), child));
  }
  return entries;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned)?.round() ?? 0;
  }
  return 0;
}

DateTime? _dateValue(Object? value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.round());
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _stringValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text;
}