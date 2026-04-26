import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/models/Package/CableModel.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/helpers/auth_helpers.dart';

class CableProvider extends ChangeNotifier {
  bool _status = false;
  bool _vstatus = false;

  // Getters
  bool get status => _status;
  bool get vstatus => _vstatus;

  /// Get Cable Package
  Future<CableModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);
      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return CableModel();
        return CableModel.fromJson(jsonData);
      } else {
        return CableModel();
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return CableModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Error getPackage: $e");
      return CableModel();
    }
  }

  /// Verify TV Smart Card
  Future<Map<String, dynamic>> verifyTv({
    required String packageId,
    required String smartNo,
    BuildContext? context,
  }) async {
    _vstatus = true;
    notifyListeners();

    try {
      final req = await authGet("/verify-card/$packageId/$smartNo/", context: context);
      _vstatus = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final data = json.decode(req.body)['data']['content'];
        return {
          "success": true,
          "customerName": data['Customer_Name'] ?? '',
          "currentBouquet": data['Current_Bouquet'] ?? '',
          "message": data['error'] ?? 'Verification successful',
        };
      } else {
        final res = json.decode(req.body);
        return {
          "success": false,
          "message": res['message'] ?? 'Verification failed',
        };
      }
    } on SocketException {
      _vstatus = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _vstatus = false;
      notifyListeners();
      debugPrint("Error verifyTv: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  /// Buy Cable TV
  Future<Map<String, dynamic>> buyTv({
    required String packageId,
    required String phone,
    required String variationCode,
    required String smartNo,
    required String planName,
    required String subscriptionType,
    String? amount,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "variation_code": variationCode,
      "smart_no": smartNo,
      "plan_name": planName,
      "phone_number": phone,
      "amount": amount,
      "subscription_type": subscriptionType,
      "transaction_pin": transactionPin,
      "channel": "App",
    };

    try {
      final req = await authPost("/purchase-cable/", body, context: context!);
      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        await UserProvider().getUser(context: context);
        return {"success": true, "message": res['message'] ?? 'Subscription successful'};
      } else {
        final res = json.decode(req.body);
        return {"success": false, "message": res['message'] ?? 'Subscription failed'};
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Error buyTv: $e");
      return {"success": false, "message": "Please try again"};
    }
  }
}
