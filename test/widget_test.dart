import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:vyraal_rider/config/routes/app_routes.dart';
import 'package:vyraal_rider/core/realtime/rider_realtime_service.dart';
import 'package:vyraal_rider/app.dart';
import 'package:vyraal_rider/features/home/views/home_view.dart';
import 'package:vyraal_rider/features/login/views/login_view.dart';
import 'package:vyraal_rider/features/navigation/views/delivery_navigation_view.dart';
import 'package:vyraal_rider/features/navigation/views/pickup_navigation_view.dart';
import 'package:vyraal_rider/features/verification/views/verification_view.dart';
import 'package:vyraal_rider/features/withdraw/views/withdraw_view.dart';

void main() {
  testWidgets('shows the login page', (WidgetTester tester) async {
    await tester.pumpWidget(const VyraalRiderApp());

    expect(find.text('Vyraal'), findsOneWidget);
    expect(find.text('Welcome Rider'), findsOneWidget);
    expect(find.text('+92'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.text('Enter your phone number to continue'), findsOneWidget);
  });

  testWidgets('login page renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const VyraalRiderApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    }
  });

  testWidgets('verification page renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: VerificationView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Vyraal'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'VERIFY'), findsOneWidget);
    }
  });

  testWidgets('dashboard page renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: HomeView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('DAILY SUMMARY'), findsOneWidget);
      expect(find.text('Available Orders'), findsOneWidget);
      expect(find.text('Amanat Dairy'), findsOneWidget);
      expect(
        find.text('Pickup requests within 3 km of your current location'),
        findsOneWidget,
      );
    }
  });

  testWidgets('order discovery accepts and locks an order in realtime', (
    WidgetTester tester,
  ) async {
    final events = <RiderRealtimeEvent>[];
    final subscription = RiderRealtimeService.instance.events.listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.pickupNavigation: (_) => const PickupNavigationView(),
        },
        home: const HomeView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Delivering to DHA Phase 5'), findsOneWidget);
    expect(find.text('60s'), findsWidgets);

    final acceptButton = find.widgetWithText(OutlinedButton, 'Accept').first;
    await tester.ensureVisible(acceptButton);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    expect(find.text('HEADING TO SELLER'), findsOneWidget);
    expect(
      events.map((event) => event.type),
      containsAll(['order_accepted', 'order_locked_to_rider']),
    );
  });

  testWidgets('order request can decline or expire to next rider', (
    WidgetTester tester,
  ) async {
    final events = <RiderRealtimeEvent>[];
    final subscription = RiderRealtimeService.instance.events.listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    await tester.pumpWidget(const MaterialApp(home: HomeView()));
    await tester.pumpAndSettle();

    final declineButton = find.widgetWithText(OutlinedButton, 'Decline').first;
    await tester.ensureVisible(declineButton);
    await tester.tap(declineButton);
    await tester.pump();

    expect(find.text('Amanat Dairy'), findsNothing);
    expect(events.map((event) => event.type), contains('order_declined'));

    await tester.pump(const Duration(seconds: 61));
    await tester.pump();

    expect(
      find.text(
        'No nearby orders right now. Stay online and new requests will appear here.',
      ),
      findsOneWidget,
    );
    expect(
      events.map((event) => event.type),
      contains('order_sent_to_next_rider'),
    );
  });

  testWidgets('notifications show realtime alerts and admin updates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeView()));
    await tester.pump();

    expect(find.text('New order request'), findsOneWidget);

    RiderRealtimeService.instance.payoutApproved(4925);
    await tester.pump();
    await tester.pump();

    RiderRealtimeService.instance.adminMessage(
      'Documents review will be faster today.',
    );
    await tester.pump();
    await tester.pump();

    RiderRealtimeService.instance.announcement(
      'Service announcement',
      'Rain expected tonight. Drive carefully.',
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Service announcement'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Payout approved'), findsOneWidget);
    expect(find.text('Admin message'), findsWidgets);
    expect(
      find.text('Rain expected tonight. Drive carefully.'),
      findsOneWidget,
    );
    expect(find.textContaining('Your payout of Rs. 4925'), findsOneWidget);
  });

  testWidgets('earnings page renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: HomeView()));
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      if (exception != null) {
        debugDumpRenderTree();
      }
      expect(exception, isNull);
      expect(find.text('WEEKLY TOTAL'), findsOneWidget);
      expect(find.text('Rs. 8,200'), findsOneWidget);
      expect(find.text('Trip History'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Withdraw Earnings'),
        findsOneWidget,
      );
    }
  });

  testWidgets('withdraw page renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: WithdrawView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('Select Payout Method'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'REQUEST WITHDRAWAL'),
        findsOneWidget,
      );
    }
  });

  testWidgets('trip history tab renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: HomeView()));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TOTAL TRIPS'), findsOneWidget);
      expect(find.text('HOURS ONLINE'), findsOneWidget);
      expect(find.text('Royal Bakeries, Gulberg'), findsOneWidget);
    }
  });

  testWidgets('profile tab renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: HomeView()));
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ahmed Ali'), findsWidgets);
      expect(find.text('Profile Setup'), findsOneWidget);
      expect(find.text('LOGOUT ACCOUNT'), findsOneWidget);
    }
  });

  testWidgets('profile controls emit realtime events', (
    WidgetTester tester,
  ) async {
    final events = <RiderRealtimeEvent>[];
    final subscription = RiderRealtimeService.instance.events.listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    await tester.pumpWidget(const MaterialApp(home: HomeView()));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Ahmed Rider',
    );
    await tester.pump();

    tester.widget<Switch>(find.byType(Switch)).onChanged!(false);
    await tester.pump();

    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.cloud_upload_outlined).first,
            matching: find.byType(IconButton),
          ),
        )
        .onPressed!();
    await tester.pump();

    expect(find.text('Ahmed Rider'), findsAtLeastNWidgets(1));
    expect(
      events.map((event) => event.type),
      containsAll([
        'rider_profile_updated',
        'rider_status_changed',
        'rider_document_uploaded',
      ]),
    );
  });

  testWidgets('profile settings are dynamic and realtime aware', (
    WidgetTester tester,
  ) async {
    final events = <RiderRealtimeEvent>[];
    final subscription = RiderRealtimeService.instance.events.listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.home: (_) => const HomeView(),
        },
        home: const HomeView(),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('English'));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urdu').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Alerts'));
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();

    expect(find.text('Urdu'), findsOneWidget);
    expect(find.text('Muted'), findsOneWidget);

    await tester.ensureVisible(find.text('Help Center'));
    await tester.tap(find.text('Help Center'));
    await tester.pump();

    await tester.ensureVisible(find.text('Contact Support'));
    await tester.tap(find.text('Contact Support'));
    await tester.pump();

    await tester.ensureVisible(find.text('LOGOUT ACCOUNT'));
    await tester.tap(find.text('LOGOUT ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Rider'), findsOneWidget);
    expect(
      events.map((event) => event.type),
      containsAll([
        'rider_language_changed',
        'rider_alerts_changed',
        'rider_support_requested',
        'rider_logged_out',
      ]),
    );
  });

  testWidgets('pickup navigation renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(const MaterialApp(home: PickupNavigationView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HEADING TO SELLER'), findsOneWidget);
      expect(find.text('Amanat Dairy'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Picked Up'), findsOneWidget);
    }
  });

  testWidgets('delivery navigation renders on common device sizes', (
    WidgetTester tester,
  ) async {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 1024),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(
        const MaterialApp(home: DeliveryNavigationView()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Delivery in Progress'), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'DELIVERED'), findsOneWidget);
    }
  });

  testWidgets('delivery confirmation emits realtime customer updates', (
    WidgetTester tester,
  ) async {
    final events = <RiderRealtimeEvent>[];
    final subscription = RiderRealtimeService.instance.events.listen(
      events.add,
    );
    addTearDown(subscription.cancel);

    await tester.pumpWidget(const MaterialApp(home: DeliveryNavigationView()));
    await tester.pumpAndSettle();

    final callButton = find.byTooltip('Call customer');
    await tester.tap(callButton);
    await tester.pump();

    await tester.ensureVisible(find.text('Upload delivery photo'));
    await tester.tap(find.text('Upload delivery photo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'DELIVERED'));
    await tester.tap(find.widgetWithText(FilledButton, 'DELIVERED'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery photo uploaded'), findsOneWidget);
    expect(
      find.textContaining('Your order has been delivered!'),
      findsOneWidget,
    );
    expect(
      events.map((event) => event.type),
      containsAll([
        'customer_call_requested',
        'delivery_photo_uploaded',
        'order_delivered',
        'customer_notification_sent',
      ]),
    );
  });
}
