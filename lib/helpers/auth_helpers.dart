import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../providers/Database/db_provider.dart';
import 'package:blotpay/constants/app_constants.dart';

final requestBaseUrl = AppConstant.baseUrl;

/// Generic authenticated GET
Future<http.Response> authGet(String endpoint, {BuildContext? context}) async {
  final db = DatabaseProvider();
  final token = await db.getToken();

  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  final uri = endpoint.startsWith('http')
      ? Uri.parse(endpoint) // full URL (pagination)
      : Uri.parse("$requestBaseUrl$endpoint"); // relative path

  final res = await http.get(uri, headers: headers);

  if (res.statusCode == 401 && context != null) {
    await _handleUnauthorized(context);
  }

  return res;
}

/// Generic authenticated POST
Future<http.Response> authPost(String endpoint, Map<String, dynamic> body,
    {required BuildContext context}) async {
  final db = DatabaseProvider();
  final token = await db.getToken();

  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  final res = await http.post(
    Uri.parse("$requestBaseUrl$endpoint"),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 401) {
    await _handleUnauthorized(context);
  }

  return res;
}

/// Generic authenticated PUT
Future<http.Response> authPut(String endpoint, Map<String, dynamic> body,
    {BuildContext? context}) async {
  final db = DatabaseProvider();
  final token = await db.getToken();

  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  final res = await http.put(
    Uri.parse("$requestBaseUrl$endpoint"),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 401 && context != null) {
    await _handleUnauthorized(context);
  }

  return res;
}

Future<http.Response> authMultipartPut(
    String endpoint,
    Map<String, String> fields, {
      File? file,
      String fileField = "profile_picture",
      BuildContext? context,
    }) async {
  final db = DatabaseProvider();
  final token = await db.getToken();

  final url = Uri.parse("$requestBaseUrl$endpoint");
  var request = http.MultipartRequest("PUT", url);

  // Add auth header
  request.headers["Authorization"] = "Bearer $token";

  // Add fields
  request.fields.addAll(fields);

  // Add file if provided
  if (file != null) {
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
  }

  // Send request
  var streamedResponse = await request.send();

  // Convert to Response so it matches authPut
  final response = await http.Response.fromStream(streamedResponse);

  // Handle 401 just like authPut
  if (response.statusCode == 401 && context != null) {
    await _handleUnauthorized(context);
  }

  return response;
}




/// Generic authenticated DELETE
Future<http.Response> authDelete(String endpoint, {BuildContext? context}) async {
  final db = DatabaseProvider();
  final token = await db.getToken();

  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  final res = await http.delete(
    Uri.parse("$requestBaseUrl$endpoint"),
    headers: headers,
  );

  if (res.statusCode == 401 && context != null) {
    await _handleUnauthorized(context);
  }

  return res;
}

/// Handle 401 Unauthorized (example: force logout)
Future<void> _handleUnauthorized(BuildContext context) async {
  final db = DatabaseProvider();
  await db.sessionLogOut(context);
}