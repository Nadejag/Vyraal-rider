import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebasePhoneAuthService {
  FirebasePhoneAuthService._();

  static final FirebasePhoneAuthService instance = FirebasePhoneAuthService._();

  static const Duration resendTimeout = Duration(seconds: 60);

  String? _verificationId;
  int? _resendToken;
  String? _phoneNumber;

  String? get phoneNumber => _phoneNumber;
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  bool get hasPendingVerification => _verificationId != null;
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Sends Firebase OTP to the rider phone number.
  ///
  /// Returns true when Firebase auto-verifies instantly, otherwise false when
  /// manual OTP entry is required.
  Future<bool> sendCode(String phoneNumber, {bool forceResend = false}) async {
    _ensureFirebaseReady();

    final normalizedPhone = _normalizePakistanPhone(phoneNumber);
    final completer = Completer<bool>();
    _phoneNumber = normalizedPhone;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: forceResend ? _resendToken : null,
      timeout: resendTimeout,
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _verificationId = null;
          if (!completer.isCompleted) completer.complete(true);
        } catch (error) {
          if (!completer.isCompleted) {
            completer.completeError('Auto verification failed. Enter the SMS code manually.');
          }
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(_friendlyError(error));
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(false);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (_verificationId != null) return false;
        throw 'SMS code request timed out. Please try again.';
      },
    );
  }

  Future<bool> resendCode() async {
    final phone = _phoneNumber;
    if (phone == null || phone.isEmpty) {
      throw 'Please enter your phone number again.';
    }
    return sendCode(phone, forceResend: true);
  }

  Future<UserCredential> confirmCode(String smsCode) async {
    _ensureFirebaseReady();

    final cleanCode = smsCode.replaceAll(RegExp('[^0-9]'), '');
    if (cleanCode.length != 6) {
      throw 'Enter the 6-digit verification code.';
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      throw 'Please request a new verification code first.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanCode,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      _verificationId = null;
      return result;
    } on FirebaseAuthException catch (error) {
      throw _friendlyError(error);
    }
  }

  void clearPendingVerification() {
    _verificationId = null;
  }

  void _ensureFirebaseReady() {
    if (Firebase.apps.isEmpty) {
      throw 'Firebase is not configured for this platform yet.';
    }
  }

  String _normalizePakistanPhone(String value) {
    var digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('92')) return '+$digits';
    return '+92$digits';
  }

  String _friendlyError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => 'Enter a valid phone number.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'invalid-verification-code' => 'The verification code is incorrect.',
      'session-expired' => 'The verification session expired. Request a new code.',
      'quota-exceeded' => 'SMS quota exceeded. Please try again later.',
      'captcha-check-failed' => 'Phone verification check failed. Please try again.',
      'app-not-authorized' => 'This app is not authorized for Firebase Phone Auth.',
      _ => error.message ?? 'Phone verification failed. Please try again.',
    };
  }
}