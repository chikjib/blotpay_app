import 'package:flutter/material.dart';
import 'package:blotpay/styles/colors.dart';
import 'logo_spinner.dart';

OverlayEntry? _loaderOverlay;

/// Shows the fullscreen loader overlay with LogoSpinner
void _showLoader(BuildContext context) {
  if (_loaderOverlay != null) return; // already showing

  _loaderOverlay = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // Center logo spinner
        const Center(
          child: LogoSpinner(size: 60),
        ),
      ],
    ),
  );

  Overlay.of(context, rootOverlay: true).insert(_loaderOverlay!);
}

/// Hides the fullscreen loader overlay
void _hideLoader() {
  _loaderOverlay?.remove();
  _loaderOverlay = null;
}

Widget customButton({
  VoidCallback? tap,
  bool? status = false,
  String? text = "Save",
  double? fontSize = 16.0,
  FontWeight? fontWeight = FontWeight.w500,
  BuildContext? context,
}) {
  if (status == true && context != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_loaderOverlay == null) {
        _showLoader(context);
      }
    });
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hideLoader();
    });
  }

  return GestureDetector(
    onTap: status == true ? null : tap,
    child: Container(
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: status == false ? primaryColor : grey,
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context!).size.width,
      child: Text(
        status == false ? text! : 'Please wait...',
        style: TextStyle(
          color: white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    ),
  );
}
