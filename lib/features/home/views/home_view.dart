import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/maps/rider_map_models.dart';
import '../../../core/maps/rider_navigation_map.dart';
import '../../../shared/widgets/ui_polish.dart';
import '../models/home_model.dart';
import '../view_models/home_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _backgroundColor = Color(0xFFFAFAFF);
  static const _inkColor = Color(0xFF111827);
  static const _mutedColor = Color(0xFF5F5F63);
  static const _goldColor = Color(0xFFFFC914);
  static const _darkGoldColor = Color(0xFF6E5200);
  static const _borderGoldColor = Color(0xFFD3C7AC);
  static const _fieldBorderColor = Color(0xFF8E816A);
  static const _softBlueColor = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _DashboardHeader(viewModel: viewModel),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final horizontalPadding =
                                constraints.maxWidth >= 600 ? 32.0 : 16.0;

                            return SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                14,
                                horizontalPadding,
                                18,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 430,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.02, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey(
                                        viewModel.model.selectedTabIndex,
                                      ),
                                      child: switch (viewModel
                                          .model
                                          .selectedTabIndex) {
                                        1 => _EarningsContent(
                                          model: viewModel.model,
                                        ),
                                        2 => _HistoryContent(
                                          model: viewModel.model,
                                        ),
                                        3 => _ProfileContent(
                                          viewModel: viewModel,
                                        ),
                                        _ => _OrdersContent(
                                          viewModel: viewModel,
                                        ),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _DashboardBottomNav(
                        selectedIndex: viewModel.model.selectedTabIndex,
                        onTap: viewModel.selectTab,
                      ),
                    ],
                  ),
                  if (viewModel.activePopupNotification != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 12,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _NotificationPopup(
                            notification: viewModel.activePopupNotification!,
                            onDismiss: viewModel.dismissNotificationPopup,
                          ),
                        ),
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

class _OrdersContent extends StatelessWidget {
  const _OrdersContent({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final model = viewModel.model;
    final availableOrders = viewModel.availableOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(child: _DailySummary(model: model)),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: _FindingOrdersMap(orderCount: availableOrders.length),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: _OrdersHeader(count: availableOrders.length),
        ),
        const SizedBox(height: 12),
        for (final order in availableOrders) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _OrderCard(
              order: order,
              onAccept: () {
                viewModel.acceptOrder(order.id);
                Navigator.of(context).pushNamed(AppRoutes.pickupNavigation);
              },
              onDecline: () => viewModel.declineOrder(order.id),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (availableOrders.isEmpty) const _EmptyOrdersState(),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HomeView._borderGoldColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: HomeView._darkGoldColor, width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFE7CE),
                  Color(0xFFFFC914),
                  Color(0xFF2B3742),
                ],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Vyraal',
              style: TextStyle(
                color: HomeView._inkColor,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _NotificationBell(
            count: viewModel.unreadNotificationsCount,
            onTap: () => _showNotificationsSheet(context, viewModel),
          ),
          const SizedBox(width: 8),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeView._goldColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: Color(0xFF151515),
                fontSize: 13,
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            fixedSize: const Size(36, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: const BorderSide(color: HomeView._borderGoldColor),
            ),
          ),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: HomeView._darkGoldColor,
            size: 20,
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFD00000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationPopup extends StatefulWidget {
  const _NotificationPopup({
    required this.notification,
    required this.onDismiss,
  });

  final RiderNotificationModel notification;
  final VoidCallback onDismiss;

  @override
  State<_NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<_NotificationPopup> {
  String? _playedForId;

  @override
  void initState() {
    super.initState();
    _playFeedbackIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _NotificationPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playFeedbackIfNeeded();
  }

  void _playFeedbackIfNeeded() {
    if (_playedForId == widget.notification.id) return;

    _playedForId = widget.notification.id;
    if (widget.notification.isUrgent) {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isUrgent
                ? HomeView._goldColor
                : HomeView._borderGoldColor,
            width: notification.isUrgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _NotificationIcon(type: notification.type, isLarge: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeView._inkColor,
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeView._mutedColor,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onDismiss,
              tooltip: 'Dismiss notification',
              icon: const Icon(Icons.close_rounded, size: 20),
              color: HomeView._mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

void _showNotificationsSheet(BuildContext context, HomeViewModel viewModel) {
  viewModel.markNotificationsRead();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: HomeView._inkColor,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Realtime rider alerts, payout updates, and admin messages',
                style: TextStyle(
                  color: HomeView._mutedColor,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: viewModel.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _NotificationListTile(
                      notification: viewModel.notifications[index],
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

class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({required this.notification});

  final RiderNotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      decoration: BoxDecoration(
        color: notification.isUnread
            ? const Color(0xFFFFFCF0)
            : HomeView._softBlueColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: notification.isUrgent
              ? HomeView._goldColor
              : HomeView._borderGoldColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(type: notification.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeView._inkColor,
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      notification.timeLabel,
                      style: const TextStyle(
                        color: HomeView._mutedColor,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: HomeView._mutedColor,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type, this.isLarge = false});

  final RiderNotificationType type;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (type) {
      RiderNotificationType.orderRequest => (
        Icons.local_shipping_outlined,
        const Color(0xFF10B981),
        const Color(0xFFE6FFF5),
      ),
      RiderNotificationType.orderAccepted => (
        Icons.check_circle_outline_rounded,
        HomeView._darkGoldColor,
        const Color(0xFFFFF4C2),
      ),
      RiderNotificationType.payoutApproved => (
        Icons.payments_outlined,
        const Color(0xFF00A86B),
        const Color(0xFFE5F8F0),
      ),
      RiderNotificationType.adminMessage => (
        Icons.admin_panel_settings_outlined,
        const Color(0xFF475467),
        const Color(0xFFE9EFFB),
      ),
      RiderNotificationType.announcement => (
        Icons.campaign_outlined,
        HomeView._darkGoldColor,
        const Color(0xFFFFF1C7),
      ),
    };

    final size = isLarge ? 44.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: isLarge ? 24 : 21),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAILY SUMMARY',
                  style: TextStyle(
                    color: HomeView._mutedColor,
                    fontSize: 12,
                    height: 1,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE38C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: HomeView._darkGoldColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: "Today's Trips",
                  value: model.todayTrips.toString(),
                ),
              ),
              Container(width: 1, height: 42, color: HomeView._borderGoldColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _SummaryMetric(
                    label: "Today's Earnings",
                    value: model.todayEarnings,
                    valueColor: HomeView._darkGoldColor,
                    alignRight: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor = HomeView._inkColor,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: HomeView._mutedColor,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 25,
              height: 0.95,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FindingOrdersMap extends StatelessWidget {
  const _FindingOrdersMap({required this.orderCount});

  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2933),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: RiderNavigationMap(
              snapshot: DemoMapPoints.snapshot,
              stage: RiderRouteStage.pickup,
              compact: true,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _MapStatusBadge(orderCount: orderCount),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HomeView._borderGoldColor),
              ),
              child: const Icon(
                Icons.near_me_rounded,
                color: HomeView._darkGoldColor,
                size: 20,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ShimmerBox(
                    baseColor: const Color(0xFFE6FFF5),
                    highlightColor: const Color(0xFFFFFFFF),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6FFF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Finding orders nearby...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeView._inkColor,
                            fontSize: 14,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Live seller requests in your 3 km radius',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: HomeView._mutedColor,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: HomeView._goldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$orderCount',
                      style: const TextStyle(
                        color: HomeView._darkGoldColor,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatusBadge extends StatelessWidget {
  const _MapStatusBadge({required this.orderCount});

  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            orderCount == 1 ? '1 live request' : '$orderCount live requests',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Available Orders',
                style: TextStyle(
                  color: HomeView._inkColor,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeView._goldColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$count NEW',
                style: const TextStyle(
                  color: HomeView._darkGoldColor,
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          'Pickup requests within 3 km of your current location',
          style: TextStyle(
            color: HomeView._mutedColor,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  final RiderOrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.isHighlighted
              ? HomeView._darkGoldColor
              : HomeView._borderGoldColor,
          width: order.isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: order.isHighlighted
                                    ? HomeView._darkGoldColor
                                    : HomeView._borderGoldColor,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              order.shopImageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const ColoredBox(
                                  color: HomeView._softBlueColor,
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: HomeView._darkGoldColor,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              order.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeView._inkColor,
                                fontSize: 17,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pickup distance',
                        style: TextStyle(
                          color: HomeView._mutedColor,
                          fontSize: 10,
                          height: 1,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.distanceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeView._inkColor,
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _OrderTimerPill(seconds: order.remainingSeconds),
                    const SizedBox(height: 10),
                    Text(
                      order.estimatedEarning,
                      style: const TextStyle(
                        color: HomeView._darkGoldColor,
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Est. Earning',
                      style: TextStyle(
                        color: HomeView._mutedColor,
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HomeView._borderGoldColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: HomeView._darkGoldColor,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivering to ${order.customerArea}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeView._inkColor,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OrderInfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${order.itemCount} items',
                ),
                _OrderInfoChip(icon: Icons.map_outlined, label: '3 km radius'),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: order.remainingSeconds / 60,
                minHeight: 5,
                backgroundColor: HomeView._softBlueColor,
                color: order.remainingSeconds <= 10
                    ? const Color(0xFFD00000)
                    : HomeView._goldColor,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              constraints: const BoxConstraints(minHeight: 38),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: HomeView._softBlueColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: HomeView._darkGoldColor,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.items,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3A321F),
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OrderActionButton(
                    label: 'Decline',
                    isPrimary: false,
                    emphasized: order.isHighlighted,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _OrderActionButton(
                    label: 'Accept',
                    isPrimary: true,
                    onPressed: order.isLocked ? null : onAccept,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoChip extends StatelessWidget {
  const _OrderInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: HomeView._softBlueColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HomeView._darkGoldColor, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: HomeView._inkColor,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimerPill extends StatelessWidget {
  const _OrderTimerPill({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFE8E8) : const Color(0xFFFFF4C2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent ? const Color(0xFFD00000) : HomeView._borderGoldColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: isUrgent ? const Color(0xFFD00000) : HomeView._darkGoldColor,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            '${seconds}s',
            style: TextStyle(
              color: isUrgent
                  ? const Color(0xFFD00000)
                  : HomeView._darkGoldColor,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeView._softBlueColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: const Text(
        'No nearby orders right now. Stay online and new requests will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: HomeView._mutedColor,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.label,
    required this.isPrimary,
    this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary ? HomeView._goldColor : Colors.white,
          foregroundColor: isPrimary ? HomeView._darkGoldColor : Colors.black,
          side: BorderSide(
            color: isPrimary
                ? HomeView._goldColor
                : emphasized
                ? Colors.black
                : HomeView._fieldBorderColor,
            width: emphasized && !isPrimary ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _EarningsContent extends StatelessWidget {
  const _EarningsContent({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeeklyTotal(model: model),
        const SizedBox(height: 14),
        _PayoutStatusTracker(status: model.payoutStatus),
        const SizedBox(height: 18),
        _WeeklyChart(model: model),
        const SizedBox(height: 16),
        const _TripHistoryHeader(),
        const SizedBox(height: 14),
        for (final trip in model.tripHistory) ...[
          _TripHistoryCard(trip: trip),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        const _WithdrawButton(),
      ],
    );
  }
}

class _WeeklyTotal extends StatelessWidget {
  const _WeeklyTotal({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WEEKLY TOTAL',
                style: TextStyle(
                  color: HomeView._mutedColor,
                  fontSize: 18,
                  height: 1,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  model.weeklyTotal,
                  style: const TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                model.weeklyGrowth,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Last 7 Days',
                    maxLines: 1,
                    style: TextStyle(
                      color: HomeView._inkColor,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    model.weekRange,
                    maxLines: 1,
                    style: const TextStyle(
                      color: HomeView._mutedColor,
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in model.weeklyEarnings)
                  Expanded(
                    child: _EarningBar(
                      item: item,
                      maxAmount: model.weeklyEarnings
                          .map((earning) => earning.amount)
                          .reduce((a, b) => a > b ? a : b),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningBar extends StatelessWidget {
  const _EarningBar({required this.item, required this.maxAmount});

  final WeeklyEarningModel item;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final heightFactor = item.amount / maxAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${(item.amount / 1000).toStringAsFixed(1)}k',
            style: TextStyle(
              color: item.isToday
                  ? HomeView._darkGoldColor
                  : HomeView._mutedColor,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor.clamp(0.18, 1),
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: item.isToday
                        ? HomeView._goldColor
                        : const Color(0xFFE9EFFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isToday
                          ? HomeView._darkGoldColor
                          : HomeView._borderGoldColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            item.day,
            style: TextStyle(
              color: item.isToday
                  ? HomeView._darkGoldColor
                  : HomeView._inkColor,
              fontSize: 11,
              height: 1,
              fontWeight: item.isToday ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutStatusTracker extends StatelessWidget {
  const _PayoutStatusTracker({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    const steps = PayoutStatus.values;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _PayoutStep(
                label: switch (steps[index]) {
                  PayoutStatus.pending => 'Pending',
                  PayoutStatus.approved => 'Approved',
                  PayoutStatus.paid => 'Paid',
                },
                isActive: steps[index].index <= status.index,
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 24,
                height: 2,
                color: steps[index].index < status.index
                    ? HomeView._goldColor
                    : HomeView._borderGoldColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _PayoutStep extends StatelessWidget {
  const _PayoutStep({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? HomeView._goldColor : HomeView._softBlueColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? HomeView._darkGoldColor
                  : HomeView._borderGoldColor,
            ),
          ),
          child: Icon(
            isActive ? Icons.check_rounded : Icons.hourglass_empty_rounded,
            size: 16,
            color: HomeView._darkGoldColor,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? HomeView._inkColor : HomeView._mutedColor,
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

class _TripHistoryHeader extends StatelessWidget {
  const _TripHistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Trip History',
            style: TextStyle(
              color: HomeView._inkColor,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(
            foregroundColor: HomeView._darkGoldColor,
            padding: EdgeInsets.zero,
            minimumSize: const Size(70, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.filter_list_rounded, size: 21),
          label: const Text('Filter'),
        ),
      ],
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip});

  final TripHistoryModel trip;

  @override
  Widget build(BuildContext context) {
    final isCash = trip.paymentType == PaymentType.cash;

    return Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: HomeView._darkGoldColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: HomeView._mutedColor,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${trip.customerName} • ${trip.location}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeView._mutedColor,
                          fontSize: 12,
                          height: 1.28,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  trip.dateTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeView._mutedColor,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trip.amount,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCash
                        ? const Color(0xFFE9EFFB)
                        : const Color(0xFFFFF1C7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isCash ? 'CASH' : 'ONLINE',
                    style: TextStyle(
                      color: isCash
                          ? HomeView._mutedColor
                          : HomeView._darkGoldColor,
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.withdraw),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: HomeView._goldColor,
          foregroundColor: HomeView._darkGoldColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
        label: const Text('Withdraw Earnings'),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Trip History',
          style: TextStyle(
            color: HomeView._inkColor,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        const _HistoryFilters(),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _HistoryStatCard(
                title: 'TOTAL TRIPS',
                value: model.totalTrips.toString(),
                suffix: 'trips',
                isDark: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HistoryStatCard(
                title: 'HOURS ONLINE',
                value: model.hoursOnline.toStringAsFixed(1),
                suffix: 'hrs',
                isDark: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final trip in model.detailedTrips) ...[
          _DetailedTripCard(trip: trip),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: HomeView._fieldBorderColor),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: HomeView._inkColor,
                      fontSize: 14,
                      height: 1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: HomeView._fieldBorderColor),
          ),
          child: const Icon(Icons.filter_list_rounded, size: 22),
        ),
      ],
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.isDark,
  });

  final String title;
  final String value;
  final String suffix;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF29313D) : HomeView._goldColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.black : HomeView._goldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : HomeView._darkGoldColor,
              fontSize: 11,
              height: 1,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white : HomeView._darkGoldColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedTripCard extends StatelessWidget {
  const _DetailedTripCard({required this.trip});

  final DetailedTripModel trip;

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == TripStatus.completed;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.dateTime,
                  style: const TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              _TripStatusBadge(isCompleted: isCompleted),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'ID: ${trip.id}',
            style: const TextStyle(
              color: HomeView._mutedColor,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          _TripStop(label: 'Pickup', value: trip.pickup, isFirst: true),
          const SizedBox(height: 10),
          _TripStop(label: 'Drop-off', value: trip.dropOff, isFirst: false),
          const SizedBox(height: 18),
          const Divider(color: HomeView._borderGoldColor, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _PaymentBadge(type: trip.paymentType),
              const Spacer(),
              Text(
                trip.amount,
                style: const TextStyle(
                  color: HomeView._inkColor,
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripStop extends StatelessWidget {
  const _TripStop({
    required this.label,
    required this.value,
    required this.isFirst,
  });

  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: HomeView._darkGoldColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (isFirst)
                Container(
                  width: 1,
                  height: 45,
                  color: HomeView._borderGoldColor,
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: HomeView._mutedColor,
                  fontSize: 13,
                  height: 1,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeView._inkColor,
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripStatusBadge extends StatelessWidget {
  const _TripStatusBadge({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE5F8F0) : const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Canceled',
        style: TextStyle(
          color: isCompleted
              ? const Color(0xFF00A86B)
              : const Color(0xFFE11D48),
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.type});

  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final isCash = type == PaymentType.cash;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isCash ? const Color(0xFFE7E7E7) : const Color(0xFFFFF1C7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isCash ? 'CASH' : 'ONLINE',
        style: TextStyle(
          color: isCash ? HomeView._mutedColor : HomeView._darkGoldColor,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.model.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHero(
          profile: profile,
          onUploadPhoto: viewModel.uploadProfilePhoto,
        ),
        const SizedBox(height: 24),
        _WorkStatusCard(
          isOnline: profile.isOnline,
          onChanged: viewModel.toggleOnlineStatus,
        ),
        const SizedBox(height: 14),
        _ProfileSetupCard(profile: profile, viewModel: viewModel),
        const SizedBox(height: 14),
        _DocumentsStatusCard(
          profile: profile,
          onUploadCnic: viewModel.uploadCnicDocument,
          onUploadBikeDocs: viewModel.uploadBikeDocument,
        ),
        const SizedBox(height: 20),
        _ProfileSettingsCard(
          profile: profile,
          onLanguageChanged: viewModel.changeLanguage,
          onAlertsChanged: viewModel.toggleAlerts,
          onHelpCenter: viewModel.openHelpCenter,
          onContactSupport: viewModel.contactSupport,
        ),
        const SizedBox(height: 24),
        _LogoutButton(
          onPressed: () {
            viewModel.logout();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          },
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onUploadPhoto});

  final RiderProfileModel profile;
  final VoidCallback onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeView._goldColor, width: 4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: profile.hasProfilePhoto
                        ? const [Color(0xFFF6E3C0), Color(0xFF0F766E)]
                        : const [Color(0xFFEAF0FF), Color(0xFFD3C7AC)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 56),
              ),
              Positioned(
                right: -2,
                bottom: 7,
                child: InkWell(
                  onTap: onUploadPhoto,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: profile.isOnline
                          ? const Color(0xFF10B981)
                          : HomeView._mutedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HomeView._inkColor,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Member since ${profile.memberSince}',
            style: const TextStyle(
              color: HomeView._mutedColor,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniProfileBadge(
                icon: Icons.verified_user_outlined,
                label: profile.isApproved ? 'Verified Rider' : 'Review Pending',
                color: profile.isApproved
                    ? const Color(0xFF10B981)
                    : HomeView._darkGoldColor,
              ),
              _MiniProfileBadge(
                icon: Icons.two_wheeler_rounded,
                label: profile.bikeRegistrationNumber,
                color: HomeView._darkGoldColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkStatusCard extends StatelessWidget {
  const _WorkStatusCard({required this.isOnline, required this.onChanged});

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFFFFAE5) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Status',
                  style: const TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isOnline
                      ? 'Online riders receive nearby order requests'
                      : 'Offline riders will not receive new requests',
                  style: const TextStyle(
                    color: HomeView._mutedColor,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: HomeView._goldColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupCard extends StatelessWidget {
  const _ProfileSetupCard({required this.profile, required this.viewModel});

  final RiderProfileModel profile;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      header: const _ProfileCardHeader(
        icon: Icons.manage_accounts_outlined,
        title: 'Profile Setup',
      ),
      child: Column(
        children: [
          _ProfileTextField(
            label: 'Full name',
            initialValue: profile.fullName,
            icon: Icons.person_outline_rounded,
            onChanged: (value) => viewModel.updateProfile(fullName: value),
          ),
          const SizedBox(height: 12),
          _LockedProfileField(
            label: 'Phone number',
            value: profile.phoneNumber,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 12),
          _ProfileTextField(
            label: 'CNIC number',
            initialValue: profile.cnic,
            icon: Icons.badge_outlined,
            onChanged: (value) => viewModel.updateProfile(cnic: value),
          ),
          const SizedBox(height: 12),
          _ProfileTextField(
            label: 'Bike registration',
            initialValue: profile.bikeRegistrationNumber,
            icon: Icons.confirmation_number_outlined,
            onChanged: (value) =>
                viewModel.updateProfile(bikeRegistrationNumber: value),
          ),
          const SizedBox(height: 12),
          _ProfileTextField(
            label: 'Vehicle',
            initialValue: profile.vehicleName,
            icon: Icons.two_wheeler_rounded,
            onChanged: (value) => viewModel.updateProfile(vehicleName: value),
          ),
        ],
      ),
    );
  }
}

class _DocumentsStatusCard extends StatelessWidget {
  const _DocumentsStatusCard({
    required this.profile,
    required this.onUploadCnic,
    required this.onUploadBikeDocs,
  });

  final RiderProfileModel profile;
  final VoidCallback onUploadCnic;
  final VoidCallback onUploadBikeDocs;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Document Verification',
                  style: TextStyle(
                    color: HomeView._inkColor,
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DocumentStatusPill(
                status: profile.isApproved
                    ? DocumentReviewStatus.approved
                    : DocumentReviewStatus.pending,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocumentUploadRow(
            title: 'CNIC document',
            status: profile.cnicStatus,
            onUpload: onUploadCnic,
          ),
          const SizedBox(height: 10),
          _DocumentUploadRow(
            title: 'Bike documents',
            status: profile.bikeDocsStatus,
            onUpload: onUploadBikeDocs,
          ),
        ],
      ),
    );
  }
}

class _MiniProfileBadge extends StatelessWidget {
  const _MiniProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(
        color: HomeView._inkColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LockedProfileField extends StatelessWidget {
  const _LockedProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(
        color: HomeView._inkColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DocumentUploadRow extends StatelessWidget {
  const _DocumentUploadRow({
    required this.title,
    required this.status,
    required this.onUpload,
  });

  final String title;
  final DocumentReviewStatus status;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: HomeView._softBlueColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: HomeView._darkGoldColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: HomeView._inkColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _DocumentStatusPill(status: status),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onUpload,
            tooltip: 'Upload $title',
            icon: const Icon(Icons.cloud_upload_outlined),
            color: HomeView._darkGoldColor,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _DocumentStatusPill extends StatelessWidget {
  const _DocumentStatusPill({required this.status});

  final DocumentReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      DocumentReviewStatus.approved => (
        'APPROVED',
        const Color(0xFF00A86B),
        const Color(0xFFE5F8F0),
      ),
      DocumentReviewStatus.pending => (
        'PENDING',
        HomeView._darkGoldColor,
        const Color(0xFFFFF1C7),
      ),
      DocumentReviewStatus.missing => (
        'MISSING',
        const Color(0xFFD00000),
        const Color(0xFFFFE8E8),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          height: 1,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({
    required this.profile,
    required this.onLanguageChanged,
    required this.onAlertsChanged,
    required this.onHelpCenter,
    required this.onContactSupport,
  });

  final RiderProfileModel profile;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onAlertsChanged;
  final VoidCallback onHelpCenter;
  final VoidCallback onContactSupport;

  static const _languages = ['English', 'Urdu', 'Arabic'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: onLanguageChanged,
                  itemBuilder: (context) => _languages
                      .map(
                        (language) => PopupMenuItem<String>(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(),
                  child: _SettingTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: profile.language,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ),
              const SizedBox(
                height: 96,
                child: VerticalDivider(
                  color: HomeView._borderGoldColor,
                  width: 1,
                ),
              ),
              Expanded(
                child: _SettingTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Alerts',
                  subtitle: profile.alertsEnabled ? 'Enabled' : 'Muted',
                  onTap: () => onAlertsChanged(!profile.alertsEnabled),
                  trailingIcon: profile.alertsEnabled
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                ),
              ),
            ],
          ),
          const Divider(color: HomeView._borderGoldColor, height: 1),
          _SupportRow(
            icon: Icons.help_outline_rounded,
            label: 'Help Center',
            onTap: onHelpCenter,
          ),
          const Divider(color: HomeView._borderGoldColor, height: 1),
          _SupportRow(
            icon: Icons.support_agent_rounded,
            label: 'Contact Support',
            onTap: onContactSupport,
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child, this.header});

  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: HomeView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: const BoxDecoration(
                color: HomeView._softBlueColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                border: Border(
                  bottom: BorderSide(color: HomeView._borderGoldColor),
                ),
              ),
              child: header,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: child,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ProfileCardHeader extends StatelessWidget {
  const _ProfileCardHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HomeView._inkColor,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: HomeView._darkGoldColor, size: 23),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeView._mutedColor,
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(trailingIcon, color: HomeView._darkGoldColor, size: 18),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: HomeView._mutedColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: HomeView._mutedColor,
              size: 24,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD00000),
          side: const BorderSide(color: Color(0xFFD00000), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 13,
            height: 1,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('LOGOUT ACCOUNT'),
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItemData(icon: Icons.local_shipping_outlined, label: 'Orders'),
      _NavItemData(icon: Icons.payments_outlined, label: 'Earnings'),
      _NavItemData(icon: Icons.history_rounded, label: 'History'),
      _NavItemData(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: HomeView._backgroundColor,
        border: Border(top: BorderSide(color: HomeView._borderGoldColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _BottomNavItem(
                data: items[index],
                isSelected: selectedIndex == index,
                onTap: () => onTap(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? HomeView._darkGoldColor : HomeView._mutedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 40 : 34,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? HomeView._goldColor.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: color, size: 21),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
