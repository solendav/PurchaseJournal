import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:purchase_journal/config/routes/route_names.dart';
import 'package:purchase_journal/config/themes/app_colors.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/features/auth/presentation/widgets/auth_shell.dart';
import 'package:purchase_journal/injection_container.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.email});

  final String? email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _checking = true;

  AuthSession get _auth => sl<AuthSession>();

  String get _email =>
      widget.email ?? _auth.pendingEmail ?? _auth.user?.email ?? '';

  @override
  void initState() {
    super.initState();
    _checkAlreadyVerified();
  }

  Future<void> _checkAlreadyVerified() async {
    await _auth.refreshUser();
    if (!mounted) return;
    if (_auth.isAuthenticated) {
      context.go(RouteNames.home);
      return;
    }
    setState(() => _checking = false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _auth.verifyEmail(
      email: _email,
      code: _codeController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      context.go(RouteNames.home);
    }
  }

  Future<void> _resend() async {
    final ok = await _auth.resendVerification(_email);
    if (!mounted) return;
    if (ok) {
      final code = _auth.devCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code != null
                ? 'Code sent to $_email. Dev code: $code'
                : 'Code sent to $_email. Check your spam folder if you do not see it.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return AuthShell(
          title: 'Verify email',
          subtitle: _email.isEmpty
              ? 'Enter the 6-digit code from your email.'
              : 'Enter the 6-digit code sent to $_email.',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_auth.devCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Dev code: ${_auth.devCode}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AuthTextField(
                  controller: _codeController,
                  label: 'Verification code',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.trim().length < 4 ? 'Enter the code' : null,
                ),
                if (_auth.error != null) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(message: _auth.error!),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Verify email',
                  isLoading: _auth.isLoading,
                  onPressed: _auth.isLoading ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _auth.isLoading ? null : _resend,
                  child: const Text('Resend code'),
                ),
                TextButton(
                  onPressed: _auth.isLoading
                      ? null
                      : () async {
                          await _auth.logout();
                          if (context.mounted) context.go(RouteNames.login);
                        },
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
