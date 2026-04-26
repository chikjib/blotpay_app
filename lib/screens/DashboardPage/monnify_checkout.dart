import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:blotpay/constants/app_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonnifyCheckoutPage extends StatefulWidget {
  final String checkoutUrl;
  final String redirectUrl;
  final String transactionReference;

  const MonnifyCheckoutPage({
    super.key,
    required this.checkoutUrl,
    required this.redirectUrl,
    required this.transactionReference,
  });



  @override
  State<MonnifyCheckoutPage> createState() => _MonnifyCheckoutPageState();
}

class _MonnifyCheckoutPageState extends State<MonnifyCheckoutPage> {
  late final WebViewController _webViewController;
  final baseUrl = AppConstant.baseUrl;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Detect redirect after payment
            if (request.url.startsWith(widget.redirectUrl)) {
              Uri uri = Uri.parse(request.url);
              print(uri);
              final transactionRef = widget.transactionReference;
              print("checkout ref");
              print(transactionRef);

              if (transactionRef != null) {
                _verifyTransaction(transactionRef);
              }

              return NavigationDecision.prevent; // Stop WebView from loading redirect page
            }
            // Detect when user manually exits Monnify (cancel/clicks close button)
            print("detect manual exit");
            print(request.url);
            if (request.url.contains("/callback") || request.url.contains("cancelled")) {
              Navigator.pop(context); // Or pushNamed to Fund Wallet
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _verifyTransaction(String transactionRef) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-atm-payment/?payment_reference=$transactionRef'),
      );

      final data = jsonDecode(response.body);
      print("data from verify");
      print(data);

      if (data['payment_status'] == 'PAID') {
        _showResult('✅ Payment Successful');
      } else {
        _showResult('❌ Payment Failed or Incomplete');
      }

    } catch (e) {
      _showResult('❗ Error verifying transaction');
    }
  }

  void _showResult(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Status'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monnify Checkout')),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}