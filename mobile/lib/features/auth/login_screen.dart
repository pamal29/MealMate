import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../home/home_screen.dart';
import '../owner/owner_dashboard_screen.dart';
import 'auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLogin = AuthService.login});

  final Future<void> Function(String email, String password) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _background = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF181818);
  static const _border = Color(0xFF262626);
  static const _muted = Color(0xFFA3A3A3);
  static const _orange = Color(0xFFF97316);
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onLogin(_email.text.trim(), _password.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AuthService.user?['role'] == 'shop_owner'
              ? const OwnerDashboardScreen()
              : const HomeScreen(),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not connect. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _unavailable(String feature) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: Text(feature, style: const TextStyle(color: Colors.white)),
        content: const Text(
          'This feature is not available yet. Please use your existing email and password to sign in.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _orange)),
          ),
        ],
      ),
    );
  }

  Widget _asset(String name, double width, double height) => SvgPicture.asset(
    'assets/login/$name.svg',
    width: width,
    height: height,
    excludeFromSemantics: true,
  );

  TextStyle _text(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    height: 1.34,
    color: color,
    fontWeight: weight,
  );

  BoxDecoration _box(double radius) => BoxDecoration(
    color: _surface,
    border: Border.all(color: _border),
    borderRadius: BorderRadius.circular(radius),
  );

  Widget _link(String label, VoidCallback action, {Color color = _orange}) =>
      TextButton(
        onPressed: _loading ? null : action,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: color,
        ),
        child: Text(label, style: _text(12, color: color)),
      );

  Widget _header() => Column(
    children: [
      const SizedBox(height: 16),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: _box(999),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _asset('university', 13.75, 11.25),
              const SizedBox(width: 6),
              Text(
                'Sabaragamuwa University of Sri Lanka',
                style: _text(
                  12,
                  color: _muted,
                  weight: FontWeight.w500,
                ).copyWith(letterSpacing: -.3),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 44),
      SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: _box(16),
              alignment: Alignment.center,
              child: _asset('utensils', 32, 32),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: _background, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'MealMate',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 18,
              height: 28 / 18,
              letterSpacing: -.45,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x26F97316),
              border: Border.all(color: const Color(0x4DF97316)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SUSL',
              style: _text(
                10,
                color: _orange,
                weight: FontWeight.w600,
              ).copyWith(letterSpacing: .5),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        'Welcome back',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 24,
          height: 32 / 24,
          letterSpacing: -.6,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Order your favourite campus food\nwithout the queue.',
        textAlign: TextAlign.center,
        style: _text(14, color: _muted).copyWith(height: 22.75 / 14),
      ),
      const SizedBox(height: 32),
    ],
  );

  InputDecoration _input(String label, {Widget? suffix}) => InputDecoration(
    semanticCounterText: label,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _orange),
    ),
    errorMaxLines: 2,
    errorStyle: _text(12, color: const Color(0xFFFCA5A5)),
  );

  Widget _card() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _box(16).copyWith(
      boxShadow: [
        const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 50,
          offset: Offset(0, 25),
          spreadRadius: -12,
        ),
      ],
    ),
    child: AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email Address',
              style: _text(12, color: _muted, weight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Semantics(
              label: 'Email Address',
              child: TextFormField(
                controller: _email,
                enabled: !_loading,
                style: _text(14),
                cursorColor: _orange,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                decoration: _input('Email Address'),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value.trim())
                    ? 'Enter a valid email address.'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Password',
                  style: _text(12, color: _muted, weight: FontWeight.w500),
                ),
                _link(
                  'Forgot password?',
                  () => _unavailable('Password recovery'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: 'Password',
              child: TextFormField(
                controller: _password,
                enabled: !_loading,
                obscureText: _hidden,
                style: _text(14),
                cursorColor: _orange,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _input(
                  'Password',
                  suffix: IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: _asset('visibility', 16.5, 11.25),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : null,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: _text(12, color: const Color(0xFFFCA5A5)),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x33F97316),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _orange.withValues(alpha: .6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: _text(14, weight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            _asset('arrow', 12, 12),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider(color: _border, height: 16)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: _text(12, color: _muted)),
                ),
                const Expanded(child: Divider(color: _border, height: 16)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(isPreview: true),
                      ),
                    ),
              child: const Text('Explore preview — no login needed'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _unavailable('Student Google sign-in'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _asset('google', 16, 16),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Continue with Student Google',
                      textAlign: TextAlign.center,
                      style: _text(14, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: Column(
      children: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OwnerDashboardScreen(isPreview: true),
                  ),
                ),
          child: const Text('Preview shop-owner dashboard'),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("Don't have an account? ", style: _text(12, color: _muted)),
            _link(
              'Register',
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: _box(999),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              _asset('shop', 12.559, 11.25),
              Text('Are you a canteen owner?', style: _text(12, color: _muted)),
              _link(
                'Shop Login',
                () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Shop owner login'),
                    content: const Text(
                      'Use your shop owner email and password in the login form above.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: _background,
      systemNavigationBarColor: _background,
    ),
    child: Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: _orange,
          surface: _surface,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 342,
                    minHeight: (constraints.maxHeight - 64)
                        .clamp(0, double.infinity)
                        .toDouble(),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [_header(), _card()],
                      ),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
