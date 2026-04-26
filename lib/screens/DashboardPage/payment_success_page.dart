import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:blotpay/utils/send_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final UserModel? user;

  const PaymentSuccessScreen({
    Key? key,
    required this.amount,
    required this.user,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {

  @override
  void initState() {
    // TODO: implement initState
    notifyUser();
    super.initState();
  }


  void notifyUser() async {

    final totalFunded1 = widget.amount - ((1.4 / 100) * widget.amount);

    sendNotification(
      "Fund Wallet",
      "Your account has been funded with ₦${totalFunded1.toStringAsFixed(2)}. Thank you for choosing us",
    );

  }


  @override
  Widget build(BuildContext context) {
    final totalFunded = widget.amount - ((1.4 / 100) * widget.amount);

    return PopScope(
        canPop: false, // disables all back navigation
        onPopInvokedWithResult: (didPop, result) {
          // Optional: handle back attempt if needed
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false, // removes the back arrow
            title: const Text(
              "Payment Confirmation",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 100),
                  const SizedBox(height: 20),
                  Text(
                    "₦${totalFunded.toStringAsFixed(2)} added successfully!",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Roboto'
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your wallet has been credited, ${widget.user?.data?.fullName?.split(" ").last}.",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Go to Dashboard",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}
