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

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _oldPin = TextEditingController();
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
    _oldPin.clear();
    _newPin.clear();
    _confirmPin.clear();

  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
            'Change Pin',
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
                          title: "Current Pin",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.number,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _oldPin,
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
                              validations.validateText(value, "Current pin"),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
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
                          builder: (context, changer, child) {
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

                                  final result = await changer.changePin(
                                    oldPin: _oldPin.text.trim(),
                                    newPin: _newPin.text.trim(),
                                    context: context, // ✅ pass context if provider needs it
                                  );

                                  if (!mounted) return;
                                  setState(() => _isSubmitting = false);

                                  // ✅ Handle result directly
                                  if (result["success"] == true) {
                                    sendNotification("Pin Update", "Your pin was recently changed");
                                    customDialogSuccess(
                                      context,
                                      result["message"],
                                      "Change Pin",
                                      const Dashboard(),
                                    );
                                  } else {
                                    customDialogError(
                                      context,
                                      result["message"],
                                      "Change Pin",
                                    );
                                  }
                                }
                              },
                              context: context,
                              status: changer.status,
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
