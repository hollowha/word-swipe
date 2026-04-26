// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'haptics_service.dart';

HapticsService createHapticsService() => const _WebHapticsService();

class _WebHapticsService implements HapticsService {
  const _WebHapticsService();

  @override
  void vibrateLight() => _vibrate([10]);

  @override
  void success() => _vibrate([12]);

  @override
  void newWord() => _vibrate([18]);

  @override
  void combo() => _vibrate([10, 35, 18]);

  @override
  void levelUp() => _vibrate([20, 40, 30, 40, 45]);

  @override
  void questComplete() => _vibrate([15, 35, 25]);

  void _vibrate(List<int> pattern) {
    try {
      js_util.callMethod(html.window.navigator, 'vibrate', [pattern]);
    } catch (_) {
      // Browsers that do not support vibration should silently no-op.
    }
  }
}
