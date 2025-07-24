import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/splash/animated_splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/journal/journal_detail_screen.dart';
import '../screens/journal/create_entry_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

// Routes
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/';
  static const String createEntry = '/create-entry';
  static const String journalDetail = '/journal/:id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ValueNotifier<bool>(false);
  final hasCompletedOnboarding = ValueNotifier<bool>(false);

  ref.listen(isAuthenticatedProvider, (previous, next) {
    isAuthenticated.value = next;
  }, fireImmediately: true);

  ref.listen(hasCompletedOnboardingProvider, (previous, next) {
    hasCompletedOnboarding.value = next;
  }, fireImmediately: true);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge([
      isAuthenticated,
      hasCompletedOnboarding,
    ]),
    redirect: (context, state) {
      final isAuth = isAuthenticated.value;
      final hasOnboarded = hasCompletedOnboarding.value;
      final currentPath = state.fullPath;

      // Always allow splash screen initially
      if (currentPath == AppRoutes.splash) {
        return null;
      }

      // If not onboarded and not going to onboarding, redirect to onboarding
      if (!hasOnboarded && currentPath != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      // If onboarded but not authenticated and not going to auth, redirect to auth
      if (hasOnboarded && !isAuth && currentPath != AppRoutes.auth) {
        return AppRoutes.auth;
      }

      // If authenticated and going to auth/onboarding, redirect to home
      if (isAuth &&
          (currentPath == AppRoutes.auth ||
              currentPath == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const AnimatedSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
        routes: [
          GoRoute(
            path: 'create-entry',
            name: 'create-entry',
            builder: (context, state) => const CreateEntryScreen(),
          ),
          GoRoute(
            path: 'journal/:id',
            name: 'journal-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return JournalDetailScreen(entryId: id);
            },
          ),
        ],
      ),
    ],
  );
});
