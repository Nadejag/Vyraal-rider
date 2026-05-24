import '../../../config/routes/app_routes.dart';
import '../../../core/auth/firebase_phone_auth_service.dart';
import '../../../core/base/base_view_model.dart';
import '../models/verification_model.dart';

class VerificationViewModel extends BaseViewModel {
  VerificationViewModel({FirebasePhoneAuthService? phoneAuthService})
    : _phoneAuthService =
          phoneAuthService ?? FirebasePhoneAuthService.instance {
    final phoneNumber = _phoneAuthService.phoneNumber;
    if (phoneNumber != null) {
      _model = _model.copyWith(phoneNumber: phoneNumber);
    }
  }

  final FirebasePhoneAuthService _phoneAuthService;

  VerificationModel _model = const VerificationModel();

  VerificationModel get model => _model;
  String get phoneNumber => _model.phoneNumber;
  String get code => _model.code;
  String get timerText => _model.formattedTimer;

  String digitAt(int index) {
    if (index >= code.length) return '';
    return code[index];
  }

  void updateDigit(int index, String value) {
    final digit = value.isEmpty ? '' : value[value.length - 1];
    final digits = List<String>.generate(4, digitAt);
    digits[index] = digit;
    _model = _model.copyWith(code: digits.join());
    clearError();
    notifyListeners();
  }

  Future<String?> verify() async {
    if (!_model.canVerify) {
      setError('Enter the 4-digit verification code.');
      return null;
    }

    setBusy(true);
    try {
      await _phoneAuthService.confirmCode(code);
      return AppRoutes.home;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }
}
