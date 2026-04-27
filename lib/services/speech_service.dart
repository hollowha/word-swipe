import 'speech_service_stub.dart'
    if (dart.library.html) 'speech_service_web.dart' as platform;

abstract class SpeechService {
  factory SpeechService() => platform.createSpeechService();

  bool get isSupported;
  void speak(String text);
  void stop();
}
