import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/ui_polish.dart';
import '../view_models/login_view_model.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const _backgroundColor = Color(0xFFFAFAFF);
  static const _inkColor = Color(0xFF111827);
  static const _mutedColor = Color(0xFF5F5F63);
  static const _goldColor = Color(0xFFFFC914);
  static const _darkGoldColor = Color(0xFF6E5200);
  static const _fieldBorderColor = Color(0xFF8E816A);
  static const _softBlueColor = Color(0xFFEFF3FF);
  static const _dashColor = Color(0xFFD8C69B);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          Future<void> submit() async {
            final route = await viewModel.submit();
            if (!context.mounted || route == null) return;

            Navigator.of(context).pushReplacementNamed(route);
          }

          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 600
                      ? 40.0
                      : 18.0;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      22 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 430,
                          minHeight: constraints.maxHeight - 40,
                        ),
                        child: IntrinsicHeight(
                          child: Stack(
                            children: [
                              const Positioned(
                                right: 18,
                                bottom: 8,
                                child: _BottomRouteMark(),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _LoginHeader(),
                                  const SizedBox(height: 42),
                                  const FadeSlideIn(child: _RiderBadge()),
                                  const SizedBox(height: 18),
                                  const FadeSlideIn(
                                    delay: Duration(milliseconds: 70),
                                    child: _WelcomeCopy(),
                                  ),
                                  const SizedBox(height: 18),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 120),
                                    child: _PhoneNumberField(
                                      viewModel: viewModel,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 170),
                                    child: _ContinueButton(
                                      isBusy: viewModel.isBusy,
                                      onPressed: submit,
                                    ),
                                  ),
                                  if (viewModel.hasError) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      viewModel.errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFB42318),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  const FadeSlideIn(
                                    delay: Duration(milliseconds: 220),
                                    child: _SecureLoginPanel(),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 60),
                                  const _TermsCopy(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vyraal',
          style: TextStyle(
            color: LoginView._inkColor,
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFE8EDFB),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF5E5E62),
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _RiderBadge extends StatelessWidget {
  const _RiderBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: LoginView._goldColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delivery_dining_rounded,
          color: LoginView._darkGoldColor,
          size: 31,
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Rider',
          style: TextStyle(
            color: LoginView._inkColor,
            fontSize: 27,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Enter your phone number to continue',
          style: TextStyle(
            color: LoginView._mutedColor,
            fontSize: 15,
            height: 1.15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({required this.viewModel});

  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: Color(0xFF463B1D),
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LoginView._fieldBorderColor),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: 76,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LoginView._goldColor.withValues(alpha: 0.16),
                  border: Border(
                    right: BorderSide(color: LoginView._dashColor, width: 1),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PK',
                      style: TextStyle(
                        color: LoginView._darkGoldColor,
                        fontSize: 11,
                        height: 1,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '+92',
                      style: TextStyle(
                        color: LoginView._inkColor,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9 -]')),
                    ],
                    onChanged: viewModel.updatePhoneNumber,
                    style: const TextStyle(
                      color: LoginView._inkColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.phone_iphone_rounded,
                        color: LoginView._darkGoldColor,
                        size: 20,
                      ),
                      hintText: '300 1234567',
                      hintStyle: TextStyle(
                        color: Color(0xFFCFC2AA),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: EdgeInsets.fromLTRB(0, 14, 12, 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ShimmerBox(
        enabled: isBusy,
        baseColor: LoginView._goldColor,
        child: FilledButton(
          onPressed: isBusy ? null : onPressed,
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: LoginView._goldColor,
            disabledBackgroundColor: LoginView._goldColor.withValues(
              alpha: 0.58,
            ),
            foregroundColor: LoginView._darkGoldColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: isBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LoginView._darkGoldColor,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue'),
                    SizedBox(width: 14),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SecureLoginPanel extends StatelessWidget {
  const _SecureLoginPanel();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: LoginView._dashColor,
        radius: 12,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: LoginView._softBlueColor.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.shield_outlined,
                color: LoginView._darkGoldColor,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure Login',
                    style: TextStyle(
                      color: LoginView._inkColor,
                      fontSize: 14,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "We'll send a verification code to this number\nvia SMS.",
                    style: TextStyle(
                      color: LoginView._mutedColor,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCopy extends StatelessWidget {
  const _TermsCopy();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            "By continuing, you agree to Vyraal's\n"
            'professional standards and local regulations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LoginView._mutedColor,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(
                  color: LoginView._darkGoldColor,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: Color(0xFFD2C5AD),
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: LoginView._darkGoldColor,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomRouteMark extends StatelessWidget {
  const _BottomRouteMark();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.38,
      child: CustomPaint(
        size: const Size(120, 130),
        painter: _RouteMarkPainter(),
      ),
    );
  }
}

class _RouteMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8D4A8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 28;

    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.15)
      ..lineTo(size.width * 0.20, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.96,
        size.width * 0.36,
        size.height * 0.96,
      )
      ..lineTo(size.width * 0.54, size.height * 0.96)
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.96,
        size.width * 0.69,
        size.height * 0.82,
      )
      ..lineTo(size.width * 0.69, size.height * 0.21)
      ..quadraticBezierTo(
        size.width * 0.69,
        size.height * 0.03,
        size.width * 0.88,
        size.height * 0.03,
      )
      ..quadraticBezierTo(
        size.width * 1.02,
        size.height * 0.03,
        size.width,
        size.height * 0.20,
      )
      ..lineTo(size.width, size.height * 0.82);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = LoginView._backgroundColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFFE8D4A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas
      ..drawCircle(Offset(size.width * 0.20, size.height * 0.15), 18, fillPaint)
      ..drawCircle(Offset(size.width * 0.20, size.height * 0.15), 18, dotPaint)
      ..drawCircle(Offset(size.width, size.height * 0.82), 18, fillPaint)
      ..drawCircle(Offset(size.width, size.height * 0.82), 18, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 5.0;
      const dashSpace = 4.0;

      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}
