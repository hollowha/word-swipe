import 'haptics_service.dart';

HapticsService createHapticsService() => const _NoOpHapticsService();

class _NoOpHapticsService implements HapticsService {
  const _NoOpHapticsService();

  @override
  void vibrateLight() {}

  @override
  void success() {}

  @override
  void newWord() {}

  @override
  void combo() {}

  @override
  void levelUp() {}

  @override
  void questComplete() {}
}
