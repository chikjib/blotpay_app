import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/models/Package/ElectricityModel.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/helpers/auth_helpers.dart';

class ElectricityProvider extends ChangeNotifier {
  bool _status = false;

  // Getter
  bool get status => _status;

  /// Get Electricity Packages
  Future<ElectricityModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return ElectricityModel();
        return ElectricityModel.fromJson(jsonData);
      }
      return ElectricityModel();
    } on SocketException {
      _status = false;
      notifyListeners();
      return ElectricityModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return ElectricityModel();
    }
  }

  /// Verify Electricity Meter
  Future<Map<String, dynamic>> verifyElectricity({
    required String packageId,
    required String meterNo,
    required String meterType,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet(
        "/verify-meter-number/$packageId/$meterNo/$meterType/",
        context: context,
      );

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final data = json.decode(req.body)['data']['content'];
        return {
          "success": true,
          "customerName": data['Customer_Name'] ?? '',
          "message": data['error'] ?? '',
        };
      }
      return {"success": false, "message": "Verification failed"};
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  /// Buy Electricity
  Future<Map<String, dynamic>> buyElectricity({
    required String packageId,
    required String serviceId,
    required String variationCode,
    required String meterNo,
    required double amount,
    required String phone,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "service_id": serviceId,
      "variation_code": variationCode,
      "meter_no": meterNo,
      "amount": amount,
      "phone_number": phone,
      "transaction_pin": transactionPin,
      "channel": "App"
    };

    try {
      final req = await authPost("/purchase-electricity/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        await UserProvider().getUser();
        return {"success": true, "message": res['message'] ?? 'Bill Payment successful'};
      } else {
        final res = json.decode(req.body);
        return {"success": false, "message": res['message'] ?? 'Bill Payment failed'};
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    }
  }
}
