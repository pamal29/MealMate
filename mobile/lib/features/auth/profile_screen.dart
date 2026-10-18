import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
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
    padding: const EdgeInsets.all(24),
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
        return ListView(
          children: [
            const Icon(Icons.account_circle_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              user['name'] as String? ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(user['email'] as String? ?? ''),
            ),
            ListTile(
              title: const Text('Account type'),
              subtitle: Text(
                user['role'] == 'shop_owner' ? 'Shop owner' : 'Student',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _logout, child: const Text('Log out')),
          ],
        );
      },
    ),
  );
}
