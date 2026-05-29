import 'verification_view.dart';

/// Compatibility wrapper for projects/routes that still reference OtpScreen.
/// Your current rider OTP screen is VerificationView.
class OtpScreen extends VerificationView {
  const OtpScreen({super.key});
}
