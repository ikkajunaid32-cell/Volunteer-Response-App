import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/repositories/auth_repository.dart';
import 'package:volunteer_app/data/repositories/task_repository.dart';
import 'package:volunteer_app/data/services/app_database.dart';
import 'package:volunteer_app/ui/splash_gate.dart';
import 'package:volunteer_app/ui/view_models/admin_task_view_model.dart';
import 'package:volunteer_app/ui/view_models/auth_view_model.dart';
import 'package:volunteer_app/ui/view_models/task_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database directly on the device
  await AppDatabase.instance.database;

  // Initialize Repositories
  final authRepository = AuthRepository();
  final taskRepository = TaskRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<TaskRepository>.value(value: taskRepository),
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider<TaskViewModel>(
          create: (_) => TaskViewModel(taskRepository),
        ),
        ChangeNotifierProvider<AdminTaskViewModel>(
          create: (_) => AdminTaskViewModel(taskRepository),
        ),
      ],
      child: const VolunteerApp(),
    ),
  );
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer Response',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashGate(),
    );
  }
}
