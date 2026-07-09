import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchase_journal/core/auth/auth_session.dart';
import 'package:purchase_journal/core/network/api_client.dart';
import 'package:purchase_journal/core/network/token_storage.dart';
import 'package:purchase_journal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:purchase_journal/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:purchase_journal/features/purchases/data/datasources/purchase_remote_datasource.dart';
import 'package:purchase_journal/features/profile/data/member_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/payment_remote_datasource.dart';
import 'package:purchase_journal/features/suppliers/data/datasources/supplier_remote_datasource.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton(() => SupplierRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PaymentRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PurchaseRemoteDataSource(sl()));
  sl.registerLazySingleton(() => DashboardRemoteDataSource(sl()));
  sl.registerLazySingleton(() => MemberRemoteDataSource(sl()));
  sl.registerLazySingleton(() => AuthSession(sl(), sl()));
  await sl<AuthSession>().bootstrap();
}
