import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/app.dart';
import 'package:hisobnoma/core/config/app_config.dart';
import 'package:hisobnoma/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
