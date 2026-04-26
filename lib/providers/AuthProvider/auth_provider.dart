import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:blotpay/providers/Database/db_provider.dart';

import '../../helpers/auth_helpers.dart';
import '../../utils/format_errors.dart';

class AuthenticationProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // -------------------------
  // Register User
  // -------------------------
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String phoneNumber,
    String? referral_code,
    BuildContext? context,
  }) async {
    _setLoading(true);

    final body = {
      "full_name": fullName,
      "username": userName,
      "email": email,
      "password": password,
      "password2": password,
      "phone_no": phoneNumber,
      "referral": referral_code
    };

    print(body);

    try {
      final req = await http.post(
        Uri.parse("$requestBaseUrl/register/"),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      print(req.body);

      _setLoading(false);

      if (req.statusCode == 200 || req.statusCode == 201) {
        await DatabaseProvider().switchUser();
        return {"success": true, "message": "Account created!"};
      } else {
        final res = json.decode(req.body);
        final Map<String, dynamic> myMap = res['data'] ?? {};
        List<String> errors = extractErrorMessages(myMap);
        String errorMessage = errors.join(', ');
        // myMap.forEach((key, value) {
        //   if (value is List && value.isNotEmpty) {
        //     errors.add(value[0].toString());
        //   }
        // });

        return {"success": false, "message": errorMessage};
      }
    } on SocketException {
      _setLoading(false);
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _setLoading(false);
      debugPrint("registerUser error: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  // -------------------------
  // Login User
  // -------------------------
  Future<Map<String, dynamic>> loginUser({
    required String identifier,
    required String password,
    BuildContext? context,
  }) async {
    _setLoading(true);

    final body = {"identifier": identifier, "password": password};

    try {
      final req = await http.post(
        Uri.parse("$requestBaseUrl/auth/login/"),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      _setLoading(false);

      if (req.statusCode == 200 || req.statusCode == 201) {
        final res = json.decode(req.body);
        print(res);

        final token = res['data']['access'] as String;
        final refresh = res['data']['refresh'] as String;
        final user = json.encode(res['data']['user']);
        final transactions = json.encode(res['data']['transactions']);

        final db = DatabaseProvider();
        await db.saveToken(token, refresh);
        await db.saveUserDetails(user);
        await db.saveTransactionDetails(transactions);

        return {"success": true, "message": "Login successful!"};
      } else {
        final res = json.decode(req.body);
        final msg = res['errors']?[0]?['detail'] ?? "Login failed";
        return {"success": false, "message": msg};
      }
    } on SocketException {
      _setLoading(false);
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _setLoading(false);
      debugPrint("loginUser error: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  // -------------------------
  // Forgot Password
  // -------------------------
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    BuildContext? context,
  }) async {
    _setLoading(true);

    try {
      final req = await http.post(
        Uri.parse("$requestBaseUrl/password_reset/"),
        body: jsonEncode({"email": email}),
        headers: {"Content-Type": "application/json"},
      );

      _setLoading(false);

      if (req.statusCode == 200 || req.statusCode == 201) {
        return {
          "success": true,
          "message":
          "An Email has been sent to your email address, please follow the instructions to reset your password"
        };
      } else {
        final res = json.decode(req.body);
        final msg = res['errors']?[0]?['detail'] ?? "Request failed";
        return {"success": false, "message": msg};
      }
    } on SocketException {
      _setLoading(false);
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _setLoading(false);
      debugPrint("forgotPassword error: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  // -------------------------
  // Logout User
  // -------------------------
  Future<Map<String, dynamic>> logoutUser(BuildContext? context) async {
    final db = DatabaseProvider();
    final token = await db.getToken();

    _setLoading(true);

    try {
      final req = await authPost("logout/", {"token": token}, context: context!);

      _setLoading(false);

      if (req.statusCode == 200 || req.statusCode == 201) {
        await db.logOut(context!);
        return {"success": true, "message": "Logged out successfully"};
      } else {
        final res = json.decode(req.body);
        return {"success": false, "message": res['data'] ?? "Logout failed"};
      }
    } on SocketException {
      _setLoading(false);
      return {"success": false, "message": "Internet connection is not available"};
    } catch (e) {
      _setLoading(false);
      debugPrint("logoutUser error: $e");
      return {"success": false, "message": "Please try again"};
    }
  }

  // -------------------------
  // Check Transaction PIN
  // -------------------------
  Future<bool> hasTransactionPin({BuildContext? context}) async {
    try {
      final response = await authGet("/verify-transaction-pin/", context: context);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"]["has_pin"] ?? false;
      }
    } catch (e) {
      debugPrint("Error checking transaction PIN: $e");
    }
    return false;
  }

  // -------------------------
  // Verify Transaction PIN
  // -------------------------
  Future<bool> verifyTransactionPin(String pin, {BuildContext? context}) async {
    try {
      final response = await authPost(
        "/verify-transaction-pin/",
        {"transaction_pin": pin},
        context: context!,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["data"]["valid"] == true;
      }
    } catch (e) {
      debugPrint("Error verifying transaction PIN: $e");
    }
    return false;
  }
}
