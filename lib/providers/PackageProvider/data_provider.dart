import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/models/Package/DataModel.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/helpers/auth_helpers.dart';

class DataProvider extends ChangeNotifier {
  bool _status = false;
  bool get status => _status;

  /// Get Data Package
  Future<DataModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);
      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return DataModel();
        return DataModel.fromJson(jsonData);
      } else {
        return DataModel();
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return DataModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Error getPackage: $e");
      return DataModel();
    }
  }

  /// Buy Data
  Future<Map<String, dynamic>> buyData({
    required String packageId,
    required String variationCode,
    required String phone,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "variation_code": variationCode,
      "phone_number": phone,
      "transaction_pin": transactionPin,
      "channel": "App"
    };

    try {
      final req = await authPost("/purchase-data/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        await UserProvider().getUser(context: context);
        return {"success": true, "message": res['message'] ?? "Data Purchase Successful"};
      } else {
        final res = json.decode(req.body);
        return {"success": false, "message": res['message'] ?? "Data Purchase Failed"};
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Error buyData: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  /// Initiate Order Data
  Future<Map<String, String>> initiateOrderData({
    required String size,
    required String title,
    required String subcategoryId,
    required String phone,
    required double amount,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "size": size,
      "title": title,
      "subcategory_id": subcategoryId,
      "phone_number": phone,
      "amount": amount,
      "channel": "App"
    };

    try {
      final req = await authPost("/initiate-order-data/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        return {"status": "success", "response": res['data']['trans_ref'] ?? ""};
      } else {
        final res = json.decode(req.body);
        return {"status": "failed", "response": res['message'] ?? "Failed to initiate order"};
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"status": "failed", "response": "Internet connection is not available"};
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Error initiateOrderData: $e");
      return {"status": "failed", "response": "Please try again"};
    }
  }
}
