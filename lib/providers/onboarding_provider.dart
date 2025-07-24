import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Onboarding state provider
class OnboardingNotifier extends AsyncNotifier<bool> {
  static const String _onboardingKey = 'has_completed_onboarding';

  @override
  Future<bool> build() async {
    return await _getOnboardingStatus();
  }

  Future<bool> _getOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      state = const AsyncValue.data(true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, false);
      state = const AsyncValue.data(false);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Provider instance
final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  () => OnboardingNotifier(),
);

// Convenience provider to check if onboarding is completed
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final onboardingState = ref.watch(onboardingProvider);
  return onboardingState.asData?.value ?? false;
});
