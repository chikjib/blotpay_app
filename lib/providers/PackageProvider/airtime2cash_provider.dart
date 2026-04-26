import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/helpers/auth_helpers.dart';
import 'package:blotpay/models/Package/Airtime2CashModel.dart';

class Airtime2CashProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  // State
  bool _status = false;
  bool get status => _status;

  /// Fetch available Airtime2Cash packages
  Future<Airtime2CashModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return Airtime2CashModel();
        return Airtime2CashModel.fromJson(jsonData);
      } else {
        return Airtime2CashModel();
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return Airtime2CashModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      print("getPackage Error: $e");
      return Airtime2CashModel();
    }
  }

  /// Convert Airtime to Cash
  Future<Map<String, dynamic>> convertAtc({
    required String packageId,
    required String phoneNumber,
    required double amountTransferred,
    required double amountToReceive,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "phone_number": phoneNumber,
      "amount_transferred": amountTransferred,
      "amount_to_receive": amountToReceive,
      "channel": "App",
    };

    try {
      final req = await authPost("/convert-airtime-to-cash/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        return { "success": true, "message": res['message'] ?? "Airtime converted successfully" };
      } else {
        final res = json.decode(req.body);
        return { "success": false, "message": res['message'] ?? "Conversion failed" };
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return { "success": false, "message": "Internet connection is not available" };
    } catch (e) {
      _status = false;
      notifyListeners();
      print("convertAtc Error: $e");
      return { "success": false, "message": "Please try again" };
    }
  }
}
