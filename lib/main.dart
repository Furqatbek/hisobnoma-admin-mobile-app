import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hisobnoma/app.dart';
import 'package:hisobnoma/core/config/app_config.dart';
import 'package:hisobnoma/core/di/injection.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until auth state is resolved (skip on web)
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Set environment: release builds default to prod, debug to dev.
  // Can be overridden via --dart-define=ENV=prod
  const env = String.fromEnvironment('ENV',
      defaultValue: kReleaseMode ? 'prod' : 'dev');
  AppConfig.current = AppConfig.fromString(env);

  // Safety: warn in debug if accidentally pointing to prod
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
}
