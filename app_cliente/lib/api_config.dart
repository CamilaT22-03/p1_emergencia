import 'package:flutter/foundation.dart';

class ApiConfig {
  // Cambiar a 'true' para usar localhost (desarrollo local)
  // Cambiar a 'false' para usar Render (producción)
  static const bool useLocalhost = true;
  
  static const String renderUrl = 'https://p1-emergencia.onrender.com';
  static const String localhostUrl = 'http://localhost:8000';
  
  static String get baseUrl {
    if (useLocalhost) {
      if (kIsWeb) {
        return localhostUrl;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'http://10.0.2.2:8000';
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return localhostUrl;
      }
    } else {
      // Usar Render en producción
      return renderUrl;
    }
  }
}
