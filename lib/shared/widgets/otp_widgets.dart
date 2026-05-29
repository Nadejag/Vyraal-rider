import 'package:flutter/material.dart';

class OtpCodeRow extends StatelessWidget {
  const OtpCodeRow({required this.digits, super.key});

  final List<String> digits;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          Expanded(
            child: OtpBox(
              label: i < digits.length ? digits[i] : '',
              filled: i < digits.length,
            ),
          ),
          if (i != 5) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class OtpBox extends StatelessWidget {
  const OtpBox({required this.label, required this.filled, super.key});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 55,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFFF5CC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? const Color(0xFFFFC914) : const Color(0xFFD3C7AC),
          width: filled ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class OtpKeypad extends StatelessWidget {
  const OtpKeypad({required this.onKeyPressed, super.key});

  final void Function(String key) onKeyPressed;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];

    return Column(
      children: [
        for (var row = 0; row < 4; row++) ...[
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                Expanded(
                  child: KeypadButton(
                    value: keys[row * 3 + col],
                    onPressed: () => onKeyPressed(keys[row * 3 + col]),
                  ),
                ),
                if (col != 2) const SizedBox(width: 12),
              ],
            ],
          ),
          if (row != 3) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class KeypadButton extends StatelessWidget {
  const KeypadButton({required this.value, required this.onPressed, super.key});

  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox(height: 50);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD3C7AC)),
          ),
          child: Center(
            child: value == 'back'
                ? const Icon(Icons.backspace_outlined, size: 20)
                : Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
