import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import '../../helpers/auth_helpers.dart';

class ReferralProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  bool _status = false;
  bool get status => _status;

  /// 🔹 Cash Out Referral Earnings
  Future<Map<String, dynamic>> cashOutReferral({
    required BuildContext context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authPost(
        "/referral-cash-out/",
        {}, // No body required
        context: context,
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await UserProvider().getUser(); // 🔥 Refresh wallet balance

        return {
          "success": true,
          "message": data['message'] ?? "Cash out successful"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Cash out failed"
        };
      }
    } on SocketException {
      return {
        "success": false,
        "message": "Internet connection is not available"
      };
    } catch (e) {
      debugPrint("Error cashOutReferral: $e");
      return {
        "success": false,
        "message": "Please try again"
      };
    } finally {
      _status = false;
      notifyListeners();
    }
  }
}
