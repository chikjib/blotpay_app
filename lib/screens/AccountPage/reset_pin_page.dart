import 'package:blotpay/screens/AccountPage/pin_reset_page.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';

class ResetPinPage extends StatefulWidget {
  final UserModel? user;

  const ResetPinPage({super.key, required this.user});

  @override
  State<ResetPinPage> createState() => _ResetPinPageState();
}

class _ResetPinPageState extends State<ResetPinPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_isSubmitting, // ✅ block back if still loading
        onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        debugPrint("Back press blocked while loading...");
      }
    },
    child:
    Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Reset Transaction Pin',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            if (!_isSubmitting) {
              Navigator.of(context).pop();
            } else {
              debugPrint("Back blocked during submit");
            }
          },
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon in yellow circle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2), // light yellow background
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 60,
                color: primaryColor, // amber/yellow
              ),
            ),
            const SizedBox(height: 50),

            // Main description
            const Text(
              "Your transaction pin is a 4-digit code introduced to provide an extra layer of security for your Wallet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 15),

            // Extra description
            const Text(
              "To reset your transaction pin, a mail with a confirmation code will be sent to your email address.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const Spacer(),

            // Reset button
            Consumer<UserProvider>(
              builder: (context, resetPin, child) {
                return customButton(
                  text: 'Reset Pin',
                  fontSize: 16,
                  tap: () async {
                    if (_isSubmitting) return; // prevent double taps

                    setState(() => _isSubmitting = true);

                    final result = await resetPin.requestPinReset(
                      email: widget.user!.data!.email.toString(),
                      context: context, // ✅ pass context if provider needs it
                    );

                    if (!mounted) return;
                    setState(() => _isSubmitting = false);

                    // ✅ Handle result directly
                    if (result["success"] == true) {
                      Navigator.of(context).pop();
                      PageNavigator(ctx: context).nextPage(
                        page: PinResetPage(user: widget.user),
                      );
                      // You can add notification here if needed
                    } else {
                      customDialogError(
                        context,
                        result["message"],
                        "Reset Pin",
                      );
                    }
                  },
                  context: context,
                  status: resetPin.status,
                );
              },
            )

          ],
        ),
      ),
    )
    );
  }
}
