import '../../../config/routes/app_routes.dart';
import '../../../core/auth/firebase_phone_auth_service.dart';
import '../../../core/base/base_view_model.dart';
import '../models/login_model.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel({FirebasePhoneAuthService? phoneAuthService})
    : _phoneAuthService = phoneAuthService ?? FirebasePhoneAuthService.instance;

  final FirebasePhoneAuthService _phoneAuthService;

  LoginModel _model = const LoginModel();

  LoginModel get model => _model;
  String get phoneNumber => _model.phoneNumber;
  bool get canSubmit => _digitsOnly(phoneNumber).length >= 7;

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
