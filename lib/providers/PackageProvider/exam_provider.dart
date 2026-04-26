import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:blotpay/models/Package/ExamModel.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/helpers/auth_helpers.dart'; // authGet & authPost

class ExamProvider extends ChangeNotifier {
  bool _status = false;

  // Getter
  bool get status => _status;

  /// Get Exam Packages
  Future<ExamModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return ExamModel();
        return ExamModel.fromJson(jsonData);
      }
      return ExamModel();
    } on SocketException {
      _status = false;
      notifyListeners();
      throw Exception("Internet connection is not available");
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      throw Exception("Please try again");
    }
  }

  /// Verify Exam Profile
  Future<Map<String, dynamic>> verifyExam({
    required String packageId,
    required String profileId,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet(
        "/verify-card/$packageId/$profileId/",
        context: context,
      );

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final data = json.decode(req.body)['data']['content'];
        final result = data['error'] ?? data['Customer_Name'] ?? '';

        if (data['error'] != null) {
          return {"success": false, "message": result};
        }
        return {"success": true, "customerName": result};
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

  /// Buy Exam Pins
  Future<Map<String, dynamic>> buyExam({
    required String packageId,
    required String phone,
    required String variationCode,
    required String serviceId,
    String? profileCode,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "phone_number": phone,
      "variation_code": variationCode,
      "transaction_pin": transactionPin,
      "channel": "App"
    };

    if (profileCode != null) {
      body["profile_code"] = profileCode;
    }

    try {
      final req = await authPost("/purchase-exam-pins/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        await UserProvider().getUser();
        return {"success": true, "message": res['message'] ?? ''};
      } else {
        final res = json.decode(req.body);
        return {"success": false, "message": res['message'] ?? 'Exam Pin Purchase failed!'};
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
