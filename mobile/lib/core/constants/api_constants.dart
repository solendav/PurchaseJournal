import 'package:purchase_journal/core/config/app_env.dart';

class ApiConstants {
  ApiConstants._();

  static String get apiBaseUrl => '${AppEnv.apiBaseUrl}/api';

  static const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';
  static const suppliers = '/suppliers';
  static const purchases = '/purchases';
  static const payments = '/payments';
  static const members = '/members';
  static const dashboardSummary = '/dashboard/summary';
  static const uploadReceipt = '/uploads/receipt';
}
