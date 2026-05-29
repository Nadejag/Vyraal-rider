import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_database_refs.dart';

class RiderReviewRepository {
  RiderReviewRepository({FirebaseDatabase? database}) : _database = database;

  final FirebaseDatabase? _database;

  Stream<RiderReviewSummary> watchMyReviewSummary({String? riderId}) {
    final database = _database ?? _maybeDatabase();
    final uid = riderId ?? FirebaseAuth.instance.currentUser?.uid;
    if (database == null || uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return database
        .ref('users/riders/$uid/reviewSummary')
        .onValue
        .map((event) => RiderReviewSummary.fromValue(event.snapshot.value));
  }

  Stream<List<RiderReviewModel>> watchMyReviews({String? riderId}) {
    final database = _database ?? _maybeDatabase();
    final uid = riderId ?? FirebaseAuth.instance.currentUser?.uid;
    if (database == null || uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return database.ref('users/riders/$uid/reviews').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const <RiderReviewModel>[];
      final reviews = <RiderReviewModel>[];
      for (final entry in value.entries) {
        final raw = entry.value;
        if (raw is! Map) continue;
        reviews.add(
          RiderReviewModel.fromJson(
            Map<String, dynamic>.from(raw),
            fallbackId: entry.key.toString(),
          ),
        );
      }
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return vyraalDatabase;
    } catch (_) {
      return null;
    }
  }
}

class RiderReviewSummary {
  const RiderReviewSummary({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  bool get hasReviews => reviewCount > 0;
  String get label => hasReviews
      ? '${rating.toStringAsFixed(1)} ★ ($reviewCount)'
      : 'No ratings yet';

  factory RiderReviewSummary.fromValue(Object? value) {
    if (value is! Map) return const RiderReviewSummary(rating: 0, reviewCount: 0);
    final data = Map<String, dynamic>.from(value);
    return RiderReviewSummary(
      rating: (data['rating'] as num? ?? 0).toDouble(),
      reviewCount: (data['reviewCount'] as num? ?? 0).toInt(),
    );
  }
}

class RiderReviewModel {
  const RiderReviewModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.sellerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String customerName;
  final String sellerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  factory RiderReviewModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
  }) {
    return RiderReviewModel(
      id: json['id']?.toString() ?? fallbackId,
      orderId: json['orderId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ??
          json['userName']?.toString() ??
          'Customer',
      sellerName: json['sellerName']?.toString() ?? 'Seller',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      comment: json['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
