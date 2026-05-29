import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/firebase_database_refs.dart';
import '../models/history_model.dart';

class HistoryViewModel extends BaseViewModel {
  HistoryViewModel({FirebaseDatabase? database, FirebaseAuth? auth})
    : _database = database,
      _auth = auth ?? FirebaseAuth.instance {
    _bind();
  }

  final FirebaseDatabase? _database;
  final FirebaseAuth _auth;

  final Map<String, Map<String, dynamic>> _completedOrders = {};
  final Map<String, Map<String, dynamic>> _globalOrders = {};
  final Map<String, Map<String, dynamic>> _riderEarnings = {};
  final Map<String, Map<String, dynamic>> _userEarnings = {};
  Map<String, dynamic> _riderStats = const {};

  StreamSubscription<DatabaseEvent>? _completedOrdersSub;
  StreamSubscription<DatabaseEvent>? _globalOrdersSub;
  StreamSubscription<DatabaseEvent>? _riderEarningsSub;
  StreamSubscription<DatabaseEvent>? _userEarningsSub;
  StreamSubscription<DatabaseEvent>? _statsSub;

  RiderHistoryModel _model = const RiderHistoryModel(
    totalTrips: 0,
    completedTrips: 0,
    cancelledTrips: 0,
    totalEarnings: 0,
    availableBalance: 0,
    hoursOnline: 0,
    trips: [],
  );

  RiderHistoryModel get model => _model;

  Future<void> refresh() async {
    await _cancelStreams();
    _bind();
  }

  void setFilter(RiderHistoryFilter filter) {
    if (_model.filter == filter) return;
    _model = _model.copyWith(filter: filter);
    notifyListeners();
  }

  void _bind() {
    final db = _maybeDatabase();
    final riderId = _auth.currentUser?.uid;
    if (db == null || riderId == null || riderId.isEmpty) {
      _model = _model.copyWith(
        error: 'Login with rider account to see realtime history.',
      );
      notifyListeners();
      return;
    }

    setBusy(true);

    _completedOrdersSub = db.ref('users/riders/$riderId/completedOrders').onValue.listen((event) {
      _completedOrders
        ..clear()
        ..addAll(_mapOfMaps(event.snapshot));
      _rebuild();
    }, onError: _setError);

    _globalOrdersSub = db
        .ref('orders')
        .orderByChild('assignedRiderId')
        .equalTo(riderId)
        .onValue
        .listen((event) {
          _globalOrders
            ..clear()
            ..addAll(_mapOfMaps(event.snapshot));
          _rebuild();
        }, onError: (_) {});

    _riderEarningsSub = db.ref('riderEarnings/$riderId').onValue.listen((event) {
      _riderEarnings
        ..clear()
        ..addAll(_mapOfMaps(event.snapshot));
      _rebuild();
    }, onError: (_) {});

    _userEarningsSub = db.ref('users/riders/$riderId/earnings').onValue.listen((event) {
      _userEarnings
        ..clear()
        ..addAll(_mapOfMaps(event.snapshot));
      _rebuild();
    }, onError: (_) {});

    _statsSub = db.ref('riderStats/$riderId').onValue.listen((event) {
      final value = event.snapshot.value;
      _riderStats = value is Map ? Map<String, dynamic>.from(value) : const {};
      _rebuild();
    }, onError: (_) {});
  }

  void _rebuild() {
    final orders = <String, Map<String, dynamic>>{};
    orders.addAll(_globalOrders);
    orders.addAll(_completedOrders);

    final earnings = <String, Map<String, dynamic>>{};
    earnings.addAll(_userEarnings);
    earnings.addAll(_riderEarnings);

    final trips = <RiderHistoryTrip>[];
    for (final entry in orders.entries) {
      final status = _status(entry.value);
      if (status == null) continue;
      final earning = _findEarning(entry.key, entry.value, earnings);
      final timestamp = _timestamp(entry.value, earning);
      trips.add(
        RiderHistoryTrip(
          id: _text(entry.value, const ['id', 'orderId'], fallback: entry.key),
          orderKey: entry.key,
          storeName: _text(entry.value, const ['storeName', 'sellerName', 'shopName'], fallback: 'Seller'),
          customerName: _text(entry.value, const ['customerName', 'buyerName'], fallback: 'Customer'),
          pickupAddress: _text(entry.value, const ['sellerAddress', 'pickupAddress', 'shopAddress'], fallback: 'Seller pickup'),
          dropOffAddress: _text(entry.value, const ['deliveryAddress', 'customerAddress', 'dropOffAddress'], fallback: 'Customer location'),
          itemSummary: _text(entry.value, const ['items', 'itemSummary'], fallback: '${(_num(entry.value['itemCount']) ?? 1).round()} item'),
          earning: _earningAmount(entry.value, earning),
          orderAmount: _num(entry.value['amount']) ?? _money(entry.value['paymentAmount']?.toString() ?? '') ?? 0,
          paymentMethod: _text(entry.value, const ['paymentMethod', 'paymentType', 'method'], fallback: 'Cash'),
          status: status,
          dateLabel: _dateLabel(timestamp),
          timestamp: timestamp,
          distanceKm: _num(entry.value['distanceKm']),
          rating: _num(entry.value['rating']),
        ),
      );
    }

    trips.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final completedTrips = trips.where((trip) => trip.status == RiderHistoryStatus.completed).length;
    final cancelledTrips = trips.where((trip) => trip.status == RiderHistoryStatus.cancelled).length;
    final totalEarnings = trips
        .where((trip) => trip.status == RiderHistoryStatus.completed)
        .fold<double>(0, (sum, trip) => sum + trip.earning);
    final availableBalance = _availableBalance(earnings, fallback: totalEarnings);

    _model = _model.copyWith(
      totalTrips: completedTrips,
      completedTrips: completedTrips,
      cancelledTrips: cancelledTrips,
      totalEarnings: totalEarnings,
      availableBalance: availableBalance,
      hoursOnline: _hoursOnline(),
      trips: trips,
      clearError: true,
    );
    setBusy(false);
    notifyListeners();
  }

  void _setError(Object error) {
    setBusy(false);
    _model = _model.copyWith(
      error:
          'Realtime history is blocked by Firebase Database rules. Deploy database.rules.json and reopen the rider app.',
    );
    notifyListeners();
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return _database ?? vyraalDatabase;
    } catch (_) {
      return null;
    }
  }

  Map<String, Map<String, dynamic>> _mapOfMaps(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is! Map) return const {};
    final result = <String, Map<String, dynamic>>{};
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is Map) {
        result[entry.key.toString()] = Map<String, dynamic>.from(raw);
      }
    }
    return result;
  }

  RiderHistoryStatus? _status(Map<String, dynamic> json) {
    final value = '${json['status'] ?? ''} ${json['requestStatus'] ?? ''} ${json['deliveryStage'] ?? ''}'.toLowerCase();
    if (value.contains('deliver') || value.contains('complete') || json['completedAt'] != null || json['deliveredAt'] != null) {
      return RiderHistoryStatus.completed;
    }
    if (value.contains('cancel') || value.contains('reject') || value.contains('failed')) {
      return RiderHistoryStatus.cancelled;
    }
    return null;
  }

  Map<String, dynamic>? _findEarning(String key, Map<String, dynamic> order, Map<String, Map<String, dynamic>> earnings) {
    if (earnings.containsKey(key)) return earnings[key];
    final orderId = _text(order, const ['id', 'orderId', 'orderKey']);
    for (final entry in earnings.entries) {
      final value = _text(entry.value, const ['id', 'orderId', 'orderKey']);
      if (entry.key == orderId || value == key || value == orderId) return entry.value;
    }
    return null;
  }

  double _earningAmount(Map<String, dynamic> order, Map<String, dynamic>? earning) {
    return _num(earning?['amount']) ??
        _num(earning?['deliveryFee']) ??
        _num(order['earning']) ??
        _num(order['riderEarning']) ??
        _num(order['deliveryFee']) ??
        _money(order['estimatedEarning']?.toString() ?? '') ??
        0;
  }

  double _availableBalance(Map<String, Map<String, dynamic>> earnings, {required double fallback}) {
    if (earnings.isEmpty) return fallback;
    var total = 0.0;
    for (final earning in earnings.values) {
      final status = earning['status']?.toString().toLowerCase() ?? '';
      if (status.contains('paid') || status.contains('withdrawn')) continue;
      total += _num(earning['amount']) ?? _num(earning['deliveryFee']) ?? 0;
    }
    return total;
  }

  int _timestamp(Map<String, dynamic> order, Map<String, dynamic>? earning) {
    final timeline = order['timeline'];
    Object? timelineTime;
    if (timeline is Map) timelineTime = timeline['deliveredAt'] ?? timeline['completedAt'];
    return _toTimestamp(order['completedAt'] ?? order['deliveredAt'] ?? timelineTime ?? earning?['createdAt'] ?? order['updatedAt'] ?? order['createdAt']) ?? DateTime.now().millisecondsSinceEpoch;
  }

  double _hoursOnline() {
    return _num(_riderStats['hoursOnline']) ??
        _num(_riderStats['totalHoursOnline']) ??
        ((_num(_riderStats['onlineSeconds']) ?? _num(_riderStats['totalOnlineSeconds']) ?? 0) / 3600);
  }

  String _text(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  double? _num(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }

  double? _money(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  int? _toTimestamp(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }

  String _dateLabel(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $hour:$minute $amPm';
  }

  Future<void> _cancelStreams() async {
    await _completedOrdersSub?.cancel();
    await _globalOrdersSub?.cancel();
    await _riderEarningsSub?.cancel();
    await _userEarningsSub?.cancel();
    await _statsSub?.cancel();
  }

  @override
  void dispose() {
    unawaited(_cancelStreams());
    super.dispose();
  }
}
