import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/widgets/auth_shell.dart';
import 'package:purchase_journal/injection_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  AuthSession get _auth => sl<AuthSession>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final isBusy = _auth.isLoading;

        return AuthShell(
          title: 'Welcome back',
          subtitle: 'Sign in to manage your purchase journal and supplier accounts.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                if (_auth.error != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _auth.error!),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Sign in',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isBusy ? null : () => context.push(RouteNames.register),
                  child: const Text("Don't have an account? Create one"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
