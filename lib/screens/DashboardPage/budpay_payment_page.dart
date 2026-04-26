import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/DashboardPage/payment_success_page.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:flutter/material.dart';
import 'package:budpay_inline_flutter/budpay_inline_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../styles/colors.dart';

class BudpayInlinePaymentScreen extends StatefulWidget {
  final double amount;
  final UserModel? user;
  final Function(dynamic response)? onPaymentSuccess;

  const BudpayInlinePaymentScreen({
    super.key,
    required this.user,
    required this.amount,
    this.onPaymentSuccess,
  });

  @override
  State<BudpayInlinePaymentScreen> createState() => _BudpayInlinePaymentScreenState();
}

class _BudpayInlinePaymentScreenState extends State<BudpayInlinePaymentScreen> {
  bool _hasHandledSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Complete Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: BudpayInlinePayment(
          publicKey: 'pk_live_k2mwip7u0yh8rytdazwze7mndcf3hhryu11tlv',
          email: widget.user?.data?.email ?? "",
          amount: widget.amount.toInt().toString(),
          firstName: widget.user?.data?.fullName?.split(" ").first ?? "",
          lastName: widget.user?.data?.fullName?.split(" ").last ?? "",
          currency: 'NGN',
          reference: DateTime.now().millisecondsSinceEpoch.toString(),

          onSuccess: (response) async {
            if (_hasHandledSuccess) return;
            _hasHandledSuccess = true;

            debugPrint("BudPay success: $response");

            // Instantly navigate to success page (no await or delay)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => PaymentSuccessScreen(
                      amount: widget.amount,
                      user: widget.user,
                    ),
                    transitionDuration: Duration.zero, // ⚡️ no animation
                  ),
                );
              }
            });

            // Trigger callback without delaying navigation
            widget.onPaymentSuccess?.call(response);
          },

          onCancel: () {
            snack_error(
              message: 'Transaction was not completed, window closed.',
              context: context,
            );
          },

          onError: (err) {
            snack_error(
              message: 'An error occurred: $err',
              context: context,
            );
          },
        ),
      ),
    );
  }
}
