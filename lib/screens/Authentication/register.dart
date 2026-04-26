import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/AuthProvider/auth_provider.dart';
import 'package:blotpay/screens/Authentication/login.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_drop_down_field.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _fullname = TextEditingController();
  TextEditingController _username = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _referral_code = TextEditingController();

  bool _obscure = true;
  bool _isSubmitting = false;


  @override
  void dispose() {
    _fullname.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _referral_code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
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
          icon: Icon(LucideIcons.chevronLeft, color: black),
          onPressed: () {
            if (!_isSubmitting) {
              Navigator.of(context).pop();
            } else {
              debugPrint("Back blocked during submit");
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create an Account",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Set up your account in few minutes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: grey,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 30),
                  customTextField(
                    title: 'Full Name',
                    controller: _fullname,
                    hint: 'Enter your full name',
                    myIcon: const Icon(Icons.abc),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        validations.validateText(value, 'First Name'),
                    type: TextInputType.name,
                  ),
                  customTextField(
                    title: 'Username',
                    controller: _username,
                    hint: 'Enter your username',
                    myIcon: const Icon(Icons.abc),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        validations.validateText(value, 'User Name'),
                    type: TextInputType.name,
                  ),

                  customTextField(
                    title: 'Phone Number',
                    controller: _phone,
                    myIcon: const Icon(Icons.phone),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    hint: 'Enter your phone number',
                    validator: (value) =>
                        validations.validatePhone(value, "Phone"),
                    type: TextInputType.phone,
                  ),
                  customTextField(
                    title: 'Email',
                    controller: _email,
                    myIcon: const Icon(Icons.email),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    hint: 'Enter your valid email address',
                    validator: (value) =>
                        validations.validateEmail(value, "Email"),
                    type: TextInputType.emailAddress,
                  ),
                  customTextField(
                    title: 'Password',
                    controller: _password,
                    myIcon: const Icon(Icons.password),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    hint: 'Enter your secured password',
                    validator: (value) =>
                        validations.validatePassword(value, "Password"),
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          if (_obscure == true) {
                            _obscure = false;
                          } else {
                            _obscure = true;
                          }
                        });
                      },
                      icon: _obscure
                          ? const Icon(Icons.visibility_off)
                          : const Icon(Icons.visibility),
                    ),
                  ),
                  customTextField(
                    title: 'Referral Code',
                    controller: _referral_code,
                    hint: 'Enter your referral code (Optional)',
                    myIcon: const Icon(Icons.abc),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    type: TextInputType.text,
                  ),

                  const SizedBox(height: 20),
                Consumer<AuthenticationProvider>(
                  builder: (context, auth, child) {
                    return customButton(
                      text: 'Create Account',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      tap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isSubmitting = true);

                          final result = await auth.registerUser(
                            fullName: _fullname.text.trim(),
                            userName: _username.text.trim(),
                            phoneNumber: _phone.text.trim(),
                            email: _email.text.trim(),
                            password: _password.text.trim(),
                            referral_code: _referral_code.text.trim(),
                            context: context,
                          );

                          setState(() => _isSubmitting = false);

                          print(result);

                          if (result["success"] == true) {
                            snack_success(
                              message: result["message"],
                              context: context,
                            );
                            PageNavigator(ctx: context).nextPageOnly(
                              page: const LoginPage(),
                            );
                          } else {
                            snack_error(
                              message: result["message"].toString(),
                              context: context,
                            );
                          }
                        }
                      },
                      context: context,
                      status: auth.isLoading,
                    );
                  },
                ),

                const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 16, color: grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          PageNavigator(
                            ctx: context,
                          ).nextPage(page: const LoginPage());
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
