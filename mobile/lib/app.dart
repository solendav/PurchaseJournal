import 'package:flutter/material.dart';
import 'package:purchase_journal/config/routes/app_router.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/injection_container.dart';

class PurchaseJournalApp extends StatelessWidget {
  const PurchaseJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authSession = sl<AuthSession>();
    final router = createAppRouter(authSession);

    return ListenableBuilder(
      listenable: authSession,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Purchase Journal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}
