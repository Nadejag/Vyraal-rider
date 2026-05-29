import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/ui_polish.dart';
import '../models/verification_model.dart';
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
  static const _successColor = Color(0xFF039855);
  static const _dangerColor = Color(0xFFB42318);

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
      VerificationModel.codeLength,
      (index) => TextEditingController(text: viewModel.digitAt(index)),
    );
    _focusNodes = List.generate(
      VerificationModel.codeLength,
      (_) => FocusNode(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && viewModel.isOtpStep) _focusNodes.first.requestFocus();
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

  void _syncOtpBoxes(VerificationViewModel viewModel) {
    for (var i = 0; i < _controllers.length; i++) {
      final digit = viewModel.digitAt(i);
      if (_controllers[i].text != digit) {
        _controllers[i].text = digit;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VerificationViewModel>(
      builder: (context, viewModel, _) {
        _syncOtpBoxes(viewModel);

        Future<void> verify() async {
          final route = await viewModel.verify();
          if (!context.mounted || route == null) return;
          Navigator.of(context).pushReplacementNamed(route);
        }

        Future<void> submitProfile() async {
          final route = await viewModel.submitProfileAndDocuments();
          if (!context.mounted || route == null) return;
          Navigator.of(context).pushReplacementNamed(route);
        }

        return Scaffold(
          backgroundColor: VerificationView._backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _VerificationHeader(model: viewModel.model),
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
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: viewModel.isOtpStep
                                  ? _OtpSection(
                                      key: const ValueKey('otp'),
                                      viewModel: viewModel,
                                      controllers: _controllers,
                                      focusNodes: _focusNodes,
                                      onVerify: verify,
                                    )
                                  : _ProfileSection(
                                      key: const ValueKey('profile'),
                                      viewModel: viewModel,
                                      onSubmit: submitProfile,
                                    ),
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
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({required this.model});

  final VerificationModel model;

  @override
  Widget build(BuildContext context) {
    final approved = model.verificationStatus == 'approved';
    final pending = model.verificationStatus == 'pending';
    final rejected = model.verificationStatus == 'rejected';
    final label = approved
        ? 'APPROVED'
        : pending
        ? 'PENDING'
        : rejected
        ? 'REJECTED'
        : 'OFFLINE';
    final color = approved
        ? VerificationView._successColor
        : rejected
        ? VerificationView._dangerColor
        : pending
        ? VerificationView._goldColor
        : VerificationView._offlineColor;

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
              'Vyraal Rider',
              style: TextStyle(
                color: VerificationView._inkColor,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontSize: 11,
                height: 1,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpSection extends StatelessWidget {
  const _OtpSection({
    super.key,
    required this.viewModel,
    required this.controllers,
    required this.focusNodes,
    required this.onVerify,
  });

  final VerificationViewModel viewModel;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(child: _VerificationIntro(phone: viewModel.phoneNumber)),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _CodeInputRow(
            controllers: controllers,
            focusNodes: focusNodes,
            onChanged: (index, value) {
              viewModel.updateDigit(index, value);
              if (viewModel.model.canVerify) onVerify();
            },
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 130),
          child: _ResendBlock(
            timerText: viewModel.timerText,
            canResend: viewModel.canResend,
            onResend: viewModel.resendCode,
          ),
        ),
        if (viewModel.hasError) ...[
          const SizedBox(height: 12),
          _ErrorText(message: viewModel.errorMessage!),
        ],
        const SizedBox(height: 42),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: _PrimaryButton(
            isBusy: viewModel.isBusy,
            label: 'VERIFY',
            icon: Icons.check_circle_outline_rounded,
            onPressed: onVerify,
          ),
        ),
        const SizedBox(height: 14),
        const FadeSlideIn(
          delay: Duration(milliseconds: 230),
          child: _SecurityNotice(),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    super.key,
    required this.viewModel,
    required this.onSubmit,
  });

  final VerificationViewModel viewModel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final model = viewModel.model;
    final readOnly = model.isApproved || model.isPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(child: _ProfileIntro(model: model)),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: _StatusCard(model: model),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: _FormCard(
            title: 'Profile setup',
            subtitle: 'This data is saved realtime to your rider profile.',
            children: [
              _AppTextField(
                label: 'Full name',
                initialValue: model.name,
                enabled: !readOnly,
                textCapitalization: TextCapitalization.words,
                onChanged: viewModel.updateName,
              ),
              _AppTextField(
                label: 'City',
                initialValue: model.city,
                enabled: !readOnly,
                textCapitalization: TextCapitalization.words,
                onChanged: viewModel.updateCity,
              ),
              _AppTextField(
                label: 'Address',
                initialValue: model.address,
                enabled: !readOnly,
                maxLines: 2,
                onChanged: viewModel.updateAddress,
              ),
              _AppTextField(
                label: 'CNIC number',
                initialValue: model.cnicNumber,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: viewModel.updateCnicNumber,
              ),
              _AppTextField(
                label: 'License number',
                initialValue: model.licenseNumber,
                enabled: !readOnly,
                onChanged: viewModel.updateLicenseNumber,
              ),
              _AppTextField(
                label: 'Vehicle type',
                initialValue: model.vehicleType,
                enabled: !readOnly,
                onChanged: viewModel.updateVehicleType,
              ),
              _AppTextField(
                label: 'Vehicle number',
                initialValue: model.vehicleNumber,
                enabled: !readOnly,
                textCapitalization: TextCapitalization.characters,
                onChanged: viewModel.updateVehicleNumber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 130),
          child: _FormCard(
            title: 'Payout accounts',
            subtitle: 'Used later for JazzCash/EasyPaisa withdrawal requests.',
            children: [
              _AppTextField(
                label: 'JazzCash number',
                initialValue: model.jazzCashNumber,
                enabled: !readOnly,
                keyboardType: TextInputType.phone,
                onChanged: viewModel.updateJazzCashNumber,
              ),
              _AppTextField(
                label: 'EasyPaisa number',
                initialValue: model.easyPaisaNumber,
                enabled: !readOnly,
                keyboardType: TextInputType.phone,
                onChanged: viewModel.updateEasyPaisaNumber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _FormCard(
            title: 'Document verification',
            subtitle:
                'Upload real images from camera/gallery. Images are saved realtime for admin review; no manual URLs required.',
            children: [
              _ImageUploadTile(
                label: 'Profile photo',
                value: model.profilePhotoUrl,
                enabled: !readOnly,
                requiredDoc: false,
                onGallery: () =>
                    viewModel.pickProfilePhoto(source: ImageSource.gallery),
                onCamera: () =>
                    viewModel.pickProfilePhoto(source: ImageSource.camera),
              ),
              _ImageUploadTile(
                label: 'CNIC front',
                value: model.cnicFrontUrl,
                enabled: !readOnly,
                requiredDoc: true,
                onGallery: () =>
                    viewModel.pickCnicFront(source: ImageSource.gallery),
                onCamera: () =>
                    viewModel.pickCnicFront(source: ImageSource.camera),
              ),
              _ImageUploadTile(
                label: 'CNIC back',
                value: model.cnicBackUrl,
                enabled: !readOnly,
                requiredDoc: true,
                onGallery: () =>
                    viewModel.pickCnicBack(source: ImageSource.gallery),
                onCamera: () =>
                    viewModel.pickCnicBack(source: ImageSource.camera),
              ),
              _ImageUploadTile(
                label: 'License front',
                value: model.licenseFrontUrl,
                enabled: !readOnly,
                requiredDoc: false,
                onGallery: () =>
                    viewModel.pickLicenseFront(source: ImageSource.gallery),
                onCamera: () =>
                    viewModel.pickLicenseFront(source: ImageSource.camera),
              ),
              _ImageUploadTile(
                label: 'Bike / vehicle photo',
                value: model.vehiclePhotoUrl,
                enabled: !readOnly,
                requiredDoc: true,
                onGallery: () =>
                    viewModel.pickVehiclePhoto(source: ImageSource.gallery),
                onCamera: () =>
                    viewModel.pickVehiclePhoto(source: ImageSource.camera),
              ),
            ],
          ),
        ),
        if (viewModel.hasError) ...[
          const SizedBox(height: 12),
          _ErrorText(message: viewModel.errorMessage!),
        ],
        const SizedBox(height: 22),
        if (!model.isApproved)
          _PrimaryButton(
            isBusy: viewModel.isBusy,
            label: model.isPending
                ? 'RESUBMIT VERIFICATION'
                : 'SUBMIT VERIFICATION',
            icon: Icons.verified_user_outlined,
            onPressed: readOnly && !model.isRejected ? null : onSubmit,
          ),
        if (model.isApproved)
          _PrimaryButton(
            isBusy: false,
            label: 'CONTINUE TO APP',
            icon: Icons.arrow_forward_rounded,
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.home),
          ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ImageUploadTile extends StatelessWidget {
  const _ImageUploadTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.requiredDoc,
    required this.onGallery,
    required this.onCamera,
  });

  final String label;
  final String value;
  final bool enabled;
  final bool requiredDoc;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final hasImage = value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage
              ? VerificationView._goldColor
              : const Color(0xFFE7E2D3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: hasImage
                  ? _InlineDocumentImage(value: value)
                  : Container(
                      color: Colors.white,
                      child: Icon(
                        requiredDoc ? Icons.badge_rounded : Icons.image_rounded,
                        color: VerificationView._mutedColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: VerificationView._inkColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (requiredDoc)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: VerificationView._dangerColor.withValues(
                            alpha: .12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: VerificationView._dangerColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasImage
                      ? 'Uploaded and ready for admin review'
                      : 'Tap camera or gallery to upload',
                  style: const TextStyle(
                    color: VerificationView._mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: enabled ? onCamera : null,
                      icon: const Icon(Icons.photo_camera_rounded, size: 18),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: enabled ? onGallery : null,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDocumentImage extends StatelessWidget {
  const _InlineDocumentImage({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final clean = value.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _broken(),
      );
    }
    try {
      final normalized = clean.contains(',') ? clean.split(',').last : clean;
      return Image.memory(
        base64Decode(normalized),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _broken(),
      );
    } catch (_) {
      return _broken();
    }
  }

  Widget _broken() => Container(
    color: Colors.white,
    alignment: Alignment.center,
    child: const Icon(
      Icons.broken_image_outlined,
      color: VerificationView._mutedColor,
    ),
  );
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
          const TextSpan(text: 'We sent a 6-digit verification code to '),
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

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({required this.model});

  final VerificationModel model;

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Rider Profile & Documents\n',
            style: TextStyle(
              color: VerificationView._inkColor,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          WidgetSpan(child: SizedBox(height: 24)),
          TextSpan(
            text:
                'Complete your profile and submit documents. You can receive realtime orders after admin approval.',
          ),
        ],
      ),
      style: TextStyle(
        color: VerificationView._mutedColor,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.model});

  final VerificationModel model;

  @override
  Widget build(BuildContext context) {
    final status = model.verificationStatus;
    final color = status == 'approved'
        ? VerificationView._successColor
        : status == 'rejected'
        ? VerificationView._dangerColor
        : status == 'pending'
        ? VerificationView._goldColor
        : VerificationView._offlineColor;
    final title = status == 'approved'
        ? 'Approved'
        : status == 'rejected'
        ? 'Rejected'
        : status == 'pending'
        ? 'Pending review'
        : 'Not submitted';
    final subtitle = status == 'approved'
        ? 'Your rider account is verified. You can go online from home.'
        : status == 'rejected'
        ? (model.rejectionReason.isEmpty
              ? 'Please update your details and submit again.'
              : model.rejectionReason)
        : status == 'pending'
        ? 'Admin can approve/reject from admin/riderVerifications in Firebase.'
        : 'Submit your profile and documents to start receiving orders.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VerificationView._borderGoldColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: VerificationView._inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: VerificationView._mutedColor,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E2D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: VerificationView._inkColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: VerificationView._mutedColor,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ...children
              .expand((child) => [child, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$initialValue'),
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      cursorColor: VerificationView._inkColor,
      style: const TextStyle(
        color: VerificationView._inkColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? const Color(0xFFFAFAFF) : const Color(0xFFF1F2F4),
        labelStyle: const TextStyle(
          color: VerificationView._mutedColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE3DDC8)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE3E6EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: VerificationView._goldColor,
            width: 2,
          ),
        ),
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(VerificationModel.codeLength, (index) {
        return _CodeBox(
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
      width: 43,
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
  const _ResendBlock({
    required this.timerText,
    required this.canResend,
    required this.onResend,
  });

  final String timerText;
  final bool canResend;
  final VoidCallback onResend;

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
            TextButton(
              onPressed: canResend ? onResend : null,
              child: Text(
                canResend ? 'Resend Code' : 'Resend Code',
                style: TextStyle(
                  color: canResend
                      ? VerificationView._darkGoldColor
                      : const Color(0xFFB9A565),
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.isBusy,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final bool isBusy;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 13),
                    Icon(icon, size: 21),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: VerificationView._dangerColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
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
