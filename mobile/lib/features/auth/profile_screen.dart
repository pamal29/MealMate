import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_screen.dart';
import 'student_profile_view.dart';
import '../ordering/student_orders_screen.dart';
import '../home/home_style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onOrders});
  final VoidCallback? onOrders;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _profile = AuthService.profile();
  }

  void _logout() {
    AuthService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error is AuthException
                    ? error.message
                    : 'Unable to load your profile.',
              ),
              const SizedBox(height: 16),
              if (AuthService.token != null)
                TextButton(
                  onPressed: () =>
                      setState(() => _profile = AuthService.profile()),
                  child: const Text('Retry'),
                ),
              FilledButton(
                onPressed: _logout,
                child: Text(AuthService.token == null ? 'Sign in' : 'Log out'),
              ),
            ],
          );
        }
        final user = snapshot.data!;
        return StudentProfileView(
          user: user,
          onLogout: _logout,
          onOrders:
              widget.onOrders ??
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Theme(
                    data: HomeStyle.theme,
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Orders')),
                      body: const StudentOrdersScreen(),
                    ),
                  ),
                ),
              ),
        );
      },
    ),
  );
}
