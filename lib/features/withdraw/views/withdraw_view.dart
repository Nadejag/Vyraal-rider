import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  static const _successColor = Color(0xFF10B981);
  static const _dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WithdrawViewModel(),
      child: Consumer<WithdrawViewModel>(
        builder: (context, viewModel, _) {
          final model = viewModel.model;
          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const _WithdrawHeader(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPadding = constraints.maxWidth >= 600 ? 38.0 : 20.0;

                        return RefreshIndicator(
                          color: _darkGoldColor,
                          onRefresh: () async {
                            await Future<void>.delayed(const Duration(milliseconds: 350));
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              24,
                              horizontalPadding,
                              25 + MediaQuery.viewInsetsOf(context).bottom,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 430),
                                child: _WithdrawContent(model: model),
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
      ),
    );
  }
}

class _WithdrawContent extends StatelessWidget {
  const _WithdrawContent({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    if (model.isLoading) {
      return const _WithdrawLoadingState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (model.errorMessage != null) ...[
          _ErrorCard(message: model.errorMessage!),
          const SizedBox(height: 14),
        ],
        FadeSlideIn(child: _BalanceCard(model: model)),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 55),
          child: _StatsRow(model: model),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 85),
          child: _AmountInput(amount: model.withdrawalAmount),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 110),
          child: _AmountChips(model: model),
        ),
        const SizedBox(height: 18),
        const Text(
          'Payout Method',
          style: TextStyle(
            color: WithdrawView._inkColor,
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 145),
          child: _AccountTitleField(value: model.accountTitle),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 175),
          child: _PayoutCard(
            method: PayoutMethod.easypaisa,
            title: 'Easypaisa',
            subtitle: 'Manual/admin verified transfer',
            account: model.easypaisaNumber,
            color: const Color(0xFF10B981),
            isSelected: model.selectedMethod == PayoutMethod.easypaisa,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 205),
          child: _PayoutCard(
            method: PayoutMethod.jazzCash,
            title: 'JazzCash',
            subtitle: 'Manual/admin verified transfer',
            account: model.jazzCashNumber,
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
        const SizedBox(height: 22),
        _WithdrawalHistory(history: model.history),
      ],
    );
  }
}

class _WithdrawLoadingState extends StatelessWidget {
  const _WithdrawLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ShimmerBox(
            enabled: true,
            child: Container(
              height: index == 0 ? 118 : 72,
              decoration: BoxDecoration(
                color: WithdrawView._softBlueColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: WithdrawView._dangerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WithdrawView._dangerColor,
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
        border: Border(bottom: BorderSide(color: WithdrawView._borderGoldColor)),
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
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Text(
              'Withdraw Earnings',
              style: TextStyle(
                color: WithdrawView._inkColor,
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WithdrawView._goldColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'REALTIME',
              style: TextStyle(
                color: Color(0xFF151515),
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: WithdrawView._goldColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WithdrawView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available for Withdrawal',
            style: TextStyle(
              color: WithdrawView._darkGoldColor,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rs. ${_formatNumber(model.availableBalance)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 31,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total earned Rs. ${_formatNumber(model.totalEarned)} • Paid Rs. ${_formatNumber(model.paidAmount)}',
            style: const TextStyle(
              color: Color(0xFF3D3100),
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Today',
            value: 'Rs. ${_formatNumber(model.todayEarnings)}',
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Pending',
            value: 'Rs. ${_formatNumber(model.pendingAmount + model.approvedAmount)}',
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Trips',
            value: model.completedTrips.toString(),
            icon: Icons.route_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: WithdrawView._darkGoldColor, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WithdrawView._inkColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WithdrawView._mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountInput extends StatefulWidget {
  const _AmountInput({required this.amount});

  final int amount;

  @override
  State<_AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<_AmountInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amount == 0 ? '' : widget.amount.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.amount == 0 ? '' : widget.amount.toString();
    if (oldWidget.amount != widget.amount && _controller.text != next) {
      _controller.text = next;
      _controller.selection = TextSelection.collapsed(offset: next.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
            context.read<WithdrawViewModel>().setAmount(int.tryParse(cleaned) ?? 0);
          },
          decoration: InputDecoration(
            prefixText: 'Rs. ',
            hintText: 'Enter amount',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: WithdrawView._darkGoldColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountChips extends StatelessWidget {
  const _AmountChips({required this.model});

  final WithdrawModel model;

  @override
  Widget build(BuildContext context) {
    final suggestions = <int>{
      500,
      1000,
      2000,
      5000,
      if (model.availableBalance > 0) model.availableBalance,
    }.where((value) => value > 0 && value <= model.availableBalance).toList();

    if (suggestions.isEmpty) {
      return const Text(
        'Complete deliveries to build your withdrawable balance.',
        style: TextStyle(
          color: WithdrawView._mutedColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amount in suggestions)
          ChoiceChip(
            label: Text(amount == model.availableBalance ? 'Max' : 'Rs. ${_formatNumber(amount)}'),
            selected: model.withdrawalAmount == amount,
            onSelected: (_) => context.read<WithdrawViewModel>().setAmount(amount),
            selectedColor: WithdrawView._goldColor,
            backgroundColor: Colors.white,
            side: const BorderSide(color: WithdrawView._borderGoldColor),
            labelStyle: const TextStyle(
              color: WithdrawView._inkColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _AccountTitleField extends StatelessWidget {
  const _AccountTitleField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      textInputAction: TextInputAction.next,
      onChanged: context.read<WithdrawViewModel>().updateAccountTitle,
      decoration: InputDecoration(
        labelText: 'Account title',
        hintText: 'Name on JazzCash/Easypaisa account',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.badge_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: WithdrawView._darkGoldColor, width: 1.5),
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
    required this.account,
    required this.color,
    required this.isSelected,
  });

  final PayoutMethod method;
  final String title;
  final String subtitle;
  final String account;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => context.read<WithdrawViewModel>().selectMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFAE8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? WithdrawView._darkGoldColor : WithdrawView._borderGoldColor,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: WithdrawView._inkColor,
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: WithdrawView._mutedColor,
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: WithdrawView._darkGoldColor,
                    size: 23,
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: account,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onChanged: (value) => context.read<WithdrawViewModel>().updateAccountNumber(method, value),
                decoration: InputDecoration(
                  labelText: '$title number',
                  hintText: '03XXXXXXXXX',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: WithdrawView._borderGoldColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: WithdrawView._darkGoldColor, width: 1.5),
                  ),
                ),
              ),
            ],
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
            value: '- Rs. ${_formatNumber(model.serviceFee)}',
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
    if (status == PayoutStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: WithdrawView._dangerColor),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Last withdrawal was rejected. Please check account details and try again.',
                style: TextStyle(
                  color: WithdrawView._dangerColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = switch (status) {
      PayoutStatus.draft => -1,
      PayoutStatus.pending => 0,
      PayoutStatus.approved => 1,
      PayoutStatus.paid => 2,
      PayoutStatus.rejected => -1,
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
            'Latest Payment Status',
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
                    color: activeIndex > i ? WithdrawView._goldColor : WithdrawView._borderGoldColor,
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
            color: isActive ? WithdrawView._goldColor : WithdrawView._softBlueColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? WithdrawView._darkGoldColor : WithdrawView._borderGoldColor,
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
              color: isActive ? WithdrawView._inkColor : WithdrawView._mutedColor,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w800,
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
          Icon(Icons.info_outline_rounded, color: WithdrawView._darkGoldColor, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Withdrawals are created in realtime and wait for admin/manual JazzCash or EasyPaisa processing. Paid/rejected status updates appear here automatically.',
              style: TextStyle(
                color: Color(0xFF303030),
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w500,
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
    final viewModel = context.watch<WithdrawViewModel>();
    final canRequest = viewModel.model.canRequest && !viewModel.busy;
    return SizedBox(
      height: 50,
      child: ShimmerBox(
        enabled: viewModel.busy,
        baseColor: WithdrawView._goldColor,
        child: FilledButton(
          onPressed: !canRequest
              ? null
              : () async {
                  final ok = await context.read<WithdrawViewModel>().requestWithdrawal();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Withdrawal request sent. Admin approval is pending.'
                            : context.read<WithdrawViewModel>().model.errorMessage ??
                                'Could not send withdrawal request.',
                      ),
                    ),
                  );
                },
          style: FilledButton.styleFrom(
            elevation: 5,
            shadowColor: Colors.black.withValues(alpha: 0.45),
            backgroundColor: WithdrawView._goldColor,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            foregroundColor: Colors.black,
            disabledForegroundColor: const Color(0xFF6B7280),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontSize: 14,
              height: 1,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Text(viewModel.busy ? 'REQUESTING...' : 'REQUEST WITHDRAWAL'),
        ),
      ),
    );
  }
}

class _WithdrawalHistory extends StatelessWidget {
  const _WithdrawalHistory({required this.history});

  final List<WithdrawalRequestModel> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal History',
          style: TextStyle(
            color: WithdrawView._inkColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WithdrawView._borderGoldColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: WithdrawView._mutedColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No withdrawal requests yet.',
                    style: TextStyle(
                      color: WithdrawView._mutedColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final request in history.take(8)) ...[
            _HistoryTile(request: request),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.request});

  final WithdrawalRequestModel request;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      PayoutStatus.paid => WithdrawView._successColor,
      PayoutStatus.approved => WithdrawView._darkGoldColor,
      PayoutStatus.rejected => WithdrawView._dangerColor,
      PayoutStatus.pending => const Color(0xFF2563EB),
      PayoutStatus.draft => WithdrawView._mutedColor,
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WithdrawView._borderGoldColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs. ${_formatNumber(request.finalAmount)} • ${request.method.shortLabel}',
                  style: const TextStyle(
                    color: WithdrawView._inkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_dateLabel(request.createdAt)} • ${_maskAccount(request.accountNumber)}',
                  style: const TextStyle(
                    color: WithdrawView._mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              request.status.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(num value) {
  final intValue = value.round();
  final text = intValue.toString();
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

String _dateLabel(DateTime? value) {
  if (value == null) return 'Realtime';
  final now = DateTime.now();
  final difference = now.difference(value);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} h ago';
  if (difference.inDays < 7) return '${difference.inDays} d ago';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _maskAccount(String value) {
  final cleaned = value.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.length <= 4) return cleaned;
  final last = cleaned.substring(cleaned.length - 4);
  return '•••• $last';
}
