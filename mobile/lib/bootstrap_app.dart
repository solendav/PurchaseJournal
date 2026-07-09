import 'package:flutter/material.dart';
import 'package:purchase_journal/app.dart';
import 'package:purchase_journal/config/themes/app_theme.dart';
import 'package:purchase_journal/core/constants/app_constants.dart';
import 'package:purchase_journal/core/widgets/splash_page.dart';
import 'package:purchase_journal/injection_container.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    try {
      await init();
    } catch (e) {
      _error = e.toString();
    } finally {
      const minSplash = Duration(milliseconds: 1600);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < minSplash) {
        await Future.delayed(minSplash - elapsed);
      }
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      );
    }

    if (_error != null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: Text('Failed to start: $_error')),
        ),
      );
    }

    return const PurchaseJournalApp();
  }
}
