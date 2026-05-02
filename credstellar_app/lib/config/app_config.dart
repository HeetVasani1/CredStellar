import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment configuration for the CredStellar app.
///
/// DEPLOYMENT:
/// 1. Replace the _productionUrl with your deployed backend URL
/// 2. Set useProduction = true
/// 3. Build the APK: flutter build apk --release
class AppConfig {
  // ── Toggle this to switch between local dev and production ──
  static const bool useProduction = false;

  // ── Your deployed backend URL (Render/Railway/etc.) ──
  // Replace this with your actual deployed URL
  static const String _productionUrl = 'https://credstellar-api.onrender.com/api';

  // ── Local development URLs ──
  static const String _localWebUrl = 'http://localhost:3000/api';
  static const String _localEmulatorUrl = 'http://10.0.2.2:3000/api';

  static String get baseUrl {
    if (useProduction) {
      return _productionUrl;
    }
    // Local dev: auto-detect web vs emulator
    return kIsWeb ? _localWebUrl : _localEmulatorUrl;
  }
}
