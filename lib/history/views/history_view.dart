import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/ui_polish.dart';
import '../models/history_model.dart';
import '../view_models/history_view_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  static const _backgroundColor = Color(0xFFFAFAFF);
  static const _inkColor = Color(0xFF111827);
  static const _mutedColor = Color(0xFF5F5F63);
  static const _goldColor = Color(0xFFFFC914);
  static const _darkGoldColor = Color(0xFF6E5200);
  static const _borderGoldColor = Color(0xFFD3C7AC);
  static const _dangerColor = Color(0xFFE11D48);
  static const _successColor = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel(),
      child: Consumer<HistoryViewModel>(
        builder: (context, viewModel, _) {
          final model = viewModel.model;
          return Scaffold(
            backgroundColor: _backgroundColor,
            appBar: AppBar(
              backgroundColor: _backgroundColor,
              elevation: 0,
              centerTitle: true,
              foregroundColor: _inkColor,
              title: const Text(
                'Trip History',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: viewModel.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    FadeSlideIn(child: _SummaryCard(model: model)),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _FilterRow(
                        selected: model.filter,
                        onChanged: viewModel.setFilter,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (viewModel.busy && model.trips.isEmpty)
                      const _HistoryLoadingList()
                    else if (model.error != null)
                      _ErrorState(
                        message: model.error!,
                        onRetry: viewModel.refresh,
                      )
                    else if (model.visibleTrips.isEmpty)
                      const _EmptyState()
                    else
                      for (final trip in model.visibleTrips) ...[
                        FadeSlideIn(child: _TripCard(trip: trip)),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.model});

  final RiderHistoryModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HistoryView._goldColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: HistoryView._goldColor.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: HistoryView._darkGoldColor),
              SizedBox(width: 8),
              Text(
                'Realtime delivery history',
                style: TextStyle(
                  color: HistoryView._darkGoldColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            model.totalEarningsLabel,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Total earned from completed deliveries',
            style: TextStyle(
              color: HistoryView._darkGoldColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: 'Trips',
                  value: model.totalTrips.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  title: 'Balance',
                  value: model.availableBalanceLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  title: 'Online',
                  value: '${model.hoursOnline.toStringAsFixed(1)}h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: HistoryView._darkGoldColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});

  final RiderHistoryFilter selected;
  final ValueChanged<RiderHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'All',
          selected: selected == RiderHistoryFilter.all,
          onTap: () => onChanged(RiderHistoryFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Completed',
          selected: selected == RiderHistoryFilter.completed,
          onTap: () => onChanged(RiderHistoryFilter.completed),
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Cancelled',
          selected: selected == RiderHistoryFilter.cancelled,
          onTap: () => onChanged(RiderHistoryFilter.cancelled),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? HistoryView._inkColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HistoryView._inkColor : HistoryView._borderGoldColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : HistoryView._inkColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final RiderHistoryTrip trip;

  @override
  Widget build(BuildContext context) {
    final completed = trip.status == RiderHistoryStatus.completed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HistoryView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? HistoryView._successColor.withValues(alpha: 0.12)
                      : HistoryView._dangerColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: completed
                      ? HistoryView._successColor
                      : HistoryView._dangerColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HistoryView._inkColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.dateLabel,
                      style: const TextStyle(
                        color: HistoryView._mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    completed ? trip.earningLabel : 'Rs. 0',
                    style: TextStyle(
                      color: completed
                          ? HistoryView._successColor
                          : HistoryView._mutedColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: completed
                          ? HistoryView._successColor.withValues(alpha: 0.10)
                          : HistoryView._dangerColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      trip.statusLabel,
                      style: TextStyle(
                        color: completed
                            ? HistoryView._successColor
                            : HistoryView._dangerColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressLine(
            icon: Icons.storefront_rounded,
            title: 'Pickup',
            value: trip.pickupAddress,
          ),
          const SizedBox(height: 8),
          _AddressLine(
            icon: Icons.location_on_rounded,
            title: 'Drop-off',
            value: trip.dropOffAddress,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(icon: Icons.receipt_long_rounded, label: trip.id),
              _InfoPill(icon: Icons.shopping_bag_rounded, label: trip.itemSummary),
              _InfoPill(icon: Icons.payments_rounded, label: trip.paymentMethod),
              if (trip.distanceKm != null)
                _InfoPill(
                  icon: Icons.route_rounded,
                  label: '${trip.distanceKm!.toStringAsFixed(1)} km',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HistoryView._darkGoldColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: HistoryView._inkColor,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6EF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEAE1C9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HistoryView._mutedColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: HistoryView._mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingList extends StatelessWidget {
  const _HistoryLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(
            child: Container(
              height: 146,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HistoryView._borderGoldColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 44, color: HistoryView._mutedColor),
          SizedBox(height: 12),
          Text(
            'No delivery history yet',
            style: TextStyle(
              color: HistoryView._inkColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completed deliveries will appear here in realtime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HistoryView._mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HistoryView._dangerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 38, color: HistoryView._dangerColor),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HistoryView._inkColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
