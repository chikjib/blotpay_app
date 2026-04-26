import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blotpay/screens/AccountPage/support_page.dart';
import 'package:blotpay/utils/currency.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/Transaction/transaction_model.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPage extends StatefulWidget {
  final TransactionModelDatum detail;

  const DetailPage({super.key, required this.detail});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Repaint only the scrollable body so the shared image doesn’t include the app bar.
  final GlobalKey _shareKey = GlobalKey();

  Future<void> _openWhatsAppChannel() async {
    final Uri url = Uri.parse(
      "https://whatsapp.com/channel/0029Vaic5lH6buMM2gBIHd1T",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // opens WhatsApp or browser
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp channel")),
      );
    }
  }


  checkStatus(String status) {
    switch (status) {
      case "pending":
        return Text(
          "pending",
          style: TextStyle(color: amber, fontWeight: FontWeight.w600, fontSize: 12),
        );
      case "confirmed":
        return Text(
          "confirmed",
          style: TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 12),
        );
      case "failed":
        return Text(
          "failed",
          style: TextStyle(color: red, fontWeight: FontWeight.w600, fontSize: 12),
        );
      case "ignored":
        return Text(
          "ignored",
          style: TextStyle(color: pink, fontWeight: FontWeight.w600, fontSize: 12),
        );
      case "reversed":
        return Text(
          "reversed",
          style: TextStyle(color: purple, fontWeight: FontWeight.w600, fontSize: 12),
        );
    }
  }

  Color getStatusBackground(String status) {
    switch (status) {
      case "pending":
        return amber.withValues(alpha: 0.2);
      case "confirmed":
        return green.withValues(alpha: 0.2);
      case "failed":
        return red.withValues(alpha: 0.2);
      case "ignored":
        return pink.withValues(alpha: 0.2);
      case "reversed":
        return purple.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Future<void> _shareAsImage() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      final boundary =
          _shareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = (await getTemporaryDirectory()).path;
      final file = File(
        '$dir/transaction_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
          ShareParams(
            text: 'Transaction Receipt',
            files: [XFile(file.path)],
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          )
      );

    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  final debitCategories = [
    "airtime",
    "data",
    "cable",
    "electricity",
    "exam",
    "sms",
    "upgrade",
  ];

  String sign = "+"; // default credit

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    if (debitCategories.contains(detail.category?.type)) {
      if (detail.status == "confirmed" ||
          detail.status == "pending" ||
          detail.status == "failed") {
        sign = "-"; // debit confirmed
      }
    }

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: _shareAsImage,
          ),
        ],
        centerTitle: false,
      ),
      body: RepaintBoundary(
        key: _shareKey,
        child: Stack(
          children: [
            // ✅ Watermark behind content but inside the boundary

            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoSize = constraints.maxWidth * 0.8; // 80% of width
                    return Center(
                      child: Transform.translate(
                          offset: const Offset(0, -90),
                        child: Transform.rotate(
                          angle: -0.5, // diagonal rotation (~ -28.6°)
                          child: Opacity(
                            opacity: 0.2,
                            child: Image.asset(
                              "assets/images/splash_logo.png", // PNG version
                              width: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )

                    );
                  },
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Amount + status block
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$sign ${formatNaira(double.tryParse(detail.amount.toString()))}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ✅ overflow-safe row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "${detail.plan} recharge for ${detail.phoneNo}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontFamily: 'Roboto',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusBackground(detail.status.toString()),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: checkStatus(detail.status.toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowItem(
                        "Date & Time:",
                        DateFormat.jm().add_yMMMd().format(detail.createdAt!),
                      ),
                      _rowItem("Reference", detail.txRef ?? "", copyable: true),
                      _rowItem("Type:", detail.category?.description ?? ""),
                      (detail.cardNo != null && detail.cardNo!.isNotEmpty)
                          ? _rowItem("Beneficiary:", detail.cardNo ?? "")
                          : _rowItem("Beneficiary:", detail.phoneNo ?? ""),

                      (detail.token != null  && detail.token!.isNotEmpty)
                          ? _rowItem("Token", detail.token ?? "")
                          : const SizedBox(),
                      _rowItem("Method:", "Wallet"),
                      _rowItem(
                        "Before transaction:",
                        formatNaira(
                          double.tryParse(detail.initialBalance.toString()),
                        ),
                      ),
                      _rowItem(
                        "After transaction:",
                        formatNaira(double.tryParse(detail.newBalance.toString())),
                      ),
                      _rowItem("Fee:", "₦0.00"),
                      const SizedBox(height: 10,),
                      Center(
                        child: Text("Thanks for choosing Blotpay", style: TextStyle(fontWeight: FontWeight.w700),),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Rectify row like screenshot
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    // light red background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Having issues with this transaction? ",
                          style: TextStyle(color: primaryColor, fontSize: 14),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () {
                              PageNavigator(ctx: context).nextPage(page: const ContactSupportPage());
                            },
                            child: Text(
                              "Rectify",
                              style: TextStyle(
                                color: primaryColor, // darker red
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: GestureDetector(
                    onTap: _openWhatsAppChannel,
                    child: Text(
                      "Join our WhatsApp channel to enjoy massive giveaways 🎁",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ],
        )


      ),
    );
  }

  Widget _rowItem(String title, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Value + Copy
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (copyable)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied to clipboard")),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                // Value text wraps instead of overflowing
                Expanded(
                  child: Text(
                    value,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
