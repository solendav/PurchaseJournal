import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/widgets/auth_shell.dart';
import 'package:purchase_journal/injection_container.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  AuthSession get _auth => sl<AuthSession>();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _auth.register(
      email: _email.text.trim(),
      password: _password.text,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.go(
        _auth.needsEmailVerification ? RouteNames.verifyEmail : RouteNames.home,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final isBusy = _auth.isLoading;

        return AuthShell(
          title: 'Create account',
          subtitle: 'Start tracking purchases, suppliers, and payments in one place.',
          showBack: true,
          onBack: () => context.pop(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: _firstName,
                        label: 'First name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _lastName,
                        label: 'Last name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                  hint: 'At least 8 characters',
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
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                if (_auth.error != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _auth.error!),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Create account',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isBusy ? null : () => context.pop(),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
