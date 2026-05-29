import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/widgets/rider_image.dart';
import '../models/home_model.dart';
import '../view_models/home_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..init(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  static const _bg = Color(0xFFFFFBF2);
  static const _gold = Color(0xFFFFC107);
  static const _dark = Color(0xFF211B10);
  static const _muted = Color(0xFF776F61);
  static const _card = Colors.white;
  static const _border = Color(0xFFFFE0A3);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final model = vm.model;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _gold,
          onRefresh: vm.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(profile: model.profile),
                      const SizedBox(height: 14),
                      if (vm.errorMessage != null)
                        _ErrorBanner(
                          message: vm.errorMessage!,
                          onClose: vm.clearError,
                        ),
                      if (model.ordersError != null)
                        _ErrorBanner(
                          message: model.ordersError!,
                          onClose: vm.clearError,
                        ),
                      _WorkStatusCard(
                        profile: model.profile,
                        isChanging: vm.isChangingStatus,
                        onToggle: (value) {
                          vm.toggleWorkStatus(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      if (vm.isLoading) ...[
                        const _DashboardSkeleton(),
                      ] else ...[
                        _AvailableOrdersSection(
                          orders: vm.availableOrders,
                          isBusy: vm.isBusy,
                          isOnline: vm.isOnline,
                          isAccepting: vm.isAcceptingOrder,
                          onAccept: (order) async {
                            final accepted = await vm.acceptOrder(order);
                            if (!context.mounted || !accepted) return;
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.pickupNavigation);
                          },
                          onDecline: vm.declineOrder,
                        ),
                        const SizedBox(height: 16),
                        _StatsGrid(model: model),
                        const SizedBox(height: 16),
                        _WeeklyEarningsCard(model: model),
                        const SizedBox(height: 16),
                        _HistoryPreview(model: model),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final RiderProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.trim().isEmpty ? 'Rider' : profile.fullName;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.profile);
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _HomeBody._gold,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22FFC107),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: RiderImage(
                url: profile.profilePhotoUrl,
                base64: profile.profilePhotoUrl,
                fallback: const Icon(
                  Icons.delivery_dining_rounded,
                  color: _HomeBody._dark,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalam-o-Alaikum',
                  style: TextStyle(
                    color: _HomeBody._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeBody._dark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            final vm = context.read<HomeViewModel>();
            _showSettingsModal(context, vm);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HomeBody._border),
            ),
            child: const Icon(
              Icons.settings_suggest_rounded,
              color: _HomeBody._dark,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsModal(BuildContext context, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _SettingsModal(vm: vm);
      },
    );
  }
}

class _SettingsModal extends StatefulWidget {
  const _SettingsModal({required this.vm});
  final HomeViewModel vm;

  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.vm.model.profile.email,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final prof = widget.vm.model.profile;
        // Sync if updated externally
        if (_emailController.text != prof.email) {
          _emailController.text = prof.email;
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Settings & Preferences',
                  style: TextStyle(
                    color: _HomeBody._dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your real-time notification settings',
                  style: TextStyle(
                    color: _HomeBody._muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildToggleRow(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Alerts for new nearby orders',
                  value: prof.alertsEnabled,
                  onChanged: widget.vm.toggleAlerts,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFF3F4F6)),
                ),
                _buildToggleRow(
                  icon: Icons.alternate_email_rounded,
                  title: 'Email Notifications',
                  subtitle: 'Real-time order & account updates',
                  value: prof.emailNotificationsEnabled,
                  onChanged: widget.vm.toggleEmailNotifications,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notification Email Address',
                  style: TextStyle(
                    color: _HomeBody._dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email for notifications',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _HomeBody._gold,
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: _HomeBody._dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final saved = await widget.vm.updateEmail(
                          _emailController.text,
                        );
                        if (!context.mounted || !saved) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notification email saved successfully!',
                            ),
                            backgroundColor: _HomeBody._green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _HomeBody._dark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _HomeBody._gold,
                    foregroundColor: _HomeBody._dark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _HomeBody._gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _HomeBody._dark, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _HomeBody._dark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _HomeBody._muted.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: _HomeBody._green,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _WorkStatusCard extends StatelessWidget {
  const _WorkStatusCard({
    required this.profile,
    required this.isChanging,
    required this.onToggle,
  });

  final RiderProfileModel profile;
  final bool isChanging;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final online = profile.isOnline;
    final busy = profile.isBusy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: online
              ? const [Color(0xFFFFD75A), Color(0xFFFFC107)]
              : const [Colors.white, Color(0xFFFFF7DE)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _HomeBody._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15F2B300),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              busy
                  ? Icons.local_shipping_rounded
                  : online
                  ? Icons.radar_rounded
                  : Icons.power_settings_new_rounded,
              color: busy
                  ? _HomeBody._blue
                  : online
                  ? _HomeBody._green
                  : _HomeBody._muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busy
                      ? 'Busy on delivery'
                      : online
                      ? 'You are online'
                      : 'You are offline',
                  style: const TextStyle(
                    color: _HomeBody._dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  busy
                      ? 'Complete current order to receive new requests.'
                      : online
                      ? 'Realtime seller requests can appear here.'
                      : 'Go online to receive available orders.',
                  style: TextStyle(
                    color: _HomeBody._dark.withValues(alpha: 0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isChanging)
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _HomeBody._dark,
              ),
            )
          else
            Switch.adaptive(
              value: online,
              activeThumbColor: _HomeBody._green,
              onChanged: busy ? null : onToggle,
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          title: "Today's Trips",
          value: model.todayTrips.toString(),
          icon: Icons.route_rounded,
          color: _HomeBody._blue,
        ),
        _StatCard(
          title: "Today's Earnings",
          value: model.todayEarnings,
          icon: Icons.payments_rounded,
          color: _HomeBody._green,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.withdraw),
        ),
        _StatCard(
          title: 'Total Trips',
          value: model.totalTrips.toString(),
          icon: Icons.check_circle_rounded,
          color: _HomeBody._gold,
        ),
        _StatCard(
          title: 'Hours Online',
          value: model.hoursOnline.toStringAsFixed(1),
          icon: Icons.timer_rounded,
          color: _HomeBody._red,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _HomeBody._card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _HomeBody._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomeBody._dark,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomeBody._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

class _WeeklyEarningsCard extends StatelessWidget {
  const _WeeklyEarningsCard({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    final max = model.weeklyEarnings.fold<int>(
      1,
      (previous, item) => item.amount > previous ? item.amount : previous,
    );

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.withdraw),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _HomeBody._card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _HomeBody._border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Weekly Earnings',
                    style: TextStyle(
                      color: _HomeBody._dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  model.weeklyGrowth,
                  style: TextStyle(
                    color: model.weeklyGrowth.startsWith('-')
                        ? _HomeBody._red
                        : _HomeBody._green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${model.weekRange} • ${model.weeklyTotal}',
              style: const TextStyle(
                color: _HomeBody._muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 92,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: model.weeklyEarnings.map((item) {
                  final height = 18 + ((item.amount / max) * 62);
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          height: height,
                          width: 18,
                          decoration: BoxDecoration(
                            color: item.isToday
                                ? _HomeBody._gold
                                : const Color(0xFFFFE8A3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.day,
                          style: TextStyle(
                            color: item.isToday
                                ? _HomeBody._dark
                                : _HomeBody._muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableOrdersSection extends StatelessWidget {
  const _AvailableOrdersSection({
    required this.orders,
    required this.isOnline,
    required this.isBusy,
    required this.isAccepting,
    required this.onAccept,
    required this.onDecline,
  });

  final List<RiderOrderModel> orders;
  final bool isOnline;
  final bool isBusy;
  final bool isAccepting;
  final Future<void> Function(RiderOrderModel order) onAccept;
  final Future<void> Function(RiderOrderModel order) onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Available Orders',
                style: TextStyle(
                  color: _HomeBody._dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _HomeBody._gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${orders.length} live',
                style: const TextStyle(
                  color: _HomeBody._dark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!isOnline)
          const _EmptyState(
            icon: Icons.power_settings_new_rounded,
            title: 'You are offline',
            message: 'Turn on your work status to receive seller requests.',
          )
        else if (isBusy)
          const _EmptyState(
            icon: Icons.delivery_dining_rounded,
            title: 'Current delivery active',
            message:
                'New requests will appear after this delivery is completed.',
          )
        else if (orders.isEmpty)
          const _EmptyState(
            icon: Icons.radar_rounded,
            title: 'Waiting for orders',
            message:
                'When a seller accepts a customer order, it appears here in realtime.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(
                order: order,
                isAccepting: isAccepting,
                onAccept: () => onAccept(order),
                onDecline: () => onDecline(order),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isAccepting,
    required this.onAccept,
    required this.onDecline,
  });

  final RiderOrderModel order;
  final bool isAccepting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _HomeBody._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: order.isHighlighted ? _HomeBody._gold : _HomeBody._border,
          width: order.isHighlighted ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShopAvatar(order: order),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeBody._dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items} • ${order.customerArea}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeBody._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.estimatedEarning,
                style: const TextStyle(
                  color: _HomeBody._green,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (order.remainingSeconds.clamp(0, 60)) / 60.0,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(
                order.remainingSeconds > 15 ? _HomeBody._gold : _HomeBody._red,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acceptance Window',
                style: TextStyle(
                  color: _HomeBody._muted.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${order.remainingSeconds}s remaining',
                style: TextStyle(
                  color: order.remainingSeconds > 15
                      ? _HomeBody._dark
                      : _HomeBody._red,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _HomeBody._border),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.storefront_rounded,
                  text: order.sellerAddress ?? 'Seller pickup location',
                ),
                const SizedBox(height: 7),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: order.deliveryAddress ?? 'Customer delivery location',
                ),
                const SizedBox(height: 7),
                _InfoRow(
                  icon: Icons.payments_rounded,
                  text: 'Bill ${order.paymentAmount ?? 'Rs. 0'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isAccepting ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _HomeBody._red,
                    side: BorderSide(
                      color: _HomeBody._red.withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isAccepting ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: _HomeBody._gold,
                    foregroundColor: _HomeBody._dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: isAccepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _HomeBody._dark,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Accept Order',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.order});

  final RiderOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _HomeBody._gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: RiderImage(
          url: order.shopImageUrl,
          base64: order.shopImageBase64 ?? order.shopImageUrl,
          fallback: const Icon(
            Icons.storefront_rounded,
            color: _HomeBody._dark,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _HomeBody._muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeBody._dark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.model});

  final HomeModel model;

  @override
  Widget build(BuildContext context) {
    final trips = model.tripHistory.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeBody._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _HomeBody._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Completed Trips',
            style: TextStyle(
              color: _HomeBody._dark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (trips.isEmpty)
            const Text(
              'No completed delivery yet. Your real completed trips will appear here.',
              style: TextStyle(
                color: _HomeBody._muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...trips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _HomeBody._green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: _HomeBody._green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip.sellerName} → ${trip.customerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _HomeBody._dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            trip.dateTime,
                            style: const TextStyle(
                              color: _HomeBody._muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      trip.amount,
                      style: const TextStyle(
                        color: _HomeBody._green,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _HomeBody._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _HomeBody._border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _HomeBody._gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _HomeBody._dark),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _HomeBody._dark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _HomeBody._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _HomeBody._red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HomeBody._red.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _HomeBody._red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _HomeBody._dark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: List.generate(4, (_) => const _SkeletonCard()),
        ),
        const SizedBox(height: 16),
        const _SkeletonCard(height: 164),
        const SizedBox(height: 16),
        const _SkeletonCard(height: 180),
      ],
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({this.height});

  final double? height;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _HomeBody._border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFFCFBF9),
                Color(0xFFF3F1ED),
                Color(0xFFFCFBF9),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: _buildDefaultSkeletonLayout(),
        );
      },
    );
  }

  Widget _buildDefaultSkeletonLayout() {
    final h = widget.height ?? 0;
    if (h == 164) {
      // Weekly earnings card skeleton
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE6DF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                Container(
                  width: 50,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE6DF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 160,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DED7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final barHeight = 20.0 + (idx * 8) % 45;
                return Container(
                  width: 16,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFECE6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    } else if (h == 180) {
      // Available orders/list card skeleton
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE6DF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3DED7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 140,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFECE6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFECE6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE6DF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3DED7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default Metric Card loader
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 65,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE6DF),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFECE6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 90,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE3DED7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 45,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEFECE6),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}
