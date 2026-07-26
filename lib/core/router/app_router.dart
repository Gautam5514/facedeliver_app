import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_shell.dart';
import '../../features/admin/analytics_screen.dart';
import '../../features/admin/billing_screen.dart';
import '../../features/admin/dashboard_screen.dart';
import '../../features/admin/event_detail_screen.dart';
import '../../features/admin/events_screen.dart';
import '../../features/admin/admin_profile_screen.dart';
import '../../features/auth/admin_auth_screen.dart';
import '../../features/auth/guest_login_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/guest/gallery_screen.dart';
import '../../features/guest/guest_account_screen.dart';
import '../../features/guest/register_screen.dart';
import '../../features/guest/scan_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../state/session_controller.dart';

class Routes {
  const Routes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const guestLogin = '/sign-in/guest';
  static const adminAuth = '/sign-in/organiser';
  static const scan = '/scan';
  static const register = '/register';

  static const gallery = '/gallery';
  static const guestAccount = '/gallery/account';

  static const adminDashboard = '/admin';
  static const adminEvents = '/admin/events';
  static const adminAnalytics = '/admin/analytics';
  static const adminBilling = '/admin/billing';
  static const adminProfile = '/admin/profile';

  static String adminEvent(String id) => '/admin/events/$id';
}

/// Routes reachable without a session. Guest registration is deliberately open:
/// someone scanning a QR code at an event has no account yet.
const _publicRoutes = <String>{
  Routes.welcome,
  Routes.guestLogin,
  Routes.adminAuth,
  Routes.scan,
  Routes.register,
};

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (session.status == SessionStatus.booting) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final isPublic = _publicRoutes.contains(location);
      final home = session.isAdmin ? Routes.adminDashboard : Routes.gallery;

      if (!session.isSignedIn) {
        if (isPublic) return null;
        return Routes.welcome;
      }

      // Signed in: bounce away from the entry screens…
      if (location == Routes.splash ||
          location == Routes.welcome ||
          location == Routes.guestLogin ||
          location == Routes.adminAuth) {
        return home;
      }

      // …and keep each role inside its own section.
      if (session.isAdmin && location.startsWith(Routes.gallery)) return home;
      if (!session.isAdmin && location.startsWith(Routes.adminDashboard)) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.guestLogin,
        builder: (_, _) => const GuestLoginScreen(),
      ),
      GoRoute(
        path: Routes.adminAuth,
        builder: (_, _) => const AdminAuthScreen(),
      ),
      GoRoute(
        path: Routes.scan,
        builder: (_, _) => const ScanScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, state) => RegisterScreen(
          eventCode: state.uri.queryParameters['eventId'] ?? '',
        ),
      ),

      // ── Guest ────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.gallery,
        builder: (_, _) => const GalleryScreen(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (_, _) => const GuestAccountScreen(),
          ),
        ],
      ),

      // ── Organiser ────────────────────────────────────────────────────────
      // A shell route keeps the bottom navigation mounted across tabs so the
      // switch is instant and scroll position survives.
      ShellRoute(
        builder: (context, state, child) => AdminShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.adminDashboard,
            pageBuilder: (_, state) => _fade(state, const DashboardScreen()),
          ),
          GoRoute(
            path: Routes.adminEvents,
            pageBuilder: (_, state) => _fade(state, const EventsScreen()),
          ),
          GoRoute(
            path: Routes.adminAnalytics,
            pageBuilder: (_, state) => _fade(state, const AnalyticsScreen()),
          ),
          GoRoute(
            path: Routes.adminBilling,
            pageBuilder: (_, state) => _fade(state, const BillingScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/events/:id',
        builder: (_, state) =>
            EventDetailScreen(eventId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.adminProfile,
        builder: (_, _) => const AdminProfileScreen(),
      ),
    ],
  );
}

/// Tab switches cross-fade instead of sliding — a slide implies hierarchy that
/// sibling tabs do not have.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}
