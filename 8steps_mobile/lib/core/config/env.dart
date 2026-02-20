import 'package:flutter/foundation.dart';

import 'platform_info.dart';

class Env {
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (isAndroidPlatform) return 'http://10.0.2.2:3000/api/v1';
    if (isIosPlatform) return 'http://localhost:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }
}
