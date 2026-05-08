import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/switch_mode_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/driver_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/benefits_screen.dart';
import '../screens/auth/driver_signup_personal_info_screen.dart';
import '../screens/auth/driver_signup_selfie_screen.dart';
import '../screens/auth/driver_signup_license_screen.dart';
import '../screens/auth/driver_signup_vehicle_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/passenger/passenger_dashboard_screen.dart';
import '../screens/passenger/scan_qr_screen.dart';
import '../screens/passenger/notifications_screen.dart';
import '../screens/passenger/account_screen.dart';
import '../screens/passenger/wallet_top_up_screen.dart';
import '../screens/passenger/confirm_payment_screen.dart';
import '../screens/passenger/payment_success_screen.dart';
import '../screens/passenger/subscription_plans_screen.dart';
import '../screens/passenger/favorite_routes_screen.dart';
import '../screens/passenger/legazpi_loop_calculation_screen.dart';
import '../screens/passenger/route_detail_screen.dart';
import '../models/route_model.dart';
import '../screens/driver/driver_dashboard_screen.dart';
import '../widgets/passenger_bottom_nav.dart';

int _previousIndex = 0;

int _getTabIndex(String? location) {
  if (location == null) return 0;
  if (location.startsWith('/passenger/scan')) return 1;
  if (location.startsWith('/passenger/account')) return 2;
  return 0;
}

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  final index = _getTabIndex(state.uri.path);
  final slideLeft = index >= _previousIndex;
  _previousIndex = index;

  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(
            begin: Offset(slideLeft ? 1.0 : -1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      );
    },
  );
}

class _PassengerShellLayout extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const _PassengerShellLayout({required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.uri.path;
    late PassengerTab activeTab;

    if (location.startsWith('/passenger/scan')) {
      activeTab = PassengerTab.scan;
    } else if (location.startsWith('/passenger/account')) {
      activeTab = PassengerTab.account;
    } else {
      activeTab = PassengerTab.home;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: PassengerBottomNav(activeTab: activeTab),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/benefits',
      name: 'benefits',
      builder: (context, state) => const BenefitsScreen(),
    ),
    GoRoute(
      path: '/select-mode',
      name: 'switch_mode',
      builder: (context, state) => const SwitchModeScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          _PassengerShellLayout(state: state, child: child),
      routes: [
        GoRoute(
          path: '/passenger',
          name: 'passenger_dashboard',
          pageBuilder: (context, state) =>
              _slideTransition(state, const PassengerDashboardScreen()),
        ),
        GoRoute(
          path: '/passenger/scan',
          name: 'scan_qr',
          pageBuilder: (context, state) =>
              _slideTransition(state, const ScanQrScreen()),
        ),
        GoRoute(
          path: '/passenger/account',
          name: 'account',
          pageBuilder: (context, state) =>
              _slideTransition(state, const AccountScreen()),
        ),
        GoRoute(
          path: '/passenger/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/passenger/wallet',
          name: 'wallet_top_up',
          builder: (context, state) => const WalletTopUpScreen(),
        ),
        GoRoute(
          path: '/passenger/confirm-payment',
          name: 'confirm_payment',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ConfirmPaymentScreen(
              startingPoint: extra?['startingPoint'] ?? 'Tagas',
              dropOffPoint: extra?['dropOffPoint'] ?? 'Ayala Mall',
              distance: extra?['distance']?.toDouble() ?? 0.0,
              vehicleType: extra?['vehicleType'] ?? 'puj',
              baseFare: extra?['baseFare'] ?? (extra?['fare'] ?? 13.50),
              fare: extra?['fare'] ?? 13.50,
              totalFare: extra?['totalFare'] ?? 0.0,
              hasDiscount: extra?['hasDiscount'] ?? false,
              tipAmount: extra?['tip']?.toInt() ?? extra?['tipAmount'] ?? 0,
              estimatedMinutes: extra?['estimatedMinutes'] ?? 0,
              paymentMethod: extra?['paymentMethod'] ?? 'Wallet',
            );
          },
        ),
        GoRoute(
          path: '/passenger/payment-success',
          name: 'payment_success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentSuccessScreen(
              amount: extra?['amount'] ?? 0.0,
              paymentMethod: extra?['paymentMethod'] ?? 'Unknown',
            );
          },
        ),
        GoRoute(
          path: '/passenger/subscription',
          name: 'subscription_plans',
          builder: (context, state) => const SubscriptionPlansScreen(),
        ),
        GoRoute(
          path: '/passenger/routes',
          name: 'favorite_routes',
          builder: (context, state) => const FavoriteRoutesScreen(),
        ),
        GoRoute(
          path: '/passenger/route_detail',
          name: 'route_detail',
          builder: (context, state) {
            final route = state.extra as RouteModel;
            return RouteDetailScreen(route: route);
          },
        ),
        GoRoute(
          path: '/passenger/calculation',
          name: 'legazpi_loop_calculation',
          builder: (context, state) {
            final route = state.extra is RouteModel
                ? state.extra as RouteModel
                : null;
            return LegazpiLoopCalculationScreen(initialRoute: route);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/driver-login',
      name: 'driver_login',
      builder: (context, state) => const DriverLoginScreen(),
    ),
    GoRoute(
      path: '/driver-signup',
      name: 'driver_signup_personal_info',
      builder: (context, state) => const DriverSignupPersonalInfoScreen(),
    ),
    GoRoute(
      path: '/driver-signup-selfie',
      name: 'driver_signup_selfie',
      builder: (context, state) => const DriverSignupSelfieScreen(),
    ),
    GoRoute(
      path: '/driver-signup-license',
      name: 'driver_signup_license',
      builder: (context, state) => const DriverSignupLicenseScreen(),
    ),
    GoRoute(
      path: '/driver-signup-vehicle',
      name: 'driver_signup_vehicle',
      builder: (context, state) => const DriverSignupVehicleScreen(),
    ),
    GoRoute(
      path: '/driver',
      name: 'driver_dashboard',
      builder: (context, state) => const DriverDashboardScreen(),
    ),
  ],
);
