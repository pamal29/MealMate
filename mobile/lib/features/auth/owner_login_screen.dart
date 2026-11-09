import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../home/home_style.dart';
import '../owner/owner_dashboard_screen.dart';
import 'auth_service.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key, this.onLogin = AuthService.login});
  final Future<void> Function(String, String) onLogin;
  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false, _hidden = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _info(String title, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  Future<void> _login() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onLogin(_email.text.trim(), _password.text);
      if (AuthService.user?['role'] != 'shop_owner') {
        AuthService.logout();
        throw const AuthException(
          'Use a shop-owner account here. Students can return to Student Login.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const OwnerDashboardScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AuthException
              ? e.message
              : 'Could not connect. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HomeStyle.border),
        ),
        labelStyle: const TextStyle(fontSize: 12, color: HomeStyle.muted),
      ),
    ),
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              children: [
                const Text(
                  'Sabaragamuwa University of Sri Lanka',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: HomeStyle.muted),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: HomeStyle.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SvgPicture.asset(
                      'assets/login/utensils.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'MealMate  SUSL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                const Text(
                  'FOR SHOP OWNERS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: HomeStyle.orange),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Shop Owner Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your shop, ready for the campus rush.\nSign in to your business dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HomeStyle.muted, height: 1.6),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: HomeStyle.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HomeStyle.border),
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your shop email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (v) =>
                              v != null &&
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(v.trim())
                              ? null
                              : 'Enter a valid email address.',
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _info(
                              'Password recovery',
                              'Password recovery is not connected yet. Contact your shop administrator.',
                            ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _hidden,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: 'Toggle password visibility',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter your password.'
                              : null,
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _login,
                          child: Text(_busy ? 'Signing in...' : '→ Login'),
                        ),
                        const Divider(height: 36, color: HomeStyle.border),
                        const Text(
                          'Secure access for registered shop owners',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: HomeStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextButton(
                  onPressed: () => _info(
                    'Shop access',
                    'Ask your MealMate project administrator to arrange shop-owner access. A contact address has not been configured.',
                  ),
                  child: const Text('Need access for your shop? Contact us'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← Back to Student Login'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const OwnerDashboardScreen(isPreview: true),
                          ),
                        ),
                  child: const Text('Preview shop-owner dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
