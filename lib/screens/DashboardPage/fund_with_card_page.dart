import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/DashboardPage/payment_success_page.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../styles/colors.dart';
import 'budpay_payment_page.dart';

class FundWithCardPage extends StatefulWidget {
  final UserModel? user;

  const FundWithCardPage({Key? key, required this.user}) : super(key: key);

  @override
  State<FundWithCardPage> createState() => _FundWithCardPageState();
}

class _FundWithCardPageState extends State<FundWithCardPage> {
  String _amount = "";

  void _onKeyTap(String value) {
    setState(() {
      if (value == "back") {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else {
        _amount += value;
      }
    });
  }

  Future<void> _submit() async {
    if (_amount.isEmpty) return;

    double amount = double.parse(_amount);

    PageNavigator(ctx: context).nextPage(
      page: BudpayInlinePaymentScreen(
        user: widget.user,
        amount: amount,
        onPaymentSuccess: (response) async {
          debugPrint("Payment completed: $response");
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final displayAmount = _amount.isEmpty
        ? "0.00"
        : double.parse(_amount).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Fund with Card',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.09),
              // 🔹 Scrollable content
              Column(
                children: [
                  const Text(
                    "Enter Amount",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "₦$displayAmount",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.1),

              // 🔹 Fixed keypad pinned at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildKeypad(screenWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(double screenWidth) {
    final buttonSize = screenWidth * 0.22;

    return Column(
      children: [
        for (var row in [
          ["1", "2", "3"],
          ["4", "5", "6"],
          ["7", "8", "9"],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((e) => _buildKey(e, size: buttonSize)).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey(
                "back",
                icon: LucideIcons.arrowLeft,
                color: Colors.grey[300]!,
                size: buttonSize,
              ),
              _buildKey("0", size: buttonSize),
              _buildKey(
                "submit",
                icon: LucideIcons.arrowRight,
                color: primaryColor,
                size: buttonSize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(
    String value, {
    IconData? icon,
    required double size,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: () {
        if (value == "submit") {
          _submit();
        } else {
          _onKeyTap(value);
        }
      },
      child: CircleAvatar(
        radius: 50,
        backgroundColor: value == "submit"
            ? primaryColor
            : (value == "back" ? Colors.grey[300] : Colors.white),
        child: icon != null
            ? Icon(
                icon,
                color: value == "submit" ? Colors.white : Colors.black87,
              )
            : Text(value, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
