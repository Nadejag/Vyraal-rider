import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/maps/rider_map_models.dart';
import '../../../core/maps/rider_navigation_map.dart';
import '../../../shared/widgets/ui_polish.dart';
import '../view_models/navigation_view_model.dart';

class PickupNavigationView extends StatelessWidget {
  const PickupNavigationView({super.key});

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
      create: (_) => PickupNavigationViewModel(),
      child: Consumer<PickupNavigationViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: _backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const _PickupHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RiderNavigationMap(
                            snapshot: viewModel.navigationSnapshot,
                            stage: RiderRouteStage.pickup,
                          ),
                        ),
                        DraggableScrollableSheet(
                          initialChildSize: 0.42,
                          minChildSize: 0.18,
                          maxChildSize: 0.68,
                          snap: true,
                          snapSizes: const [0.18, 0.42, 0.68],
                          builder: (context, scrollController) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: _PickupSheet(
                                viewModel: viewModel,
                                scrollController: scrollController,
                              ),
                            );
                          },
                        ),
                      ],
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

class _PickupHeader extends StatelessWidget {
  const _PickupHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: PickupNavigationView._borderGoldColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PickupNavigationView._borderGoldColor,
                width: 2,
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFFEFE7CE), Color(0xFF0F766E)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'HEADING TO SELLER',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PickupNavigationView._inkColor,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PickupNavigationView._goldColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupSheet extends StatelessWidget {
  const _PickupSheet({required this.viewModel, required this.scrollController});

  final PickupNavigationViewModel viewModel;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: PickupNavigationView._backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: PickupNavigationView._borderGoldColor),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 58,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3F2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      viewModel.model.sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PickupNavigationView._inkColor,
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ESTIMATED\nEARNING',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: PickupNavigationView._mutedColor,
                          fontSize: 10,
                          height: 1.45,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        viewModel.model.estimatedEarning,
                        style: const TextStyle(
                          color: PickupNavigationView._darkGoldColor,
                          fontSize: 23,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 70),
              child: Wrap(
                spacing: 19,
                runSpacing: 12,
                children: [
                  _InfoPill(
                    icon: Icons.inventory_2_outlined,
                    text: 'Items:\n${viewModel.model.itemsCount}',
                    color: PickupNavigationView._softBlueColor,
                    textColor: const Color(0xFF3A321F),
                  ),
                  _InfoPill(
                    icon: Icons.timer_outlined,
                    text: viewModel.model.timeAway,
                    color: const Color(0xFFDDF6EF),
                    textColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: PickupNavigationView._softBlueColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PickupNavigationView._borderGoldColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: PickupNavigationView._darkGoldColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        viewModel.model.address,
                        style: const TextStyle(
                          color: PickupNavigationView._mutedColor,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: 'Call Seller',
                    icon: Icons.phone_outlined,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 69,
                  child: _OutlineActionButton(
                    label: '',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  viewModel.markPickedUp();
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.deliveryNavigation);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: PickupNavigationView._goldColor,
                  foregroundColor: PickupNavigationView._darkGoldColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 21),
                label: const Text('Picked Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: PickupNavigationView._borderGoldColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: label.isEmpty
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: PickupNavigationView._inkColor,
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Icon(icon, size: 21),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: PickupNavigationView._inkColor,
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: Icon(icon, size: 20),
              label: Text(label),
            ),
    );
  }
}
