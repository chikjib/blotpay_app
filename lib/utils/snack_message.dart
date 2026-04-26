import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';

import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';


void snack_success({String? message, BuildContext? context}){
  showTopSnackBar(
    Overlay.of(context!),
    CustomSnackBar.success(
      backgroundColor: Colors.lightBlue,
      message: message ?? "",
    ),
  );
}

void snack_error({String? message, BuildContext? context}){
  showTopSnackBar(
    Overlay.of(context!),
    CustomSnackBar.error(
      backgroundColor: red,
      message: message ?? "",
    ),
  );
}