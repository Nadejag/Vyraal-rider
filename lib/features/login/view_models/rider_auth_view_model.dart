import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/auth/firebase_phone_auth_service.dart';
import '../../../core/auth/rider_auth_service.dart';
import '../../../core/base/base_view_model.dart';
import '../models/login_model.dart';
import '../models/rider_user_model.dart';

class RiderAuthViewModel extends BaseViewModel {
  RiderAuthViewModel({
    FirebasePhoneAuthService? phoneAuthService,
    RiderAuthService? authService,
  })  : _phoneAuthService =
            phoneAuthService ?? FirebasePhoneAuthService.instance,
        _authService = authService ?? RiderAuthService();

  final FirebasePhoneAuthService _phoneAuthService;
  final RiderAuthService _authService;

  LoginModel _model = const LoginModel();
  RiderUserModel? _currentUser;

  LoginModel get model => _model;
  RiderUserModel? get currentUser => _currentUser;
  String get phoneNumber => _model.phoneNumber;
  bool get canSubmit => _digitsOnly(phoneNumber).length >= 7;
  bool get isLoggedIn => _currentUser != null;

  /// Initialize and check for saved session (one-time login)
  Future<String?> init() async {
    try {
      setBusy(true);

      // Check for saved user session
      final savedUser = await _authService.getSavedUser();
      if (savedUser != null) {
        _currentUser = savedUser;
        return AppRoutes.home; // User is already logged in
      }

      // Check Firebase auth state
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final user = await _authService.createOrFetchUser(
          firebaseUser.phoneNumber ?? '',
          uid: firebaseUser.uid,
        );
        _currentUser = user;
        return AppRoutes.home;
      }

      return AppRoutes.login; // No saved session, show login
    } catch (e) {
      debugPrint('Auth init error: $e');
      return AppRoutes.login;
    } finally {
      setBusy(false);
    }
  }

  void updatePhoneNumber(String value) {
    _model = _model.copyWith(phoneNumber: value);
    clearError();
    notifyListeners();
  }

  Future<String?> submit() async {
    if (!canSubmit) {
      setError('Enter a valid phone number.');
      return null;
    }

    setBusy(true);
    try {
      await _phoneAuthService.sendCode(_toPakistanE164(phoneNumber));
      return AppRoutes.verification;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }

  /// Set current user after successful verification
  Future<void> setCurrentUser(String phone, {String? uid}) async {
    try {
      final user =
          await _authService.createOrFetchUser(phone, uid: uid ?? '');
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting current user: $e');
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp('[^0-9]'), '');
  }

  String _toPakistanE164(String value) {
    var digits = _digitsOnly(value);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('92')) return '+$digits';
    return '+92$digits';
  }
}
