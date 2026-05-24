import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/ui_polish.dart';
import '../models/withdraw_model.dart';
import '../view_models/withdraw_view_model.dart';

class WithdrawView extends StatelessWidget {
  const WithdrawView({super.key});

  static const _backgroundColor = Color(0xFFFAFAFF);
  static const _inkColor = Color(0xFF111827);
  static const _mutedColor = Color(0xFF5F5F63);
  static const _goldColor = Color(0xFFFFC914);
  static const _darkGoldColor = Color(0xFF6E5200);
  static const _borderGoldColor = Color(0xFFD3C7AC);
  static const _softBlueColor = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WithdrawViewModel(),
      child: Consumer<WithdrawViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const _WithdrawHeader(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPadding = constraints.maxWidth >= 600
                            ? 38.0
                            : 20.0;

                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            25 + MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: _WithdrawContent(model: viewModel.model),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const _WithdrawBottomNav(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WithdrawContent extends StatelessWidget {
  const _WithdrawContent({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(child: _BalanceCard(balance: model.availableBalance)),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: _AmountInput(amount: model.withdrawalAmount),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 110),
          child: _AmountChips(selectedAmount: model.withdrawalAmount),
        ),
        const SizedBox(height: 18),
        const Text(
          'Select Payout Method',
          style: TextStyle(
            color: WithdrawView._inkColor,
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: _PayoutCard(
            method: PayoutMethod.easypaisa,
            title: 'Easypaisa',
            subtitle: 'Instant Transfer',
            account: '0300 1234567',
            color: const Color(0xFF10B981),
            isSelected: model.selectedMethod == PayoutMethod.easypaisa,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 190),
          child: _PayoutCard(
            method: PayoutMethod.jazzCash,
            title: 'JazzCash',
            subtitle: 'Standard Transfer',
            color: const Color(0xFFF9828B),
            isSelected: model.selectedMethod == PayoutMethod.jazzCash,
          ),
        ),
        const SizedBox(height: 14),
        _WithdrawSummary(model: model),
        const SizedBox(height: 16),
        _WithdrawStatusTracker(status: model.payoutStatus),
        const SizedBox(height: 18),
        const _WithdrawNotice(),
        const SizedBox(height: 20),
        const _RequestWithdrawButton(),
      ],
    );
  }
}

class _WithdrawHeader extends StatelessWidget {
  const _WithdrawHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: WithdrawView._borderGoldColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: WithdrawView._darkGoldColor, width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFFEFE7CE), Color(0xFFFFC914)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Text(
              'VYRAAL',
              style: TextStyle(
                color: WithdrawView._inkColor,
                fontSize: 21,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WithdrawView._goldColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: Color(0xFF151515),
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: WithdrawView._goldColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: WithdrawView._darkGoldColor,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${_formatNumber(balance)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  const _AmountInput({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal Amount',
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: WithdrawView._darkGoldColor),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Rs.  '),
                TextSpan(
                  text: _formatNumber(amount),
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountChips extends StatelessWidget {
  const _AmountChips({required this.selectedAmount});

  final int selectedAmount;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<WithdrawViewModel>();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AmountChip(
          label: 'Rs. 1000',
          isSelected: selectedAmount == 1000,
          onTap: () => viewModel.setAmount(1000),
        ),
        _AmountChip(
          label: 'Rs. 2000',
          isSelected: selectedAmount == 2000,
          onTap: () => viewModel.setAmount(2000),
        ),
        _AmountChip(
          label: 'Rs. 5000',
          isSelected: selectedAmount == 5000,
          onTap: () => viewModel.setAmount(5000),
        ),
        _AmountChip(
          label: 'Max',
          isSelected: selectedAmount == viewModel.model.availableBalance,
          onTap: () => viewModel.setAmount(viewModel.model.availableBalance),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? WithdrawView._goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WithdrawView._borderGoldColor),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF303030),
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    this.account,
  });

  final PayoutMethod method;
  final String title;
  final String subtitle;
  final String? account;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<WithdrawViewModel>();

    return PressScale(
      onTap: () => viewModel.selectMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFCFCFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected
                ? WithdrawView._darkGoldColor
                : WithdrawView._borderGoldColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? WithdrawView._inkColor
                          : WithdrawView._mutedColor,
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected
                          ? WithdrawView._mutedColor
                          : const Color(0xFF9A9A9A),
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 34,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: WithdrawView._backgroundColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: WithdrawView._borderGoldColor,
                        ),
                      ),
                      child: Text(
                        account!,
                        style: const TextStyle(
                          color: WithdrawView._inkColor,
                          fontSize: 13,
                          height: 1,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_outline_rounded,
                color: WithdrawView._darkGoldColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSummary extends StatelessWidget {
  const _WithdrawSummary({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Withdrawal Amount',
            value: 'Rs. ${_formatNumber(model.withdrawalAmount)}',
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Service Fee (1.5%)',
            value: '- Rs. ${model.serviceFee}',
          ),
          const SizedBox(height: 14),
          const Divider(color: WithdrawView._borderGoldColor, height: 1),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Final to be Credited',
            value: 'Rs. ${_formatNumber(model.finalAmount)}',
            valueColor: WithdrawView._darkGoldColor,
          ),
        ],
      ),
    );
  }
}

class _WithdrawStatusTracker extends StatelessWidget {
  const _WithdrawStatusTracker({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final activeIndex = switch (status) {
      PayoutStatus.draft => -1,
      PayoutStatus.pending => 0,
      PayoutStatus.approved => 1,
      PayoutStatus.paid => 2,
    };
    const labels = ['Pending', 'Approved', 'Paid'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Status',
            style: TextStyle(
              color: WithdrawView._inkColor,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: _WithdrawStatusStep(
                    label: labels[i],
                    isActive: activeIndex >= i,
                  ),
                ),
                if (i != labels.length - 1)
                  Container(
                    width: 22,
                    height: 2,
                    color: activeIndex > i
                        ? WithdrawView._goldColor
                        : WithdrawView._borderGoldColor,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WithdrawStatusStep extends StatelessWidget {
  const _WithdrawStatusStep({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? WithdrawView._goldColor
                : WithdrawView._softBlueColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? WithdrawView._darkGoldColor
                  : WithdrawView._borderGoldColor,
            ),
          ),
          child: Icon(
            isActive ? Icons.check_rounded : Icons.schedule_rounded,
            color: WithdrawView._darkGoldColor,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? WithdrawView._inkColor
                  : WithdrawView._mutedColor,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = WithdrawView._inkColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _WithdrawNotice extends StatelessWidget {
  const _WithdrawNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: WithdrawView._softBlueColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: WithdrawView._darkGoldColor,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Transfers usually take 2-4 hours to\n'
              'reflect in your account. Please\n'
              'ensure your account details are\n'
              'correct to avoid delays.',
              style: TextStyle(
                color: Color(0xFF303030),
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestWithdrawButton extends StatelessWidget {
  const _RequestWithdrawButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ShimmerBox(
        enabled: context.watch<WithdrawViewModel>().isBusy,
        baseColor: WithdrawView._goldColor,
        child: FilledButton(
          onPressed: () =>
              context.read<WithdrawViewModel>().requestWithdrawal(),
          style: FilledButton.styleFrom(
            elevation: 5,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            backgroundColor: WithdrawView._goldColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              height: 1,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('REQUEST WITHDRAWAL'),
        ),
      ),
    );
  }
}

class _WithdrawBottomNav extends StatelessWidget {
  const _WithdrawBottomNav();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_outlined, 'Orders', AppRoutes.home),
      (Icons.payments_outlined, 'Earnings', AppRoutes.home),
      (Icons.history_rounded, 'History', AppRoutes.home),
      (Icons.person_outline_rounded, 'Profile', AppRoutes.home),
    ];

    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: WithdrawView._backgroundColor,
        border: Border(top: BorderSide(color: WithdrawView._borderGoldColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(items[index].$3, (route) => false),
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index].$1,
                          color: index == 1
                              ? WithdrawView._darkGoldColor
                              : WithdrawView._mutedColor,
                          size: 21,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[index].$2,
                          style: TextStyle(
                            color: index == 1
                                ? WithdrawView._darkGoldColor
                                : WithdrawView._mutedColor,
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final positionFromEnd = text.length - i;
    buffer.write(text[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
