import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_model.dart';
import 'package:purchase_journal/features/suppliers/data/models/supplier_statement_model.dart';

class SupplierRemoteDataSource {
  SupplierRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<SupplierModel>> list() async {
    final response = await _api.get(ApiConstants.suppliers);
    final data = response.data as Map<String, dynamic>;
    final suppliers = data['suppliers'] as List<dynamic>? ?? [];
    return suppliers
        .map((e) => SupplierModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SupplierStatementModel> getStatement(String supplierId) async {
    final response = await _api.get('${ApiConstants.suppliers}/$supplierId/statement');
    final data = response.data as Map<String, dynamic>;
    return SupplierStatementModel.fromJson(data);
  }

  Future<SupplierModel> create({required String name, String phone = '', String notes = ''}) async {
    final response = await _api.post(ApiConstants.suppliers, data: {
      'name': name,
      'phone': phone,
      'notes': notes,
    });
    final data = response.data as Map<String, dynamic>;
    return SupplierModel.fromJson(Map<String, dynamic>.from(data['supplier'] as Map));
  }

  Future<SupplierModel> update(
    String id, {
    String? name,
    String? phone,
    String? notes,
  }) async {
    final response = await _api.put('${ApiConstants.suppliers}/$id', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
    });
    final data = response.data as Map<String, dynamic>;
    return SupplierModel.fromJson(Map<String, dynamic>.from(data['supplier'] as Map));
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConstants.suppliers}/$id');
  }
}
