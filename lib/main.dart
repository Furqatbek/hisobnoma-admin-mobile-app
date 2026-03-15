import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/app.dart';
import 'package:hisobnoma/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection
  await configureDependencies();

  runApp(const HisobnomaApp());
}
