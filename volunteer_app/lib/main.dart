import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:volunteer_app/core/constants/api_constants.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/repositories/auth_repository.dart';
import 'package:volunteer_app/data/repositories/task_repository.dart';
import 'package:volunteer_app/data/services/api_service.dart';
import 'package:volunteer_app/ui/splash_gate.dart';
import 'package:volunteer_app/ui/view_models/admin_task_view_model.dart';
import 'package:volunteer_app/ui/view_models/auth_view_model.dart';
import 'package:volunteer_app/ui/view_models/task_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Constants and preferences
  await ApiConstants.init();

  // Initialize API Service
  final apiService = ApiService();
  await apiService.init();

  // Initialize Repositories
  final authRepository = AuthRepository(apiService);
  final taskRepository = TaskRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
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
