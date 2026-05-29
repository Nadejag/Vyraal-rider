import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/maps/rider_map_models.dart';
import '../../../core/maps/rider_navigation_map.dart';
import '../../../core/realtime/rider_order_chat_sheet.dart';
import '../../../shared/widgets/ui_polish.dart';
import '../view_models/navigation_view_model.dart';

class DeliveryNavigationView extends StatelessWidget {
  const DeliveryNavigationView({super.key});

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
      create: (_) => DeliveryNavigationViewModel(),
      child: Consumer<DeliveryNavigationViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: DeliveryNavigationView._backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const _DeliveryHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RiderNavigationMap(
                            snapshot: viewModel.navigationSnapshot,
                            stage: RiderRouteStage.delivery,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: FadeSlideIn(
                            child: _EtaCard(model: viewModel.model),
                          ),
                        ),
                        DraggableScrollableSheet(
                          initialChildSize: 0.48,
                          minChildSize: 0.20,
                          maxChildSize: 0.74,
                          snap: true,
                          snapSizes: const [0.20, 0.48, 0.74],
                          builder: (context, scrollController) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: _DeliverySheet(
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

Future<void> _callPhone(String phone) async {
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DeliveryNavigationView._borderGoldColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEFE7CE), Color(0xFFCDEB57)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Vyraal',
              style: TextStyle(
                color: DeliveryNavigationView._inkColor,
                fontSize: 24,
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
              color: DeliveryNavigationView._goldColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.model});

  final dynamic model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DeliveryNavigationView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: DeliveryNavigationView._goldColor,
            child: const Icon(
              Icons.navigation_outlined,
              color: DeliveryNavigationView._darkGoldColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Delivery in Progress',
                    maxLines: 1,
                    style: TextStyle(
                      color: DeliveryNavigationView._mutedColor,
                      fontSize: 13,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ETA: ${model.eta}',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                model.distance,
                maxLines: 1,
                style: const TextStyle(
                  color: DeliveryNavigationView._darkGoldColor,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySheet extends StatelessWidget {
  const _DeliverySheet({
    required this.viewModel,
    required this.scrollController,
  });

  final DeliveryNavigationViewModel viewModel;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  color: DeliveryNavigationView._borderGoldColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (viewModel.model.isDelivered) ...[
              _DeliveredNotice(
                notificationSent: viewModel.model.notificationSent,
              ),
              const SizedBox(height: 18),
            ],
            FadeSlideIn(
              delay: const Duration(milliseconds: 70),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.model.customerName,
                          style: const TextStyle(
                            color: DeliveryNavigationView._inkColor,
                            fontSize: 21,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: DeliveryNavigationView._mutedColor,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                viewModel.model.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DeliveryNavigationView._mutedColor,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: viewModel.callCustomer,
                    tooltip: 'Call customer',
                    style: IconButton.styleFrom(
                      backgroundColor: DeliveryNavigationView._softBlueColor,
                      fixedSize: const Size(52, 52),
                      shape: const CircleBorder(),
                      side: const BorderSide(
                        color: DeliveryNavigationView._borderGoldColor,
                      ),
                    ),
                    icon: const Icon(
                      Icons.phone_in_talk_outlined,
                      color: DeliveryNavigationView._darkGoldColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _AddressRouteCard(address: viewModel.model.address),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Row(
                children: [
                  Expanded(
                    child: _DeliveryInfoCard(
                      title: 'Payment',
                      value: viewModel.model.paymentAmount,
                      badge: 'COD',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeliveryInfoCard(
                      title: 'Items',
                      value: viewModel.model.items,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ProofPhotoCard(
              hasPhoto: viewModel.model.hasDeliveryPhoto,
              onUpload: viewModel.uploadDeliveryPhoto,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    viewModel.model.isDelivered ||
                        !viewModel.hasActiveOrder ||
                        viewModel.isBusy
                    ? null
                    : () => viewModel.markDelivered(),
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFE5F8F0),
                  disabledForegroundColor: const Color(0xFF00A86B),
                  backgroundColor: viewModel.model.hasDeliveryPhoto
                      ? DeliveryNavigationView._goldColor
                      : const Color(0xFFFFD84E),
                  foregroundColor: DeliveryNavigationView._darkGoldColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: viewModel.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 22),
                label: Text(
                  viewModel.model.isDelivered
                      ? 'DELIVERED'
                      : viewModel.hasActiveOrder
                      ? 'DELIVERED'
                      : 'NO ACTIVE DELIVERY',
                ),
              ),
            ),
            if (viewModel.model.isDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
                  style: FilledButton.styleFrom(
                    backgroundColor: DeliveryNavigationView._goldColor,
                    foregroundColor: DeliveryNavigationView._darkGoldColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('BACK TO HOME'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DeliveryOutlineButton(
                    icon: Icons.report_problem_outlined,
                    label: 'Call',
                    onPressed: () => _callPhone(viewModel.model.customerPhone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DeliveryOutlineButton(
                    icon: Icons.chat_outlined,
                    label: 'Chat',
                    onPressed: () => RiderOrderChatSheet.show(
                      context,
                      orderId: viewModel.model.orderId,
                      title: viewModel.model.customerName,
                    ),
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

class _DeliveredNotice extends StatelessWidget {
  const _DeliveredNotice({required this.notificationSent});

  final bool notificationSent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9BE7C6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF00A86B),
            size: 26,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              notificationSent
                  ? 'Delivered. Customer notified: "Your order has been delivered!"'
                  : 'Delivered successfully.',
              style: const TextStyle(
                color: DeliveryNavigationView._inkColor,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRouteCard extends StatelessWidget {
  const _AddressRouteCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DeliveryNavigationView._borderGoldColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: DeliveryNavigationView._goldColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_outlined,
              color: DeliveryNavigationView._darkGoldColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Customer home: $address',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DeliveryNavigationView._inkColor,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPhotoCard extends StatelessWidget {
  const _ProofPhotoCard({required this.hasPhoto, required this.onUpload});

  final bool hasPhoto;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: hasPhoto ? null : onUpload,
      style: OutlinedButton.styleFrom(
        disabledForegroundColor: const Color(0xFF00A86B),
        foregroundColor: DeliveryNavigationView._inkColor,
        backgroundColor: hasPhoto
            ? const Color(0xFFE5F8F0)
            : DeliveryNavigationView._softBlueColor,
        side: BorderSide(
          color: hasPhoto
              ? const Color(0xFF9BE7C6)
              : DeliveryNavigationView._borderGoldColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      ),
      child: Row(
        children: [
          Icon(
            hasPhoto
                ? Icons.photo_camera_back_rounded
                : Icons.add_a_photo_outlined,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPhoto
                      ? 'Delivery photo uploaded'
                      : 'Upload delivery photo',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPhoto
                      ? 'Proof of delivery is attached'
                      : 'Optional proof after handing items at the door',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            hasPhoto
                ? Icons.check_circle_outline_rounded
                : Icons.upload_rounded,
            color: hasPhoto
                ? const Color(0xFF00A86B)
                : DeliveryNavigationView._darkGoldColor,
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  const _DeliveryInfoCard({
    required this.title,
    required this.value,
    this.badge,
  });

  final String title;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: DeliveryNavigationView._softBlueColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DeliveryNavigationView._borderGoldColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DeliveryNavigationView._mutedColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (badge != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DeliveryNavigationView._goldColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryOutlineButton extends StatelessWidget {
  const _DeliveryOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: DeliveryNavigationView._inkColor,
          side: const BorderSide(color: Color(0xFF7A705E), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
