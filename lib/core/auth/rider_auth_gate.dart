import 'package:flutter/material.dart';

import '../../features/login/models/rider_user_model.dart';
import 'rider_auth_service.dart';

class RiderAuthGate extends StatefulWidget {
  const RiderAuthGate({
    super.key,
    required this.loginBuilder,
    required this.homeBuilder,
    this.pendingBuilder,
    this.setupBuilder,
  });

  final WidgetBuilder loginBuilder;
  final WidgetBuilder homeBuilder;
  final WidgetBuilder? pendingBuilder;
  final WidgetBuilder? setupBuilder;

  @override
  State<RiderAuthGate> createState() => _RiderAuthGateState();
}

class _RiderAuthGateState extends State<RiderAuthGate> {
  final _auth = RiderAuthService();
  late Future<RiderUserModel?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _auth.restoreSavedSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RiderUserModel?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final initial = snapshot.data;
        if (initial == null) return widget.loginBuilder(context);

        return StreamBuilder<RiderUserModel?>(
          initialData: initial,
          stream: _auth.watchUser(initial.id),
          builder: (context, riderSnapshot) {
            final rider = riderSnapshot.data ?? initial;
            final status = rider.verificationStatus.toLowerCase().trim();
            final approved = rider.isVerified || status == 'approved';
            final pending = status == 'pending' || status == 'submitted' || status == 'in_review';
            final needsSetup = status.isEmpty || status == 'not_submitted' || status == 'rejected' || status == 'needs_review';

            if (approved) return widget.homeBuilder(context);
            if (needsSetup && widget.setupBuilder != null) return widget.setupBuilder!(context);
            if (pending && widget.pendingBuilder != null) return widget.pendingBuilder!(context);
            return _PendingVerificationScreen(rider: rider, auth: _auth);
          },
        );
      },
    );
  }
}

class _PendingVerificationScreen extends StatelessWidget {
  const _PendingVerificationScreen({required this.rider, required this.auth});

  final RiderUserModel rider;
  final RiderAuthService auth;

  @override
  Widget build(BuildContext context) {
    final status = rider.verificationStatus.toLowerCase();
    final rejected = status == 'rejected' || status == 'needs_review';
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    rejected ? Icons.info_rounded : Icons.verified_user_rounded,
                    size: 52,
                    color: rejected ? const Color(0xFFEF4444) : const Color(0xFFFFC914),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    rejected ? 'Verification needs update' : 'Verification pending',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejected
                        ? (rider.rejectionReason.isEmpty ? 'Please update and resubmit your documents.' : rider.rejectionReason)
                        : 'Your documents are in admin review. After approval, this screen will open the rider app automatically.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280), height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}