import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/widgets/auth_shell.dart';
import 'package:purchase_journal/injection_container.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AuthSession get _auth => sl<AuthSession>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final code = await _auth.forgotPassword(email);
    if (!mounted) return;
    if (_auth.error != null && code == null) return;
    context.push(
      RouteNames.resetPassword,
      extra: {'email': email, 'devCode': code},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return AuthShell(
          title: 'Forgot password',
          subtitle: 'We will send a reset code to your email.',
          showBack: true,
          onBack: () => context.pop(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _emailController,
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
                if (_auth.error != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _auth.error!),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Send reset code',
                  isLoading: _auth.isLoading,
                  onPressed: _auth.isLoading ? null : _submit,
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Back to login'),
                ),
                if (_auth.devCode != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Dev code: ${_auth.devCode}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
