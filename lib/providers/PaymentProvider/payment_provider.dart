import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/helpers/auth_helpers.dart';

class PaymentProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  bool _status = false;
  String _bankType = "";
  String _monnifyReference = "";

  bool get status => _status;
  String get bankType => _bankType;
  String get monnifyReference => _monnifyReference;

  /// ✅ Make wallet funding payment
  Future<Map<String, dynamic>> makePayment({
    required String amount,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = { "amount": amount };

    try {
      final res = await authPost("/generate-payment-link/", body, context: context!);

      _status = false;
      notifyListeners();

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);

        final checkoutUrl = data['data']['checkoutUrl'] ?? "";
        _monnifyReference = data['data']['transactionReference'] ?? "";

        return {
          "success": true,
          "message": "Payment link generated",
          "checkoutUrl": checkoutUrl,
          "reference": _monnifyReference
        };
      } else {
        final data = json.decode(res.body);
        return {
          "success": false,
          "message": data['message'] ?? "Wallet funding failed!"
        };
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return { "success": false, "message": "Internet connection is not available" };
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("makePayment Error: $e");
      return { "success": false, "message": "Please try again" };
    }
  }
}
