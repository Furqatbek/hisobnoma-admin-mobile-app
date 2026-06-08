import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hisobnoma/app.dart';
import 'package:hisobnoma/core/config/app_config.dart';
import 'package:hisobnoma/core/di/injection.dart';

void main() async {
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    // Preserve native splash until auth state is resolved (skip on web)
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      } catch (_) {}
    }

    // Set environment: release builds default to prod, debug to dev.
    const env = String.fromEnvironment('ENV',
        defaultValue: kReleaseMode ? 'prod' : 'dev');
    AppConfig.current = AppConfig.fromString(env);

    if (kDebugMode && AppConfig.current.isProd) {
      debugPrint('⚠️ WARNING: Running in DEBUG mode with PRODUCTION API');
    }

    // Lock to portrait orientation (skip on web)
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Initialize dependency injection
    await configureDependencies();

    runApp(const HisobnomaApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('$stackTrace');
  });
}
