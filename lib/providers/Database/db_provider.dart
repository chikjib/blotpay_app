import 'dart:convert';
import 'package:blotpay/models/Transaction/transaction_model.dart';
import 'package:blotpay/screens/Authentication/welcome_login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/Authentication/login.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseProvider extends ChangeNotifier {
  // Use flutter_secure_storage
  static const _storage = FlutterSecureStorage();

  final requestBaseUrl = AppConstant.baseUrl;

  // TOKEN
  String _token = "";
  String _refreshToken = "";
  UserModel? _userDetails;
  TransactionModel? _userTransactions;

  String get token => _token;
  String get refreshToken => _refreshToken;
  UserModel? get userDetails => _userDetails;
  TransactionModel? get userTransactions => _userTransactions;

  /// Save Token securely
  Future<void> saveToken(String accessToken, String refreshToken) async {
    await _storage.write(key: 'token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);

    _token = accessToken;
    _refreshToken = refreshToken;
    notifyListeners();
  }

  /// Save User Details securely
  Future<void> saveUserDetails(dynamic details) async {
    try {
      Map<String, dynamic> json = jsonDecode(details);
      String detail = jsonEncode(UserModel.fromJson(json));
      await _storage.write(key: "user", value: detail);
      _userDetails = UserModel.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving user details: $e");
    }
  }

  /// Save User Transactions securely
  Future<void> saveTransactionDetails(dynamic details) async {
    try {
      final decoded = jsonDecode(details);

      if (decoded is List) {
        // If it's a List, wrap it in a TransactionModel
        String detail = jsonEncode(TransactionModel(data:
        decoded.map((e) => TransactionModelDatum.fromJson(e)).toList()
        ));
        await _storage.write(key: "transactions", value: detail);
        _userTransactions = TransactionModel(data:
        decoded.map((e) => TransactionModelDatum.fromJson(e)).toList()
        );
      } else if (decoded is Map<String, dynamic>) {
        // If it's already a Map (API pagination style)
        String detail = jsonEncode(TransactionModel.fromJson(decoded));
        await _storage.write(key: "transactions", value: detail);
        _userTransactions = TransactionModel.fromJson(decoded);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error saving transaction details: $e");
    }
  }


  /// Retrieve Token
  Future<String> getToken() async {
    final data = await _storage.read(key: 'token');
    if (data != null) {
      _token = data;
      notifyListeners();
      return data;
    } else {
      _token = "";
      notifyListeners();
      return '';
    }
  }

  /// Retrieve User Details
  Future<UserModel> getUserDetails() async {
    final data = await _storage.read(key: 'user');
    if (data != null) {
      try {
        Map<String, dynamic> json = jsonDecode(data);
        var user = UserModel.fromJson(json);
        _userDetails = user;
        notifyListeners();
        return user;
      } catch (e) {
        debugPrint("Error getting user details: $e");
        return UserModel();
      }
    } else {
      _userDetails = null;
      notifyListeners();
      return UserModel();
    }
  }
  /// Retrieve Transaction Details
  Future<TransactionModel> getTransactionDetails() async {
    final data = await _storage.read(key: 'transactions');
    if (data != null) {
      try {
        Map<String, dynamic> json = jsonDecode(data);
        var transaction = TransactionModel.fromJson(json);
        _userTransactions = transaction;
        notifyListeners();
        return transaction;
      } catch (e) {
        debugPrint("Error getting transaction details: $e");
        return TransactionModel();
      }
    } else {
      _userTransactions = null;
      notifyListeners();
      return TransactionModel();
    }
  }

  /// Log Out - Clear everything securely
  Future<void> logOut(BuildContext context) async {
    // 🗑️ Clear all tokens
    await _storage.delete(key: "token");
    await _storage.delete(key: "refreshToken"); // if you’re storing refresh
    _token = "";

    // Optionally clear cached user details if you store them
    // await _storage.delete(key: "user_details");
    // _userDetails = null;

    notifyListeners();

    // 🔄 Redirect to login screen
    if (context.mounted) {
      PageNavigator(ctx: context).nextPageOnly(page: const WelcomeLogin());

    }
  }

  Future<void> sessionLogOut(BuildContext context) async {
    // 🗑️ Clear all tokens
    await _storage.delete(key: "token");
    await _storage.delete(key: "refreshToken"); // if you’re storing refresh
    _token = "";

    // Optionally clear cached user details if you store them
    // await _storage.delete(key: "user_details");
    // _userDetails = null;

    notifyListeners();

    // 🔄 Redirect to login screen
    if (context.mounted) {
      // ✅ Show snackbar first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired, please log in again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ Delay slightly so snackbar can show before navigating
      await Future.delayed(const Duration(seconds: 2));

      // 🔄 Redirect to login screen
      PageNavigator(ctx: context).nextPageOnly(page: const WelcomeLogin());
    }
  }


  /// Log Out - Clear everything securely
  Future<void> switchUser() async {
    final prefs = await SharedPreferences.getInstance();

    await _storage.delete(key: "token");
    await _storage.delete(key: "user");
    await _storage.delete(key: "transactions");
    prefs.clear();

    _token = "";
    _userDetails = null;
    _userTransactions = null;

    notifyListeners();

  }

}
