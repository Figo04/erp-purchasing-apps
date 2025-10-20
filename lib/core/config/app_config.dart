// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  static String get appTitle {
    if (isWeb) return 'Supplier Portal';
    if (isMobile) return 'Warehouse Scanner';
    return 'ERP Purchasing';
  }
}