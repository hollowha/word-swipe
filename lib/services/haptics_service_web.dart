// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'haptics_service.dart';

HapticsService createHapticsService() => const _WebHapticsService();

class _WebHapticsService implements HapticsService {
  const _WebHapticsService();

  @override
  void vibrateLight() {
    try {
      js_util.callMethod(html.window.navigator, 'vibrate', [10]);
    } catch (_) {
      // Browsers that do not support vibration should silently no-op.
    }
  }
}
