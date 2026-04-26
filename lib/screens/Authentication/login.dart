import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/AuthProvider/auth_provider.dart';
import 'package:blotpay/screens/Authentication/forgot_password.dart';
import 'package:blotpay/screens/Authentication/register.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_text_field.dart';
import 'package:local_auth/local_auth.dart';

import '../../models/User/user_model.dart';
import '../../providers/Database/db_provider.dart';
import '../services/secure_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  // late final LocalAuthentication auth;
  bool _supportState = false;
  bool _obscure = true;
  bool _isLoading = false;
  bool _isSubmitting = false;
  UserModel? user;
  // String biometricText = "";



  @override
  void initState() {
    super.initState();
    // auth = LocalAuthentication();
    // auth.isDeviceSupported().then((bool isSupported) {
    //   setState(() => _supportState = isSupported);
    // });

    _loadDetails();

  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final db = DatabaseProvider();

    // 1. Load cached user + transactions
    final cachedUser = await db.getUserDetails();

    if (mounted) {
      setState(() {
        user = cachedUser;
        _identifier.text = user?.data?.username ?? "";
      });
    }
  }

  Future<void> _loginUser(
    BuildContext context,
    String identifier,
    String password, {
    bool biometric = false,
  }) async {
    setState(() => _isLoading = true);


    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );

    await DatabaseProvider().switchUser(); //Switch User first

    final result = await authProvider.loginUser(
      identifier: identifier.trim(),
      password: password.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // ✅ Save for biometric login later (only on normal login)
      if (!biometric) {
        debugPrint("biometric set");
        await SecureAuthService.saveLoginCredentials(identifier, password);
      }
      if (!mounted) return; // <- ensure widget is still alive before navigation

      // success(message: result['message'], context: context);
      PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
    } else {
      if (biometric) {
        // If biometric auto-login fails, clear stored credentials
        await SecureAuthService.clearAll();
      }
      if (!mounted) return; // <- ensure widget is still alive before navigation

      snack_error(message: result['message'], context: context);
    }
  }

  // Future<void> _fingerPrintLogin() async {
  //   try {
  //     // 1. Ask for biometric authentication
  //     bool didAuthenticate = await auth.authenticate(
  //       localizedReason: "Please authenticate to login securely",
  //       options: const AuthenticationOptions(
  //         biometricOnly: true,
  //         stickyAuth: true,
  //         useErrorDialogs: true,
  //       ),
  //     );
  //
  //     if (!didAuthenticate) {
  //       setState(() {
  //         biometricText = "Biometric authentication failed or cancelled.";
  //       });
  //       return;
  //     }
  //
  //     // 2. Retrieve saved credentials (no extra biometric inside SecureAuthService)
  //     final creds = await SecureAuthService.getStoredLoginCredentials();
  //
  //     if (creds != null) {
  //       await _loginUser(
  //         context,
  //         creds['identifier']!,
  //         creds['password']!,
  //         biometric: true,
  //       );
  //     } else {
  //       setState(() {
  //         biometricText =
  //             "Biometric login not set up yet. Please log in normally first.";
  //       });
  //     }
  //   } on PlatformException catch (e) {
  //     print("Biometric error: $e");
  //     setState(() {
  //       biometricText = "Biometric authentication error: ${e.message}";
  //     });
  //   }
  // }

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
        // leading: IconButton(
        //   icon: Icon(LucideIcons.chevronLeft, color: black),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: grey,
                  ),
                ),
                const SizedBox(height: 60),

                customTextField(
                  title: 'Email Address or Username',
                  controller: _identifier,
                  hint: 'Enter your email address or username',
                  type: TextInputType.text,
                  myIcon: const Icon(Icons.person_outlined, size: 30),
                ),

                customTextField(
                  title: 'Password',
                  controller: _password,
                  hint: 'Enter your secured password',
                  obscure: _obscure,
                  myIcon: const Icon(Icons.password, size: 30),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 30,
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      PageNavigator(
                        ctx: context,
                      ).nextPage(page: const ForgotPasswordPage());
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

              Consumer<AuthenticationProvider>(
                builder: (context, auth, child) {
                  return customButton(
                    text: 'Log In',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    tap: () async {
                      if (_isSubmitting) return; // ✅ prevent double taps

                      if (_identifier.text.isEmpty || _password.text.isEmpty) {
                        snack_error(
                          message: "All fields are required!",
                          context: context,
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      await _loginUser( context, _identifier.text, _password.text, );

                      if (!mounted) return;
                      setState(() => _isSubmitting = false);

                    },
                    context: context,
                    status: _isLoading || auth.isLoading,
                  );
                },
              ),


              const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 16, color: grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        PageNavigator(
                          ctx: context,
                        ).nextPage(page: const RegisterPage());
                      },
                      child: const Text(
                        'Create Account',
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
    )
    );
  }
}
