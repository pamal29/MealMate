import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import 'auth_service.dart';
import '../home/home_style.dart';

import 'package:flutter_svg/flutter_svg.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onRegister = AuthService.register});
  final Future<void> Function(
    String name,
    String email,
    String password, {
    String role,
    String? phone,
  }) onRegister;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  bool _hidden = true, _confirmHidden = true, _agreed = false;
  String _role = 'student';
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  
Future<void> _submit() async {
  if (_loading || !_form.currentState!.validate()) return;

  if (!_agreed) {
    setState(() {
      _error = 'Please accept the terms before continuing.';
    });
    return;
  }

  FocusScope.of(context).unfocus();

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    await AuthService.register(
      _name.text.trim(),
      _email.text.trim(),
      _password.text,
      role: _role,
      phone: _phone.text.trim().isNotEmpty 
        ? null
        : _phone.text.trim(),
    );


    if (!mounted) return;

    final role = AuthService.user?['role'];

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => role == 'shop_owner'
            ? const OwnerDashboardScreen()
            : const HomeScreen(),
      ),
      (_) => false,
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    setState(() => _error = e.message);
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _error = 'Could not connect. Please try again.';
    });
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) => Theme(
    data: HomeStyle.theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HomeStyle.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
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
      appBar: AppBar(toolbarHeight: 40, backgroundColor: HomeStyle.background),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sabaragamuwa University of Sri Lanka',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HomeStyle.muted, fontSize: 10),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SvgPicture.asset(
                      'assets/login/utensils.svg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MealMate  SUSL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Join MealMate',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your campus favourites, without the queue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: HomeStyle.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HomeStyle.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          enabled: !_loading,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          enabled: !_loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) =>
                              v == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(v.trim())
                              ? 'Enter a valid email address.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          enabled: !_loading,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number (optional)',
                            helperText: 'Kept for this session only',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_loading,
                          obscureText: _hidden,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: 'Show password',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Use at least 6 characters.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (_password.text.isNotEmpty) ...[
                          LinearProgressIndicator(
                            value: (_password.text.length / 12).clamp(0, 1),
                            color: _password.text.length >= 12
                                ? HomeStyle.green
                                : HomeStyle.orange,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Password length: ${_password.text.length} characters',
                            style: const TextStyle(
                              fontSize: 10,
                              color: HomeStyle.muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _confirm,
                          enabled: !_loading,
                          obscureText: _confirmHidden,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            suffixIcon: IconButton(
                              tooltip: 'Show confirm password',
                              onPressed: () => setState(
                                () => _confirmHidden = !_confirmHidden,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          ),
                          validator: (v) => v != _password.text
                              ? 'Passwords do not match.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'Account type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'student',
                              child: Text('Student'),
                            ),
                            DropdownMenuItem(
                              value: 'shop_owner',
                              child: Text('Shop owner'),
                            ),
                          ],
                          onChanged: _loading
                              ? null
                              : (v) => setState(() => _role = v!),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _agreed,
                            onChanged: _loading
                                ? null
                                : (v) => setState(() => _agreed = v!),
                            title: const Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Terms and Privacy'),
                              content: const Text(
                                'Preview only: final policy documents have not been supplied. Do not submit real personal information until the service policies are available.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text(
                            'Read terms and privacy',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create account'),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
