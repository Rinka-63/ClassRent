import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  Future<void> setHasSeen(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasSeenOnboarding', value);
    state = value;
  }
}

final hasSeenOnboardingProvider = NotifierProvider<HasSeenOnboardingNotifier, bool>(() {
  return HasSeenOnboardingNotifier();
});
