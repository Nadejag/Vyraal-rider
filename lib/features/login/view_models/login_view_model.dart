import '../../../config/routes/app_routes.dart';
import '../../../core/auth/firebase_phone_auth_service.dart';
import '../../../core/auth/rider_auth_service.dart';
import '../../../core/base/base_view_model.dart';
import '../models/login_model.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel({
    FirebasePhoneAuthService? phoneAuthService,
    RiderAuthService? riderAuthService,
  }) : _phoneAuthService =
           phoneAuthService ?? FirebasePhoneAuthService.instance,
       _riderAuthService = riderAuthService ?? RiderAuthService();

  final FirebasePhoneAuthService _phoneAuthService;
  final RiderAuthService _riderAuthService;

  LoginModel _model = const LoginModel();
  String? _errorMessage;

  LoginModel get model => _model;
  String get phoneNumber => _model.phoneNumber;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  @override
  bool get isBusy => busy;
  bool get canSubmit => _digitsOnly(phoneNumber).length >= 7;

  void updatePhoneNumber(String value) {
    _model = _model.copyWith(phoneNumber: value);
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> submit() async {
    if (!canSubmit) {
      _setError('Enter a valid phone number.');
      return null;
    }

    setBusy(true);
    try {
      final normalizedPhone = _toPakistanE164(phoneNumber);
      final autoVerified = await _phoneAuthService.sendCode(normalizedPhone);

      if (autoVerified && _phoneAuthService.currentUserId != null) {
        await _riderAuthService.createOrFetchUser(
          normalizedPhone,
          uid: _phoneAuthService.currentUserId,
        );
        return AppRoutes.home;
      }

      return AppRoutes.verification;
    } catch (error) {
      _setError(error.toString());
      return null;
    } finally {
      setBusy(false);
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp('[^0-9]'), '');

  String _toPakistanE164(String value) {
    var digits = _digitsOnly(value);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('92')) return '+$digits';
    return '+92$digits';
  }
}
