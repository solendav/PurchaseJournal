import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';
import 'package:purchase_journal/features/purchases/data/models/purchase_model.dart';

class PurchaseRemoteDataSource {
  PurchaseRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<PurchaseModel>> list({String? supplierId}) async {
    final response = await _api.get(
      ApiConstants.purchases,
      queryParameters: supplierId == null ? null : {'supplierId': supplierId},
    );
    final data = response.data as Map<String, dynamic>;
    final purchases = data['purchases'] as List<dynamic>? ?? [];
    return purchases
        .map((e) => PurchaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PurchaseModel> getById(String id) async {
    final response = await _api.get('${ApiConstants.purchases}/$id');
    final data = response.data as Map<String, dynamic>;
    return PurchaseModel.fromJson(Map<String, dynamic>.from(data['purchase'] as Map));
  }

  Future<PurchaseModel> create(Map<String, dynamic> body) async {
    final response = await _api.post(ApiConstants.purchases, data: body);
    final data = response.data as Map<String, dynamic>;
    return PurchaseModel.fromJson(Map<String, dynamic>.from(data['purchase'] as Map));
  }

  Future<PurchaseModel> update(String id, Map<String, dynamic> body) async {
    final response = await _api.put('${ApiConstants.purchases}/$id', data: body);
    final data = response.data as Map<String, dynamic>;
    return PurchaseModel.fromJson(Map<String, dynamic>.from(data['purchase'] as Map));
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConstants.purchases}/$id');
  }

  Future<String> uploadReceipt(String filePath) async {
    final formData = FormData.fromMap({
      'receipt': await MultipartFile.fromFile(filePath),
    });
    return _uploadReceiptFormData(formData);
  }

  Future<String> uploadReceiptFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'receipt': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'receipt.jpg',
      ),
    });
    return _uploadReceiptFormData(formData);
  }

  Future<String> _uploadReceiptFormData(FormData formData) async {
    final response = await _api.postMultipart(ApiConstants.uploadReceipt, formData);
    final data = response.data as Map<String, dynamic>;
    return data['path'] as String? ?? '';
  }
}
