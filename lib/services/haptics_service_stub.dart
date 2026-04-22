import 'haptics_service.dart';

HapticsService createHapticsService() => const _NoOpHapticsService();

class _NoOpHapticsService implements HapticsService {
  const _NoOpHapticsService();

  @override
  void vibrateLight() {}
}
