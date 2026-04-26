import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:blotpay/constants/app_constants.dart';
import '../../helpers/auth_helpers.dart';
import '../../models/User/beneficiary_model.dart';

class BeneficiaryProvider extends ChangeNotifier {
  final requestBaseUrl = AppConstant.baseUrl;

  /// 🔹 Loading status
  bool _status = false;
  bool get status => _status;

  BeneficiaryModel? beneficiaryModel;

  /// 🔹 Get All Beneficiary List
  Future<BeneficiaryModel> getAllBeneficiaries({
    required int categoryId,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authGet(
        "/beneficiary-list/?category_id=$categoryId",
        context: context,
      );

      final jsonData = json.decode(res.body);
      print("all beneficiary list");
      print(jsonData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        beneficiaryModel = BeneficiaryModel.fromJson(jsonData);
        return beneficiaryModel!;
      } else {
        return BeneficiaryModel();
      }
    } on SocketException {
      return BeneficiaryModel();
    } catch (e) {
      debugPrint("Error getBeneficiaries: $e");
      return BeneficiaryModel();
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  /// 🔹 Get Beneficiary List
  Future<BeneficiaryModel> getBeneficiaries({
    required int categoryId,
    required String networkType,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authGet(
        "/beneficiary-list/?category_id=$categoryId&network_type=$networkType",
        context: context,
      );

      final jsonData = json.decode(res.body);
      print("beneficiary list");
      print(jsonData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        beneficiaryModel = BeneficiaryModel.fromJson(jsonData);
        return beneficiaryModel!;
      } else {
        return BeneficiaryModel();
      }
    } on SocketException {
      return BeneficiaryModel();
    } catch (e) {
      debugPrint("Error getBeneficiaries: $e");
      return BeneficiaryModel();
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  /// 🔹 Save Beneficiary
  Future<Map<String, dynamic>> saveBeneficiary({
    required String phoneNo,
    required int category,
    required String networkType,
    required String name,
    required BuildContext context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "phone_no": phoneNo,
      "category": category,
      "network_type": networkType,
      "name": name,
    };

    try {
      final res = await authPost(
        "/beneficiary-list/",
        body,
        context: context,
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          "success": true,
          "message": data['message'] ?? "Beneficiary saved"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to save beneficiary"
        };
      }
    } on SocketException {
      return {
        "success": false,
        "message": "Internet connection is not available"
      };
    } catch (e) {
      debugPrint("Error saveBeneficiary: $e");
      return {
        "success": false,
        "message": "Please try again"
      };
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  /// 🔹 Update Beneficiary
  Future<Map<String, dynamic>> updateBeneficiary({
    required String phoneNo,
    required String beneficiaryId,
    required String name,
    required BuildContext context,
  }) async {
    _status = true;
    notifyListeners();

    final body = {
      "phone_no": phoneNo,
      "beneficiary_id": beneficiaryId,
      "name": name,
    };

    print(body);

    try {
      final res = await authPut(
        "/beneficiary-list/",
        body,
        context: context,
      );

      final data = json.decode(res.body);
      print(data);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          "success": true,
          "message": data['message'] ?? "Beneficiary saved"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to save beneficiary"
        };
      }
    } on SocketException {
      return {
        "success": false,
        "message": "Internet connection is not available"
      };
    } catch (e) {
      debugPrint("Error saveBeneficiary: $e");
      return {
        "success": false,
        "message": "Please try again"
      };
    } finally {
      _status = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteBeneficiary({
    required String beneficiaryId,
    required BuildContext context,
  }) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authDelete(
        "/beneficiary-list/?beneficiary_id=$beneficiaryId",
        context: context,
      );

      print(beneficiaryId);

      final data = json.decode(res.body);
      print(data);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          "success": true,
          "message": data['message'] ?? "Beneficiary deleted"
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to delete beneficiary"
        };
      }
    } on SocketException {
      return {
        "success": false,
        "message": "Internet connection is not available"
      };
    } catch (e) {
      debugPrint("Error deleteBeneficiary: $e");
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
