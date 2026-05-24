import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebasePhoneAuthService {
  FirebasePhoneAuthService._();

  static final FirebasePhoneAuthService instance = FirebasePhoneAuthService._();

  String? _verificationId;
  int? _resendToken;
  String? _phoneNumber;

  String? get phoneNumber => _phoneNumber;
  bool get hasPendingVerification => _verificationId != null;

  Future<void> sendCode(String phoneNumber) async {
    _ensureFirebaseReady();

    final completer = Completer<void>();
    _phoneNumber = phoneNumber;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(_friendlyError(error));
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        if (_verificationId == null) {
          throw 'SMS code request timed out. Please try again.';
        }
      },
    );
  }

  Future<void> confirmCode(String smsCode) async {
    _ensureFirebaseReady();
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw 'Please request a new verification code first.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _verificationId = null;
    } on FirebaseAuthException catch (error) {
      throw _friendlyError(error);
    }
  }

  void _ensureFirebaseReady() {
    if (Firebase.apps.isEmpty) {
      throw 'Firebase is not configured for this platform yet.';
    }
  }

  String _friendlyError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => 'Enter a valid phone number.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'invalid-verification-code' => 'The verification code is incorrect.',
      'session-expired' =>
        'The verification session expired. Request a new code.',
      'quota-exceeded' => 'SMS quota exceeded. Please try again later.',
      _ => error.message ?? 'Phone verification failed. Please try again.',
    };
  }
}
