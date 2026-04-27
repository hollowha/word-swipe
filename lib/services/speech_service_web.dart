// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'speech_service.dart';

SpeechService createSpeechService() => const _WebSpeechService();

class _WebSpeechService implements SpeechService {
  const _WebSpeechService();

  @override
  bool get isSupported => html.window.speechSynthesis != null;

  @override
  void speak(String text) {
    if (text.trim().isEmpty || !isSupported) return;
    html.window.speechSynthesis?.cancel();
    final utterance = html.SpeechSynthesisUtterance(text.trim())
      ..lang = 'en-US'
      ..rate = 0.9;
    html.window.speechSynthesis?.speak(utterance);
  }

  @override
  void stop() {
    html.window.speechSynthesis?.cancel();
  }
}
