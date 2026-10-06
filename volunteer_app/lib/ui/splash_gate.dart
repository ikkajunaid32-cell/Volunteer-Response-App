import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/ui/view_models/auth_view_model.dart';
import 'package:volunteer_app/ui/views/admin/admin_dashboard_view.dart';
import 'package:volunteer_app/ui/views/auth/login_view.dart';
import 'package:volunteer_app/ui/views/volunteer/volunteer_dashboard_view.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isLoading && authVm.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to Volunteer Response...'),
            ],
          ),
        ),
      );
    }

    if (!authVm.isAuthenticated) {
      return const LoginView();
    }

    if (authVm.isAdmin) {
      return const AdminDashboardView();
    }

    return const VolunteerDashboardView();
  }
}
