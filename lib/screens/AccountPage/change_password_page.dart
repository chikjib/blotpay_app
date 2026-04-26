import 'package:blotpay/screens/AccountPage/account_page.dart';
import 'package:flutter/material.dart';
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

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _oldPassword = TextEditingController();
  TextEditingController _newPassword = TextEditingController();
  TextEditingController _confirmPassword = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;


  @override
  void dispose() {
    // TODO: implement dispose
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
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
    child:Scaffold(
        backgroundColor: myLightGrey,
        appBar: AppBar(
          backgroundColor: myLightGrey,
          elevation: 0,
          title: const Text(
            'Change Password',
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
                          title: "Current Password",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.text,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _oldPassword,
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
                              validations.validateText(value, "Current password"),
                        ),
                        customTextField(
                          title: "New Password",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.text,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _newPassword,
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
                              validations.checkPassword(value, "New password"),
                        ),
                        customTextField(
                          title: "Confirm New Password",
                          myIcon: const Icon(Icons.password),
                          type: TextInputType.text,
                          autoValidate: AutovalidateMode.onUserInteraction,
                          controller: _confirmPassword,
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
                              validations.passwordMatch(_newPassword.text, "Confirm new password",value),
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

                                  if (_newPassword.text.trim() != _confirmPassword.text.trim()) {
                                    snack_error(
                                      message: "The two passwords do not match",
                                      context: context,
                                    );
                                    return;
                                  }

                                  setState(() => _isSubmitting = true);

                                  final result = await changer.changePassword(
                                    oldPassword: _oldPassword.text.trim(),
                                    newPassword: _newPassword.text.trim(),
                                    confirmPassword: _confirmPassword.text.trim(),
                                    context: context, // ✅ pass context if your provider needs it
                                  );

                                  if (!mounted) return;
                                  setState(() => _isSubmitting = false);

                                  // ✅ Handle result directly (like upgradeUser flow)
                                  if (result["success"] == true) {
                                    sendNotification("Password Update", "Your password was recently changed");
                                    customDialogSuccess(
                                      context,
                                      result["message"],
                                      "Change Password",
                                      const Dashboard(),
                                    );
                                  } else {
                                    customDialogError(
                                      context,
                                      result["message"],
                                      "Change Password",
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
