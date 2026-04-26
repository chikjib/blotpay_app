import 'package:blotpay/screens/Authentication/login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
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
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/User/user_model.dart';
import '../../providers/Database/db_provider.dart';
import '../services/secure_auth_service.dart';

class WelcomeLogin extends StatefulWidget {
  const WelcomeLogin({super.key});

  @override
  State<WelcomeLogin> createState() => _WelcomeLoginState();
}

class _WelcomeLoginState extends State<WelcomeLogin> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late final LocalAuthentication auth;
  bool _supportState = false;
  bool _obscure = true;
  bool _isLoading = false;

  String biometricText = "";

  bool loginEnabled = false;

  UserModel? user;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then((bool isSupported) {
      setState(() => _supportState = isSupported);
    });
    _loadDetails();
    _loadPrefs();
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _loadDetails() async {
    final db = DatabaseProvider();

    // 1. Load cached user + transactions
    final cachedUser = await db.getUserDetails();

    if (mounted) {
      setState(() {
        user = cachedUser;
        _identifier.text = user?.data?.username ?? "";
        profileImageUrl = user?.data?.profilePicture.toString() ?? "";
      });
    }
  }

  Future<ImageProvider> loadFixedNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        // Decode with orientation fix
        final image = img.decodeImage(bytes);
        if (image != null) {
          final fixedBytes = img.encodeJpg(image);
          return MemoryImage(Uint8List.fromList(fixedBytes));
        }
      }
    } catch (e) {
      debugPrint("Image load error: $e");
    }
    return const AssetImage('assets/images/default_image.png');
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loginEnabled = prefs.getBool("biometric_login_enabled") ?? false;
    });
  }

  String sentenceCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
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
    final result = await authProvider.loginUser(
      identifier: identifier.trim(),
      password: password.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // ✅ Save for biometric login later (only on normal login)
      // if (!biometric) {
      //   await SecureAuthService.saveLoginCredentials(identifier, password);
      // }

      // success(message: result['message'], context: context);
      PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
    } else {
      if (biometric) {
        final msg = (result['message'] ?? "").toString().toLowerCase();

        // Only clear if it's really bad credentials, not network issues
        if (msg.contains("invalid") || msg.contains("incorrect")) {
          await SecureAuthService.clearAll();
        }
      }

      snack_error(message: result['message'], context: context);
    }
  }

  Future<void> _fingerPrintLogin() async {
    try {
      // 1. Ask for biometric authentication
      bool didAuthenticate = await auth.authenticate(
        localizedReason: "Please authenticate to login securely",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        setState(() {
          biometricText = "Biometric authentication failed or cancelled.";
        });
        return;
      }

      // 2. Retrieve saved credentials (no extra biometric inside SecureAuthService)
      final creds = await SecureAuthService.getStoredLoginCredentials();
      print("credentials");
      print(creds);
      if (creds != null) {
        await _loginUser(
          context,
          creds['identifier']!,
          creds['password']!,
          biometric: true,
        );
      } else {
        setState(() {
          biometricText =
              "Biometric login not set up yet. Please log in normally first.";
        });
      }
    } on PlatformException catch (e) {
      print("Biometric error: $e");
      setState(() {
        biometricText = "Biometric authentication error: ${e.message}";
      });
    }
  }

  void _openFreshchat() async {
    Freshchat.showConversations();
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

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top red header with logo
            Container(
              height: size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, primaryColor],
                ),
                image: const DecorationImage(
                  image: AssetImage("assets/images/pattern2.png"),
                  repeat: ImageRepeat.noRepeat, // tile the pattern
                  opacity: 0.1, // make it subtle
                  fit: BoxFit.cover
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 250,
                      child: SvgPicture.asset(
                        "assets/images/logo.svg",
                        width: 250,
                        height: 150,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 80, // set your preferred size
                          height: 80,
                          child: ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                (profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty &&
                                    profileImageUrl != "null"
                                    ? FutureBuilder<ImageProvider>(
                                  future: loadFixedNetworkImage(profileImageUrl!), // ✅ orientation fix
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting ||
                                        snapshot.hasError ||
                                        !snapshot.hasData) {
                                      // ✅ placeholder instead of spinner
                                      return Image.asset(
                                        'assets/images/default_image.png',
                                        fit: BoxFit.contain,
                                      );
                                    }
                                    return Image(
                                      image: snapshot.data!,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                )
                                    : Image.asset(
                                  'assets/images/default_image.png',
                                  fit: BoxFit.contain,
                                )),

                                // ✅ Dimming overlay
                                Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Welcome Back, ${toSentenceCase(user?.data?.fullName?.split(" ").last ?? "")}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  customTextField(
                    title: 'Password',
                    controller: _password,
                    hint: '******',
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
                    alignment: Alignment.topLeft,
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

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        fit: FlexFit.tight,
                        // or loose if you want button smaller
                        child: Consumer<AuthenticationProvider>(
                          builder: (context, auth, child) {
                            return customButton(
                              text: 'Log In',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              tap: () {
                                if (_identifier.text.isEmpty ||
                                    _password.text.isEmpty) {
                                  snack_error(
                                    message: "All fields are required!",
                                    context: context,
                                  );
                                } else {
                                  _loginUser(
                                    context,
                                    _identifier.text,
                                    _password.text,
                                  );
                                }
                              },
                              context: context,
                              status: _isLoading || auth.isLoading,
                            );
                          },
                        ),
                      ),

                      if (_supportState && loginEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _fingerPrintLogin,
                              icon: Icon(
                                Icons.fingerprint,
                                color: white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not  ${sentenceCase(user?.data?.username ?? "")}? ",
                        style: TextStyle(fontSize: 16, color: black),
                      ),
                      GestureDetector(
                        onTap: () {
                          PageNavigator(
                            ctx: context,
                          ).nextPageOnly(page: const LoginPage());
                        },
                        child: Text(
                          'Switch Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30,),
                  GestureDetector(
                    onTap: _openFreshchat,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.chat_bubble),
                        const SizedBox(width: 8,),
                        Text("Live Chat", style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: black,
                        ),)

                      ],
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
