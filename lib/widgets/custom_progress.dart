import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';

import 'package:flutter/material.dart';
import 'logo_spinner.dart';

OverlayEntry? _loaderOverlay;

/// Show fullscreen loader
void showLoader(BuildContext context, {String message = "Loading..."}) {
  if (_loaderOverlay != null) return; // already showing

  _loaderOverlay = OverlayEntry(
    builder: (_) => Stack(
      children: [
        // Dim background
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        // Centered logo + text
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoSpinner(size: 70, duration: Duration(seconds: 2)),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Overlay.of(context, rootOverlay: true).insert(_loaderOverlay!);
}

/// Hide fullscreen loader
void hideLoader() {
  _loaderOverlay?.remove();
  _loaderOverlay = null;
}


Row customProgress(double width, double height){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: height,
        width: width,
        child:  CircularProgressIndicator(strokeWidth: 2,color: primaryColor),
      ),
      const SizedBox(width: 10,),
      const Text("Loading...")
    ],
  );
}
Row reloader(double width, double height){
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: height,
        width: width,
        child:  CircularProgressIndicator(strokeWidth: 2,color: primaryColor),
      ),
      const SizedBox(width: 10,),
    ],
  );
}