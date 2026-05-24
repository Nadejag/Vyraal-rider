import 'package:flutter/material.dart';

import 'config/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/home/views/home_view.dart';
import 'features/login/views/login_view.dart';
import 'features/navigation/views/delivery_navigation_view.dart';
import 'features/navigation/views/pickup_navigation_view.dart';
import 'features/verification/views/verification_view.dart';
import 'features/withdraw/views/withdraw_view.dart';

class VyraalRiderApp extends StatelessWidget {
  const VyraalRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyraal Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginView(),
        AppRoutes.verification: (_) => const VerificationView(),
        AppRoutes.home: (_) => const HomeView(),
        AppRoutes.withdraw: (_) => const WithdrawView(),
        AppRoutes.pickupNavigation: (_) => const PickupNavigationView(),
        AppRoutes.deliveryNavigation: (_) => const DeliveryNavigationView(),
      },
    );
  }
}
