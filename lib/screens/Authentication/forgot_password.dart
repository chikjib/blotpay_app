import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/AuthProvider/auth_provider.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

import '../../styles/colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _email = TextEditingController();

  bool _isSubmitting = false;


  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light
    ));
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
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: black, size: 30,),
          onPressed: () {
            if (!_isSubmitting) {
              Navigator.of(context).pop();
            } else {
              debugPrint("Back blocked during submit");
            }
          },
        ),
      ),
      body:  SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reset your password",
                    style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: black),
                  ),
                  const SizedBox(height: 15,),
                  Text(
                    "Fill in your email address below to reset your password",
                    style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: grey),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  customTextField(
                      title: 'Email',
                      controller: _email,
                      myIcon: const Icon(Icons.email),
                      autoValidate: AutovalidateMode.onUserInteraction,
                      hint: 'Enter your valid email address',
                      validator: (value) =>
                          validations.validateEmail(value, "Email"),
                      type: TextInputType.emailAddress),

                  const SizedBox(
                    height: 20,
                  ),

              Consumer<AuthenticationProvider>(
                builder: (context, forgot, child) {
                  return customButton(
                    text: 'Submit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    tap: () async {
                      if (_isSubmitting) return; // prevent double taps

                      if (_formKey.currentState!.validate()) {
                        setState(() => _isSubmitting = true);

                        final result = await forgot.forgotPassword(
                          email: _email.text.trim(),
                        );

                        if (!mounted) return;
                        setState(() => _isSubmitting = false);

                        if (result["success"] == true) {
                          snack_success(
                            message: result["message"],
                            context: context,
                          );
                          // Example: navigate after success
                          // PageNavigator(ctx: context).nextPageOnly(page: const LoginPage());
                        } else {
                          snack_error(
                            message: result["message"],
                            context: context,
                          );
                        }
                      }
                    },
                    context: context,
                    status: forgot.isLoading, // still shows loading spinner if provider is busy
                  );
                },
              )



              ],
              ),
            ),
          ),
        ),
      ),

    )
    );
  }
}
