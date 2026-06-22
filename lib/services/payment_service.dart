import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_experience.dart';
import '../constants.dart';

class PaymentResult {
  const PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.used3DSecure = false,
  });

  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final bool used3DSecure;
}

/// Ödeme katmanı — 3D Secure hazır; önizlemede simülasyon.
abstract final class PaymentService {
  static Future<PaymentResult> charge({
    required int amountTL,
    required String reservationRef,
    required String paymentMethod,
    int? installmentMonths,
    String? cardLast4,
    bool skipGateway = false,
  }) async {
    if (!AppExperience.paymentsEnabled || skipGateway) {
      await Future.delayed(const Duration(milliseconds: 600));
      return PaymentResult(
        success: true,
        transactionId: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
        used3DSecure: AppExperience.runPaymentSimulation,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/payments/charge'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amountTL': amountTL,
              'reservationRef': reservationRef,
              'paymentMethod': paymentMethod,
              if (installmentMonths != null) 'installmentMonths': installmentMonths,
              if (cardLast4 != null) 'cardLast4': cardLast4,
              'secure3d': true,
            }),
          )
          .timeout(AppConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return PaymentResult(
            success: true,
            transactionId: data['transactionId']?.toString(),
            used3DSecure: true,
          );
        }
        return PaymentResult(
          success: false,
          errorMessage: data['message']?.toString() ?? 'Ödeme reddedildi',
        );
      }
    } catch (_) {}

    return const PaymentResult(
      success: false,
      errorMessage: 'Ödeme servisine ulaşılamadı. Lütfen tekrar deneyin.',
    );
  }
}
