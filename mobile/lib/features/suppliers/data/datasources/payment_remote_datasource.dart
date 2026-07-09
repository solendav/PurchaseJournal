import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';
import 'package:purchase_journal/features/purchases/data/models/payment_model.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<PaymentModel>> list({String? supplierId}) async {
    final response = await _api.get(
      ApiConstants.payments,
      queryParameters: supplierId == null ? null : {'supplierId': supplierId},
    );
    final data = response.data as Map<String, dynamic>;
    final payments = data['payments'] as List<dynamic>? ?? [];
    return payments
        .map((e) => PaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PaymentModel> getById(String id) async {
    final response = await _api.get('${ApiConstants.payments}/$id');
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(Map<String, dynamic>.from(data['payment'] as Map));
  }

  Future<PaymentModel> create({
    required String supplierId,
    required double amount,
    required String paymentDate,
    String notes = '',
    String? purchaseId,
  }) async {
    final response = await _api.post(ApiConstants.payments, data: {
      'supplierId': supplierId,
      'amount': amount,
      'paymentDate': paymentDate,
      'notes': notes,
      if (purchaseId != null) 'purchaseId': purchaseId,
    });
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(Map<String, dynamic>.from(data['payment'] as Map));
  }

  Future<PaymentModel> update(
    String id, {
    required double amount,
    required String paymentDate,
    String notes = '',
  }) async {
    final response = await _api.put('${ApiConstants.payments}/$id', data: {
      'amount': amount,
      'paymentDate': paymentDate,
      'notes': notes,
    });
    final data = response.data as Map<String, dynamic>;
    return PaymentModel.fromJson(Map<String, dynamic>.from(data['payment'] as Map));
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConstants.payments}/$id');
  }
}
