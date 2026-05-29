import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config/routes/app_routes.dart';
import 'core/auth/rider_auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/views/home_view.dart';
import 'features/login/views/login_view.dart';
import 'features/navigation/views/delivery_navigation_view.dart';
import 'features/navigation/views/pickup_navigation_view.dart';
import 'features/profile/views/profile_view.dart';
import 'features/verification/views/verification_view.dart';
import 'features/withdraw/views/withdraw_view.dart';
import 'history/views/history_view.dart';

class VyraalRiderApp extends StatefulWidget {
  const VyraalRiderApp({super.key});

  @override
  State<VyraalRiderApp> createState() => _VyraalRiderAppState();
}

class _VyraalRiderAppState extends State<VyraalRiderApp> {
  late final Future<String> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _determineInitialRoute();
  }

  Future<String> _determineInitialRoute() async {
    try {
      final authService = RiderAuthService();
      final savedUser = await authService.restoreSavedSession();
      
      if (savedUser != null) {
        return AppRoutes.home;
      }

      // Check Firebase auth state
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return AppRoutes.home;
      }

      return AppRoutes.login; // No saved session, show login
    } catch (e) {
      debugPrint('Route determination error: $e');
      return AppRoutes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'Vyraal Rider',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final initialRoute = snapshot.data ?? AppRoutes.login;

        return MaterialApp(
          key: ValueKey(initialRoute),
          title: 'Vyraal Rider',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: initialRoute,
          routes: {
            AppRoutes.login: (_) => const LoginView(),
            AppRoutes.verification: (_) => const VerificationView(),
            AppRoutes.home: (_) => const HomeView(),
            AppRoutes.profile: (_) => const ProfileView(),
            AppRoutes.history: (_) => const HistoryView(),
            AppRoutes.withdraw: (_) => const WithdrawView(),
            AppRoutes.pickupNavigation: (_) => const PickupNavigationView(),
            AppRoutes.deliveryNavigation: (_) => const DeliveryNavigationView(),
          },
        );
      },
    );
  }
}
