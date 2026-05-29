import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/auth/firebase_phone_auth_service.dart';
import '../../../core/auth/rider_auth_service.dart';
import '../../../core/services/rider_image_upload_service.dart';
import '../../login/models/rider_user_model.dart';
import '../models/verification_model.dart';

class VerificationViewModel extends ChangeNotifier {
  VerificationViewModel({
    FirebasePhoneAuthService? phoneAuthService,
    RiderAuthService? authService,
    RiderImageUploadService? imageUploadService,
  })  : _phoneAuthService = phoneAuthService ?? FirebasePhoneAuthService.instance,
        _authService = authService ?? RiderAuthService(),
        _imageUploadService = imageUploadService ?? RiderImageUploadService() {
    final phoneNumber = _phoneAuthService.phoneNumber;
    if (phoneNumber != null) {
      _model = _model.copyWith(phoneNumber: phoneNumber);
    }
    _startTimer();
    _loadCurrentUserIfAlreadySignedIn();
  }

  final FirebasePhoneAuthService _phoneAuthService;
  final RiderAuthService _authService;
  final RiderImageUploadService _imageUploadService;
  Timer? _timer;
  StreamSubscription<RiderUserModel?>? _profileSub;

  VerificationModel _model = const VerificationModel();
  bool _busy = false;
  String? _errorMessage;

  VerificationModel get model => _model;
  bool get isBusy => _busy;
  bool get busy => _busy;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  String? get errorMessage => _errorMessage;

  String get phoneNumber => _model.phoneNumber;
  String get code => _model.code;
  String get timerText => _model.formattedTimer;
  bool get canResend => _model.canResend && !_busy;
  bool get isOtpStep => _model.step == RiderVerificationStep.otp;
  bool get isProfileStep => _model.step == RiderVerificationStep.profileSetup;
  bool get isSubmittedStep => _model.step == RiderVerificationStep.submitted;
  bool get isApprovedStep => _model.step == RiderVerificationStep.approved;

  @override
  void dispose() {
    _timer?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  String digitAt(int index) {
    if (index >= code.length) return '';
    return code[index];
  }

  void updateDigit(int index, String value) {
    final digit = value.isEmpty ? '' : value[value.length - 1];
    final digits = List<String>.generate(VerificationModel.codeLength, digitAt);
    digits[index] = digit;
    _model = _model.copyWith(code: digits.join());
    clearError();
    notifyListeners();
  }

  void updateName(String value) => _patch(name: value);
  void updateCity(String value) => _patch(city: value);
  void updateAddress(String value) => _patch(address: value);
  void updateCnicNumber(String value) => _patch(cnicNumber: value);
  void updateLicenseNumber(String value) => _patch(licenseNumber: value);
  void updateVehicleType(String value) => _patch(vehicleType: value);
  void updateVehicleNumber(String value) => _patch(vehicleNumber: value);
  void updateJazzCashNumber(String value) => _patch(jazzCashNumber: value);
  void updateEasyPaisaNumber(String value) => _patch(easyPaisaNumber: value);
  void updateProfilePhotoUrl(String value) => _patch(profilePhotoUrl: value);
  void updateCnicFrontUrl(String value) => _patch(cnicFrontUrl: value);
  void updateCnicBackUrl(String value) => _patch(cnicBackUrl: value);
  void updateLicenseFrontUrl(String value) => _patch(licenseFrontUrl: value);
  void updateVehiclePhotoUrl(String value) => _patch(vehiclePhotoUrl: value);


  Future<void> pickProfilePhoto({ImageSource source = ImageSource.gallery}) =>
      _pickImage(source: source, apply: updateProfilePhotoUrl);

  Future<void> pickCnicFront({ImageSource source = ImageSource.gallery}) =>
      _pickImage(source: source, apply: updateCnicFrontUrl);

  Future<void> pickCnicBack({ImageSource source = ImageSource.gallery}) =>
      _pickImage(source: source, apply: updateCnicBackUrl);

  Future<void> pickLicenseFront({ImageSource source = ImageSource.gallery}) =>
      _pickImage(source: source, apply: updateLicenseFrontUrl);

  Future<void> pickVehiclePhoto({ImageSource source = ImageSource.gallery}) =>
      _pickImage(source: source, apply: updateVehiclePhotoUrl);

  Future<void> _pickImage({
    required ImageSource source,
    required ValueChanged<String> apply,
  }) async {
    if (_busy) return;
    setBusy(true);
    try {
      final picked = await _imageUploadService.pickDocumentImage(source: source);
      if (picked == null) return;
      if (picked.bytesLength > 900000) {
        setError('Image is still too large. Please choose a clearer compressed image.');
        return;
      }
      apply(picked.dataUri);
      clearError();
    } catch (error) {
      setError('Image upload failed: $error');
    } finally {
      setBusy(false);
    }
  }

  Future<String?> verify() async {
    if (!_model.canVerify) {
      setError('Enter the 6-digit verification code.');
      return null;
    }

    setBusy(true);
    try {
      await _phoneAuthService.confirmCode(code);
      await _createOrLoadRiderProfile();

      if (_model.step == RiderVerificationStep.approved) return AppRoutes.home;
      return null;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }

  Future<void> resendCode() async {
    if (!_model.canResend || _busy) return;
    final phone = _model.phoneNumber.trim();
    if (phone.isEmpty) {
      setError('Phone number missing. Go back and enter your phone again.');
      return;
    }

    setBusy(true);
    try {
      await _phoneAuthService.sendCode(phone);
      _model = _model.copyWith(code: '', secondsRemaining: 60);
      clearError(notify: false);
      _startTimer();
    } catch (error) {
      setError(error.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<String?> submitProfileAndDocuments() async {
    if (_model.riderId.isEmpty) {
      setError('Rider session expired. Please login again.');
      return null;
    }
    if (!_model.isProfileComplete) {
      setError('Complete name, city, address, CNIC and vehicle details.');
      return null;
    }
    if (!_model.hasMinimumDocuments) {
      setError('Upload CNIC front, CNIC back and bike/vehicle photo. License is recommended.');
      return null;
    }

    setBusy(true);
    try {
      await _authService.saveProfileSetup(
        riderId: _model.riderId,
        phone: _model.phoneNumber,
        name: _model.name,
        city: _model.city,
        address: _model.address,
        cnicNumber: _model.cnicNumber,
        licenseNumber: _model.licenseNumber,
        vehicleType: _model.vehicleType,
        vehicleNumber: _model.vehicleNumber,
        jazzCashNumber: _model.jazzCashNumber,
        easyPaisaNumber: _model.easyPaisaNumber,
        profilePhotoUrl: _model.profilePhotoUrl,
      );

      await _authService.submitDocumentVerification(
        riderId: _model.riderId,
        phone: _model.phoneNumber,
        name: _model.name,
        cnicNumber: _model.cnicNumber,
        licenseNumber: _model.licenseNumber,
        vehicleType: _model.vehicleType,
        vehicleNumber: _model.vehicleNumber,
        cnicFrontUrl: _model.cnicFrontUrl,
        cnicBackUrl: _model.cnicBackUrl,
        licenseFrontUrl: _model.licenseFrontUrl,
        vehiclePhotoUrl: _model.vehiclePhotoUrl,
        profilePhotoUrl: _model.profilePhotoUrl,
      );

      _model = _model.copyWith(
        step: RiderVerificationStep.submitted,
        verificationStatus: 'pending',
        workStatus: 'offline',
      );
      clearError(notify: false);
      notifyListeners();
      return AppRoutes.home;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  void setError(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  void clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  void _patch({
    String? name,
    String? city,
    String? address,
    String? cnicNumber,
    String? licenseNumber,
    String? vehicleType,
    String? vehicleNumber,
    String? jazzCashNumber,
    String? easyPaisaNumber,
    String? profilePhotoUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? licenseFrontUrl,
    String? vehiclePhotoUrl,
  }) {
    _model = _model.copyWith(
      name: name,
      city: city,
      address: address,
      cnicNumber: cnicNumber,
      licenseNumber: licenseNumber,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      jazzCashNumber: jazzCashNumber,
      easyPaisaNumber: easyPaisaNumber,
      profilePhotoUrl: profilePhotoUrl,
      cnicFrontUrl: cnicFrontUrl,
      cnicBackUrl: cnicBackUrl,
      licenseFrontUrl: licenseFrontUrl,
      vehiclePhotoUrl: vehiclePhotoUrl,
    );
    clearError(notify: false);
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_model.secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      _model = _model.copyWith(secondsRemaining: _model.secondsRemaining - 1);
      notifyListeners();
    });
  }

  Future<void> _loadCurrentUserIfAlreadySignedIn() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    await _createOrLoadRiderProfile(firebaseUser: firebaseUser);
  }

  Future<void> _createOrLoadRiderProfile({User? firebaseUser}) async {
    final user = firebaseUser ?? FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Firebase user not found after verification.';

    final phone = user.phoneNumber ?? _model.phoneNumber;
    final rider = await _authService.createOrFetchUser(phone, uid: user.uid);
    _applyRiderProfile(rider);
    _watchProfile(rider.id);
  }

  void _watchProfile(String riderId) {
    _profileSub?.cancel();
    _profileSub = _authService.watchUser(riderId).listen((rider) {
      if (rider == null) return;
      _applyRiderProfile(rider);
    });
  }

  void _applyRiderProfile(RiderUserModel rider) {
    final verificationStatus = rider.verificationStatus.trim().isEmpty
        ? 'not_submitted'
        : rider.verificationStatus;

    RiderVerificationStep step;
    if (verificationStatus == 'approved' || rider.isVerified) {
      step = RiderVerificationStep.approved;
    } else if (verificationStatus == 'pending') {
      step = RiderVerificationStep.submitted;
    } else {
      step = RiderVerificationStep.profileSetup;
    }

    _model = _model.copyWith(
      riderId: rider.id,
      phoneNumber: rider.phone.isEmpty ? _model.phoneNumber : rider.phone,
      name: rider.name == 'Rider' ? _model.name : rider.name,
      city: rider.city,
      address: rider.address,
      cnicNumber: rider.cnicNumber,
      licenseNumber: rider.licenseNumber,
      vehicleType: rider.vehicleType,
      vehicleNumber: rider.vehicleNumber,
      jazzCashNumber: rider.jazzCashNumber,
      easyPaisaNumber: rider.easyPaisaNumber,
      profilePhotoUrl: rider.profilePhotoUrl,
      cnicFrontUrl: rider.cnicFrontUrl,
      cnicBackUrl: rider.cnicBackUrl,
      licenseFrontUrl: rider.licenseFrontUrl,
      vehiclePhotoUrl: rider.vehiclePhotoUrl,
      verificationStatus: verificationStatus,
      rejectionReason: rider.rejectionReason,
      workStatus: rider.workStatus,
      step: step,
    );
    clearError(notify: false);
    notifyListeners();
  }
}
