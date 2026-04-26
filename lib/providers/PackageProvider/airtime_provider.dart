import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import '../../helpers/auth_helpers.dart';
import '../../models/Package/AirtimeModel.dart';

class AirtimeProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  // 🔹 Only status state
  bool _status = false;
  bool get status => _status;

  /// 🔹 Fetch Airtime Packages
  Future<AirtimeModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authGet("/get-package/$categoryId/", context: context);
      final jsonData = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return AirtimeModel.fromJson(jsonData);
      } else {
        return AirtimeModel();
      }
    } on SocketException {
      return AirtimeModel();
    } catch (e) {
      debugPrint("Error getPackage: $e");
      return AirtimeModel();
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  /// 🔹 Buy Airtime
  Future<Map<String, dynamic>> buyAirtime({
    required String packageId,
    required String phone,
    required double amount,
    required String transactionPin,
    required BuildContext context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "phone_number": phone,
      "amount": amount,
      "transaction_pin": transactionPin,
      "channel": "App"
    };

    try {
      final res = await authPost("/purchase-airtime/", body, context: context);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await UserProvider().getUser(); // refresh wallet
        return {"success": true, "message": data['message'] ?? "Airtime purchase successful"};
      } else {
        return {"success": false, "message": data['message'] ?? "Airtime purchase failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      debugPrint("Error buyAirtime: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  /// 🔹 Initiate Airtime Order
  Future<Map<String, dynamic>> initiateOrderAirtime({
    required String subcategoryId,
    required String phone,
    required double amount,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "subcategory_id": subcategoryId,
      "phone_number": phone,
      "amount": amount,
      "channel": "App"
    };

    try {
      final res = await authPost("/initiate-order-airtime/", body, context: context!);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {"success": true, "response": data['data']['trans_ref']};
      } else {
        return {"success": false, "response": data['message'] ?? "Failed to initiate order"};
      }
    } on SocketException {
      return {"success": false, "response": "Internet connection is not available"};
    } catch (e) {
      debugPrint("Error initiateOrderAirtime: $e");
      return {"success": false, "response": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }
}
