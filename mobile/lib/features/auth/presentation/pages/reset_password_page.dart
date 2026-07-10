import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/widgets/auth_shell.dart';
import 'package:purchase_journal/injection_container.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email, this.devCode});

  final String email;
  final String? devCode;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  AuthSession get _auth => sl<AuthSession>();

  @override
  void initState() {
    super.initState();
    if (widget.devCode != null) {
      _codeController.text = widget.devCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.resetPassword(
      email: widget.email,
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return AuthShell(
          title: 'Reset password',
          subtitle: 'Enter the 6-digit code sent to ${widget.email}.',
          showBack: true,
          onBack: () => context.pop(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.devCode != null) ...[
                  Text(
                    'Dev code: ${widget.devCode}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AuthTextField(
                  controller: _codeController,
                  label: 'Reset code',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.trim().length < 4 ? 'Enter the code' : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  label: 'New password',
                  hint: 'At least 8 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
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
                  label: 'Update password',
                  isLoading: _auth.isLoading,
                  onPressed: _auth.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
