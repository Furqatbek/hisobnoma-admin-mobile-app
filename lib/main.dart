import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hisobnoma/app.dart';
import 'package:hisobnoma/core/config/app_config.dart';
import 'package:hisobnoma/core/di/injection.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until auth state is resolved
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set environment (override via --dart-define=ENV=prod)
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.current = AppConfig.fromString(env);

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection
  await configureDependencies();

  runApp(const HisobnomaApp());
}
