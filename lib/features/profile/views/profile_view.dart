import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/routes/app_routes.dart';
import '../../../core/auth/rider_auth_service.dart';
import '../../../core/services/rider_image_upload_service.dart';
import '../../login/models/rider_user_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _backgroundColor = Color(0xFFFFFBF2);
  static const _inkColor = Color(0xFF211B10);
  static const _mutedColor = Color(0xFF776F61);
  static const _goldColor = Color(0xFFFFC107);
  static const _borderColor = Color(0xFFFFE0A3);
  static const _successColor = Color(0xFF10B981);

  final RiderAuthService _auth = RiderAuthService();
  final RiderImageUploadService _imageUpload = RiderImageUploadService();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _vehicleNumberController;
  RiderUserModel? _rider;
  StreamSubscription<RiderUserModel?>? _profileSub;
  bool _loading = true;
  bool _loggingOut = false;
  bool _saving = false;
  String? _draftPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _vehicleTypeController = TextEditingController();
    _vehicleNumberController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final rider = await _auth.restoreSavedSession();
    if (!mounted) return;
    setState(() {
      _rider = rider;
      _loading = false;
    });
    if (rider != null) _syncControllers(rider);

    final riderId = rider?.id;
    if (riderId == null || riderId.isEmpty) return;
    _profileSub = _auth.watchUser(riderId).listen((updated) {
      if (!mounted || updated == null) return;
      setState(() => _rider = updated);
      if (!_saving) _syncControllers(updated);
    });
  }

  void _syncControllers(RiderUserModel rider) {
    _nameController.text = rider.name;
    _phoneController.text = rider.phone;
    _cityController.text = rider.city;
    _addressController.text = rider.address;
    _vehicleTypeController.text = rider.vehicleType;
    _vehicleNumberController.text = rider.vehicleNumber;
    _draftPhotoUrl = rider.profilePhotoUrl;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _imageUpload.pickDocumentImage(
      source: source,
      imageQuality: 70,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (picked == null || !mounted) return;
    if (picked.bytesLength > 900000) {
      _showMessage('Image is too large. Please choose a smaller photo.');
      return;
    }
    setState(() => _draftPhotoUrl = picked.dataUri);
  }

  Future<void> _saveProfile() async {
    final rider = _rider;
    if (rider == null || _saving) return;
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showMessage('Name and phone number are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _auth.updateRiderProfile(
        riderId: rider.id,
        name: _nameController.text,
        phone: _phoneController.text,
        city: _cityController.text,
        address: _addressController.text,
        vehicleType: _vehicleTypeController.text,
        vehicleNumber: _vehicleNumberController.text,
        profilePhotoUrl: _draftPhotoUrl,
      );
      if (mounted) {
        setState(() {
          _rider = rider.copyWith(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            vehicleType: _vehicleTypeController.text.trim(),
            vehicleNumber: _vehicleNumberController.text.trim(),
            profilePhotoUrl: _draftPhotoUrl ?? rider.profilePhotoUrl,
          );
        });
      }
      _showMessage('Profile saved in realtime.');
    } catch (_) {
      _showMessage('Could not save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  void dispose() {
    unawaited(_profileSub?.cancel());
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = _rider;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        foregroundColor: _inkColor,
        centerTitle: true,
        title: const Text(
          'Rider Profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _goldColor))
            : rider == null
            ? _EmptyProfile(onLogin: () => unawaited(_logout()))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  _ProfileHeader(
                    rider: rider,
                    photoUrl: _draftPhotoUrl ?? rider.profilePhotoUrl,
                    onPickGallery: () =>
                        unawaited(_pickPhoto(ImageSource.gallery)),
                    onPickCamera: () =>
                        unawaited(_pickPhoto(ImageSource.camera)),
                  ),
                  const SizedBox(height: 14),
                  _StatusCard(rider: rider),
                  const SizedBox(height: 14),
                  _EditableSection(
                    nameController: _nameController,
                    phoneController: _phoneController,
                    cityController: _cityController,
                    addressController: _addressController,
                    vehicleTypeController: _vehicleTypeController,
                    vehicleNumberController: _vehicleNumberController,
                  ),
                  const SizedBox(height: 14),
                  _InfoSection(
                    title: 'Contact',
                    rows: [
                      _InfoRow(Icons.phone_rounded, 'Phone', rider.phone),
                      _InfoRow(
                        Icons.alternate_email_rounded,
                        'Email',
                        rider.email ?? 'Not saved',
                      ),
                      _InfoRow(Icons.location_city_rounded, 'City', rider.city),
                      _InfoRow(Icons.home_rounded, 'Address', rider.address),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoSection(
                    title: 'Vehicle',
                    rows: [
                      _InfoRow(
                        Icons.two_wheeler_rounded,
                        'Vehicle',
                        rider.vehicleType,
                      ),
                      _InfoRow(
                        Icons.confirmation_number_rounded,
                        'Vehicle Number',
                        rider.vehicleNumber,
                      ),
                      _InfoRow(Icons.badge_rounded, 'CNIC', rider.cnicNumber),
                      _InfoRow(
                        Icons.credit_card_rounded,
                        'License',
                        rider.licenseNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => unawaited(_saveProfile()),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldColor,
                      foregroundColor: _inkColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loggingOut ? null : () => unawaited(_logout()),
                    icon: _loggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _inkColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.rider,
    required this.photoUrl,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  final RiderUserModel rider;
  final String photoUrl;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProfileViewState._borderColor),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _ProfileViewState._goldColor,
                backgroundImage: _profileImage(photoUrl),
                child: _profileImage(photoUrl) == null
                    ? const Icon(
                        Icons.delivery_dining_rounded,
                        color: _ProfileViewState._inkColor,
                        size: 34,
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: PopupMenuButton<ImageSource>(
                  tooltip: 'Change photo',
                  onSelected: (source) {
                    if (source == ImageSource.camera) {
                      onPickCamera();
                    } else {
                      onPickGallery();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ImageSource.gallery,
                      child: Text('Gallery'),
                    ),
                    PopupMenuItem(
                      value: ImageSource.camera,
                      child: Text('Camera'),
                    ),
                  ],
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _ProfileViewState._borderColor),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: _ProfileViewState._inkColor,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name.trim().isEmpty ? 'Rider' : rider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileViewState._inkColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rider.phone.isEmpty ? 'Realtime rider account' : rider.phone,
                  style: const TextStyle(
                    color: _ProfileViewState._mutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _profileImage(String value) {
    final photo = value.trim();
    if (photo.isEmpty || photo == 'null') return null;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return NetworkImage(photo);
    }
    if (photo.startsWith('data:image')) {
      final comma = photo.indexOf(',');
      if (comma > -1) {
        try {
          return MemoryImage(
            base64Decode(base64.normalize(photo.substring(comma + 1))),
          );
        } catch (_) {
          return null;
        }
      }
    }
    if (photo.length < 32) return null;
    try {
      return MemoryImage(base64Decode(base64.normalize(photo)));
    } catch (_) {
      return null;
    }
  }
}

class _EditableSection extends StatelessWidget {
  const _EditableSection({
    required this.nameController,
    required this.phoneController,
    required this.cityController,
    required this.addressController,
    required this.vehicleTypeController,
    required this.vehicleNumberController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final TextEditingController vehicleTypeController;
  final TextEditingController vehicleNumberController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProfileViewState._borderColor),
      ),
      child: Column(
        children: [
          _ProfileField(
            controller: nameController,
            label: 'Name',
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: cityController,
            label: 'City',
            icon: Icons.location_city_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: addressController,
            label: 'Address',
            icon: Icons.home_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProfileField(
                  controller: vehicleTypeController,
                  label: 'Vehicle',
                  icon: Icons.two_wheeler_rounded,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileField(
                  controller: vehicleNumberController,
                  label: 'Vehicle No.',
                  icon: Icons.confirmation_number_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFFFFCF4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileViewState._borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileViewState._borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _ProfileViewState._goldColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.rider});

  final RiderUserModel rider;

  @override
  Widget build(BuildContext context) {
    final online = rider.isOnline || rider.workStatus.toLowerCase() == 'online';
    final verified =
        rider.isVerified ||
        rider.verificationStatus.toLowerCase() == 'approved';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: online ? _ProfileViewState._goldColor : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProfileViewState._borderColor),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.radar_rounded : Icons.power_settings_new_rounded,
            color: online
                ? _ProfileViewState._successColor
                : _ProfileViewState._mutedColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              online ? 'Online and receiving realtime orders' : 'Offline',
              style: const TextStyle(
                color: _ProfileViewState._inkColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _Pill(verified ? 'Verified' : rider.verificationStatus),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProfileViewState._borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ProfileViewState._inkColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            row,
            if (row != rows.last)
              const Divider(height: 18, color: Color(0xFFFFF0C7)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'Not saved' : value.trim();
    return Row(
      children: [
        Icon(icon, size: 20, color: _ProfileViewState._mutedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _ProfileViewState._mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileViewState._inkColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.trim().isEmpty ? 'Pending' : label,
        style: const TextStyle(
          color: _ProfileViewState._inkColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_rounded,
              size: 44,
              color: _ProfileViewState._mutedColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'No rider session found',
              style: TextStyle(
                color: _ProfileViewState._inkColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}
