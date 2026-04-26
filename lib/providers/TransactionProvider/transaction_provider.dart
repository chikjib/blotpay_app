import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/helpers/auth_helpers.dart';
import 'package:blotpay/models/Transaction/transaction_model.dart';
import 'package:blotpay/providers/Database/db_provider.dart';

class TransactionProvider extends ChangeNotifier {
  bool _status = false;
  String? _nextUrl;
  List<TransactionModelDatum> _transactions = [];

  bool get status => _status;
  List<TransactionModelDatum> get transactions => _transactions;
  bool get hasMore => _nextUrl != null;

  /// ✅ Load cached transactions from local DB
  Future<void> loadCachedTransactions() async {
    try {
      final cachedModel = await DatabaseProvider().getTransactionDetails();
      if (cachedModel.data != null) {
        _transactions = cachedModel.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading cached transactions: $e");
    }
  }

  /// ✅ Fetch transactions (with pagination)
  Future<Map<String, dynamic>> getTransactions({
    bool loadMore = false,
    BuildContext? context,
  }) async {
    _status = true;
    notifyListeners();

    final url = loadMore && _nextUrl != null
        ? _nextUrl!
        : "/get-transactions/?limit=10";

    try {
      final req = await authGet(url, context: context);

      _status = false;
      notifyListeners();
      if (req.statusCode == 200) {
        final jsonData = json.decode(req.body);

        // pagination
        _nextUrl = jsonData['next'];

        // parse transactions
        final results = jsonData['results']['data'] as List;
        final newTransactions =
        results.map((e) => TransactionModelDatum.fromJson(e)).toList();

        if (loadMore) {
          _transactions.addAll(newTransactions);
        } else {
          _transactions = newTransactions;
        }

        // cache response
        await DatabaseProvider().saveTransactionDetails(json.encode(jsonData));

        return {"success": true, "message": "Success", "data": _transactions};
      } else {
        return {"success": false, "message": "Something went wrong", "data": []};
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return {"success": false, "message": "Internet connection is not available", "data": []};
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("Transaction fetch error: $e");
      return {"success": false, "message": "Please try again", "data": []};
    }
  }
}
