import 'package:blotpay/models/User/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/send_notification.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

import '../../widgets/custom_dialog.dart';

class PinResetPage extends StatefulWidget {
  final UserModel? user;

  const PinResetPage({super.key, required this.user});

  @override
  State<PinResetPage> createState() => _PinResetPageState();
}

class _PinResetPageState extends State<PinResetPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _otp = TextEditingController();
  TextEditingController _newPin = TextEditingController();
  TextEditingController _confirmPin = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _otp.clear();
    _newPin.clear();
    _confirmPin.clear();

  }

  @override
  Widget build(BuildContext context) {
    return  PopScope(
        canPop: !_isSubmitting, // ✅ block back if still loading
        onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        debugPrint("Back press blocked while loading...");
      }
    },
    child: Scaffold(
        backgroundColor: myLightGrey,
        appBar: AppBar(
          backgroundColor: myLightGrey,
          elevation: 0,
          title: const Text(
            'Reset Pin',
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
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        customTextField(
                          title: "Otp Code",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.number,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _otp,
                          obscure: _obscureCurrent,
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_obscureCurrent == true) {
                                    _obscureCurrent = false;
                                  } else {
                                    _obscureCurrent = true;
                                  }
                                });
                              },
                              icon: _obscureCurrent
                                  ? const Icon(Icons.visibility,size: 30,)
                                  : const Icon(Icons.visibility_off, size: 30,)),
                          validator: (value) =>
                              validations.validateText(value, "Otp"),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        customTextField(
                          title: "New Pin",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.number,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _newPin,
                          obscure: _obscureNew,
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_obscureNew == true) {
                                    _obscureNew = false;
                                  } else {
                                    _obscureNew = true;
                                  }
                                });
                              },
                              icon: _obscureNew
                                  ? const Icon(Icons.visibility,size: 30,)
                                  : const Icon(Icons.visibility_off, size: 30,)),
                          validator: (value) =>
                              validations.validateText(value, "New pin"),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                        customTextField(
                          title: "Confirm New Pin",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.number,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _confirmPin,
                          obscure: _obscureConfirm,
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_obscureConfirm == true) {
                                    _obscureConfirm = false;
                                  } else {
                                    _obscureConfirm = true;
                                  }
                                });
                              },
                              icon: _obscureConfirm
                                  ? const Icon(Icons.visibility,size: 30,)
                                  : const Icon(Icons.visibility_off, size: 30,)),
                          validator: (value) =>
                              validations.pinMatch(_newPin.text, "Confirm new pin",value),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),

                        Consumer<UserProvider>(
                          builder: (context, reset, child) {
                            return customButton(
                              text: 'Save Changes',
                              fontSize: 16,
                              tap: () async {
                                if (_isSubmitting) return; // prevent double taps

                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  if (_newPin.text.trim() != _confirmPin.text.trim()) {
                                    snack_error(
                                      message: "The two pins do not match",
                                      context: context,
                                    );
                                    return;
                                  }

                                  setState(() => _isSubmitting = true);

                                  final result = await reset.pinReset(
                                    otp: _otp.text.trim(),
                                    email: widget.user!.data!.email.toString(),
                                    transactionPin: _newPin.text.trim(),
                                    context: context, // ✅ if provider needs context
                                  );

                                  if (!mounted) return;
                                  setState(() => _isSubmitting = false);

                                  // ✅ Handle result directly
                                  if (result["success"] == true) {
                                    sendNotification("Pin Reset", "Your pin was recently reset");
                                    customDialogSuccess(
                                      context,
                                      result["message"],
                                      "Reset Pin",
                                      const Dashboard(),
                                    );
                                  } else {
                                    customDialogError(
                                      context,
                                      result["message"],
                                      "Reset Pin",
                                    );
                                  }
                                }
                              },
                              context: context,
                              status: reset.status,
                            );
                          },
                        )

                      ],
                    )
                )
            )
        ))
    );
  }
}
