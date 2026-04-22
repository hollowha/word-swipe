import 'haptics_service_stub.dart'
    if (dart.library.html) 'haptics_service_web.dart' as platform;

abstract class HapticsService {
  factory HapticsService() => platform.createHapticsService();

  void vibrateLight();
}
