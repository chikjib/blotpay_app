import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/models/Package/BulkSmsModel.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/helpers/auth_helpers.dart'; // import authGet/authPost

class BulkSmsProvider extends ChangeNotifier {
  bool _status = false;

  // Getter
  bool get status => _status;

  /// Get Bulk SMS Package
  Future<BulkSmsModel> getPackage(int categoryId, {BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final req = await authGet("/get-package/$categoryId/", context: context);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final jsonData = json.decode(req.body);
        if (jsonData == null) return BulkSmsModel();
        return BulkSmsModel.fromJson(jsonData);
      }
      return BulkSmsModel();
    } on SocketException {
      _status = false;
      notifyListeners();
      return BulkSmsModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return BulkSmsModel();
    }
  }

  /// Send Bulk SMS
  Future<Map<String, dynamic>> sendSms({
    required String packageId,
    required String recipients,
    required String senderName,
    required String message,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "package_id": packageId,
      "sender_name": senderName,
      "recipients": recipients,
      "message": message,
      "transaction_pin": transactionPin,
      "channel": "App",
    };

    try {
      final req = await authPost("/send-sms/", body, context: context!);

      _status = false;
      notifyListeners();

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        await UserProvider().getUser();
        return { "success": true, "message": res['message'] ?? "Message sent successfully" };
      } else {
        final res = json.decode(req.body);
        return { "success": false, "message": res['message'] ?? "Message sending failed!" };
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return { "success": false, "message": "Internet connection is not available" };
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return { "success": false, "message": "Please try again" };
    }
  }
}
