import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:blotpay/utils/routers.dart';

customDialogError(ctx, message, title) {
  return showDialog<String>(
    context: ctx,
    builder: (_) =>
        AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 22, fontFamily: 'Roboto'), textAlign: TextAlign.center),
          content: Text(message, style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'), textAlign: TextAlign.center),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.of(ctx, rootNavigator: true).pop();

                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }


                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    "Okay",
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                )),
          ],
        ),
  );
}

customDialogSuccess(ctx, message, title, page) {
  return showDialog<String>(
    context: ctx,
    builder: (_) =>
        AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center,),
          content: Text(message, style: const TextStyle(fontSize: 16),),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(ctx, rootNavigator: true).pop();

                  // Close the bottom sheet if it exists
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }

                  Navigator.of(ctx).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => page),
                        (route) => false, // removes everything before new page
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    "Okay",
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                )),
          ],
        ),
  );
}