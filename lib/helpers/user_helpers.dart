import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> cacheUser(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ Save basic user fields
  await prefs.setInt("user_id", user["id"]);
  await prefs.setString("username", user["username"] ?? "");
  await prefs.setString("email", user["email"] ?? "");
  await prefs.setString("full_name", user["full_name"] ?? "");
  await prefs.setString(
    "wallet_balance",
    user["wallet_balance"]?.toString() ?? "0.00",
  );
  await prefs.setString("user_level", user["user_level"] ?? "");
  await prefs.setString("profile_picture", user["profile_picture"] ?? "");

  // ✅ Save transactions (as JSON string)
  if (user.containsKey("transactions")) {
    await prefs.setString(
      "transactions",
      jsonEncode(user["transactions"]),
    );
  }
}

Future<Map<String, dynamic>> loadCachedUser() async {
  final prefs = await SharedPreferences.getInstance();

  return {
    "id": prefs.getInt("user_id") ?? 0,
    "username": prefs.getString("username") ?? "",
    "email": prefs.getString("email") ?? "",
    "full_name": prefs.getString("full_name") ?? "",
    "wallet_balance": prefs.getString("wallet_balance") ?? "0.00",
    "user_level": prefs.getString("user_level") ?? "",
    "profile_picture": prefs.getString("profile_picture") ?? "",
    "transactions": prefs.getString("transactions") != null
        ? jsonDecode(prefs.getString("transactions")!)
        : [],
  };
}
