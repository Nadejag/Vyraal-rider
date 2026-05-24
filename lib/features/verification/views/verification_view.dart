import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/ui_polish.dart';
import '../view_models/verification_view_model.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  static const _backgroundColor = Color(0xFFFAFAFF);
  static const _inkColor = Color(0xFF111827);
  static const _mutedColor = Color(0xFF5F5F63);
  static const _goldColor = Color(0xFFFFC914);
  static const _darkGoldColor = Color(0xFF6E5200);
  static const _borderGoldColor = Color(0xFFD3C7AC);
  static const _softBlueColor = Color(0xFFF0F4FF);
  static const _offlineColor = Color(0xFFA8ADB5);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VerificationViewModel(),
      child: const _VerificationContent(),
    );
  }
}

class _VerificationContent extends StatefulWidget {
  const _VerificationContent();

  @override
  State<_VerificationContent> createState() => _VerificationContentState();
}

class _VerificationContentState extends State<_VerificationContent> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<VerificationViewModel>();
    _controllers = List.generate(
      4,
      (index) => TextEditingController(text: viewModel.digitAt(index)),
    );
    _focusNodes = List.generate(4, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VerificationViewModel>(
      builder: (context, viewModel, _) {
        Future<void> verify() async {
          final route = await viewModel.verify();
          if (!context.mounted || route == null) return;

          Navigator.of(context).pushReplacementNamed(route);
        }

        return Scaffold(
          backgroundColor: VerificationView._backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const _VerificationHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth >= 600
                          ? 40.0
                          : 20.0;

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          22,
                          horizontalPadding,
                          16 + MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 430,
                              minHeight: constraints.maxHeight - 66,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FadeSlideIn(
                                  child: _VerificationIntro(
                                    phone: viewModel.phoneNumber,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 80),
                                  child: _CodeInputRow(
                                    controllers: _controllers,
                                    focusNodes: _focusNodes,
                                    onChanged: (index, value) {
                                      viewModel.updateDigit(index, value);
                                      if (viewModel.model.canVerify) verify();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 130),
                                  child: _ResendBlock(
                                    timerText: viewModel.timerText,
                                  ),
                                ),
                                if (viewModel.hasError) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    viewModel.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFB42318),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                SizedBox(height: _bottomGap(constraints)),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 180),
                                  child: _VerifyButton(
                                    isBusy: viewModel.isBusy,
                                    onPressed: verify,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const FadeSlideIn(
                                  delay: Duration(milliseconds: 230),
                                  child: _SecurityNotice(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _bottomGap(BoxConstraints constraints) {
    if (constraints.maxHeight < 540) return 18;
    if (constraints.maxHeight < 720) return 28;
    return 42;
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: VerificationView._borderGoldColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, size: 24),
            color: VerificationView._inkColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Vyraal',
              style: TextStyle(
                color: VerificationView._inkColor,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VerificationView._offlineColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'OFFLINE',
              style: TextStyle(
                color: Color(0xFF222222),
                fontSize: 12,
                height: 1,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationIntro extends StatelessWidget {
  const _VerificationIntro({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final displayPhone = phone.isEmpty ? 'your phone number' : phone;

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Verify Phone\n',
            style: TextStyle(
              color: VerificationView._inkColor,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const WidgetSpan(child: SizedBox(height: 24)),
          const TextSpan(text: 'We sent a 4-digit verification code to '),
          TextSpan(
            text: displayPhone,
            style: const TextStyle(color: VerificationView._inkColor),
          ),
          const TextSpan(text: '. Enter it below to continue.'),
        ],
      ),
      style: const TextStyle(
        color: VerificationView._mutedColor,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _CodeInputRow extends StatelessWidget {
  const _CodeInputRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 3 ? 0 : 10),
          child: _CodeBox(
            controller: controllers[index],
            focusNode: focusNodes[index],
            onChanged: (value) {
              onChanged(index, value);
              if (value.isNotEmpty && index < focusNodes.length - 1) {
                focusNodes[index + 1].requestFocus();
              }
              if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        cursorColor: VerificationView._inkColor,
        cursorWidth: 1.2,
        style: const TextStyle(
          color: VerificationView._inkColor,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: VerificationView._borderGoldColor,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFF006DFF), width: 2),
          ),
        ),
      ),
    );
  }
}

class _ResendBlock extends StatelessWidget {
  const _ResendBlock({required this.timerText});

  final String timerText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Didn't receive the code?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: VerificationView._mutedColor,
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 13,
          runSpacing: 8,
          children: [
            const Text(
              'Resend Code',
              style: TextStyle(
                color: Color(0xFFB9A565),
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                timerText,
                style: const TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ShimmerBox(
        enabled: isBusy,
        baseColor: VerificationView._goldColor,
        child: FilledButton(
          onPressed: isBusy ? null : onPressed,
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: VerificationView._goldColor,
            disabledBackgroundColor: VerificationView._goldColor.withValues(
              alpha: 0.58,
            ),
            foregroundColor: VerificationView._darkGoldColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: isBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VerificationView._darkGoldColor,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VERIFY'),
                    SizedBox(width: 13),
                    Icon(Icons.check_circle_outline_rounded, size: 21),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: VerificationView._softBlueColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE0E3EA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFC7A431),
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your security is our priority. Vyraal will never\n'
              'call you to ask for this verification code.',
              style: TextStyle(
                color: Color(0xFF312D26),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
