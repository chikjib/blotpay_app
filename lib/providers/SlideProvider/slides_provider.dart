import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blotpay/models/Slide/slide_model.dart';
import '../../helpers/auth_helpers.dart';

class SlideProvider extends ChangeNotifier {
  bool _status = false;
  bool get status => _status;

  /// Fetch Slides
  Future<SlideModel> getSlides({BuildContext? context}) async {
    _status = true;
    notifyListeners();

    try {
      final res = await authGet("/get-slides/", context: context);

      _status = false;
      notifyListeners();

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);
        return data['data'] == null ? SlideModel() : slideModelFromJson(res.body);
      } else {
        return SlideModel();
      }
    } on SocketException {
      _status = false;
      notifyListeners();
      return SlideModel();
    } catch (e) {
      _status = false;
      notifyListeners();
      debugPrint("getSlides Error: $e");
      return SlideModel();
    }
  }
}
