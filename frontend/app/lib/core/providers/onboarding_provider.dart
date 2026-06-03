import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingCompletedKey = 'onboarding_completed';

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

final onboardingBootstrapProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool(_onboardingCompletedKey) ?? false;
  ref.read(onboardingCompletedProvider.notifier).state = completed;
  return completed;
});

final markOnboardingCompleteProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingCompletedKey, true);
  ref.read(onboardingCompletedProvider.notifier).state = true;
});
