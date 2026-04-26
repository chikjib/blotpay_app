import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/providers/Database/db_provider.dart';

import '../../helpers/auth_helpers.dart';

class UserProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  // Single state
  bool _status = false;
  bool get status => _status;

  String _bankType = "";
  String get bankType => _bankType;

  // ---------------- GET USER ----------------
  Future<UserModel> getUser({BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authGet("/get-user/", context: context);
      _status = false;
      notifyListeners();

      if (res.statusCode == 200 || res.statusCode == 201) {
        final jsonData = json.decode(res.body);
        if (jsonData == null) return UserModel();

        final userModel = UserModel.fromJson(jsonData);
        await DatabaseProvider().saveUserDetails(json.encode(jsonData));
        return userModel;
      } else {
        return UserModel();
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return UserModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      print("::: $e");
      return UserModel();
    }
  }

  // ---------------- UPGRADE USER ----------------
  Future<Map<String, dynamic>> upgradeUser({
    required String userLevel,
    required String amount,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {"level": userLevel, "amount": amount, "channel": "App"};

    try {
      final res = await authPut("/upgrade-user/", body, context: context);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": data['message'] ?? "Account upgraded successfully"};
      } else {
        return {"success": false, "message": data['message'] ?? "Account upgrade failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- CHANGE PASSWORD ----------------
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {"old_password": oldPassword, "password": newPassword, "password2": confirmPassword};

    try {
      final res = await authPut("/change-password/", body, context: context);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Password Changed Successfully"};
      } else {
        return {"success": false, "message": data['data']?['old_password']?[0] ?? "Password change failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- CREATE PIN ----------------
  Future<Map<String, dynamic>> createPin({
    required String newPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {"transaction_pin": newPin};

    try {
      final res = await authPost("/create-pin/", body, context: context!);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Pin Created Successfully"};
      } else {
        return {"success": false, "message": data['data']?['transaction_pin']?[0] ?? "Pin creation failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- CHANGE PIN ----------------
  Future<Map<String, dynamic>> changePin({
    required String oldPin,
    required String newPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {"old_transaction_pin": oldPin, "transaction_pin": newPin};

    try {
      final res = await authPut("/change-pin/", body, context: context);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Pin Updated Successfully"};
      } else {
        return {"success": false, "message": data['message'] ?? "Pin change failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- REQUEST PIN RESET ----------------
  Future<Map<String, dynamic>> requestPinReset({
    required String email,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authPost("/request-reset-pin/", {"email": email}, context: context!);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Email sent successfully, click okay to continue"};
      } else {
        return {"success": false, "message": "Pin request error: User not found!"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- PIN RESET ----------------
  Future<Map<String, dynamic>> pinReset({
    required String email,
    required String otp,
    required String transactionPin,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {"email": email, "otp": otp, "transaction_pin": transactionPin};

    try {
      final res = await authPost("/verify-reset-pin/", body, context: context!);
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Pin reset successful"};
      } else {
        return {"success": false, "message": data['message'] ?? "Pin reset failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // ---------------- UPDATE USER ----------------
  Future<Map<String, dynamic>> updateUser({
    File? photo,
    required String fullName,
    required String phoneNo,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final fields = {"full_name": fullName, "phone_no": phoneNo};

    try {
      final res = await authMultipartPut(
        "/update-user-profile/",
        fields,
        file: photo,
        fileField: "profile_picture",
        context: context,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "User updated successfully"};
      } else {
        final data = json.decode(res.body);
        return {"success": false, "message": data['message'] ?? "Update failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Create Virtual Account
  // -------------------------
  Future<Map<String, dynamic>> createVirtualAccount({
    required String accountName,
    String? bankName,
    String? nin,
    required BuildContext? context,
  }) async {
    _status = true;
    _bankType = bankName ?? "";
    notifyListeners();

    final body = {
      "account_name": accountName,
      "bank_name": bankName,
      "nin": nin,
    };

    try {
      final res = await authPost(
        "/create-virtual-account/",
        body,
        context: context!,
      );
      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context); // refresh user info
        return {
          "success": true,
          "message": data['message'] ?? "Virtual account created successfully",
          "data": data['data'] ?? {}
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to create virtual account",
        };
      }
    } on SocketException {
      return {
        "success": false,
        "message": "Internet connection is not available",
      };
    } catch (e) {
      debugPrint("createVirtualAccount error: $e");
      return {
        "success": false,
        "message": "Please try again",
      };
    } finally {
      _status = false;
      notifyListeners();
    }
  }



  // ---------------- CLOSE ACCOUNT ----------------
  Future<Map<String, dynamic>> closeAccount({BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authDelete("/account/close/", context: context);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await getUser(context: context);
        return {"success": true, "message": "Account closed successfully"};
      } else {
        final data = json.decode(res.body);
        return {"success": false, "message": data['message'] ?? "Account closure failed"};
      }
    } on SocketException {
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      print("::: $e");
      return {"success": false, "message": "Please try again"};
    } finally {
      _status = false;
      notifyListeners();
    }
  }
}
