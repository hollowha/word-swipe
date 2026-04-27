import 'speech_service.dart';

SpeechService createSpeechService() => const _NoOpSpeechService();

class _NoOpSpeechService implements SpeechService {
  const _NoOpSpeechService();

  @override
  bool get isSupported => false;

  @override
  void speak(String text) {}

  @override
  void stop() {}
}
