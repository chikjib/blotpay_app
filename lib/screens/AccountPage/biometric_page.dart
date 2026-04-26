import 'package:blotpay/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/AuthProvider/auth_provider.dart';
import 'package:blotpay/utils/snack_message.dart';
import '../ServicesPage/authorize_transaction.dart';
import '../services/secure_auth_service.dart';

class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  bool loginEnabled = false;
  bool transactionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loginEnabled = prefs.getBool("biometric_login_enabled") ?? false;
      transactionsEnabled = prefs.getBool("biometric_tx_enabled") ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void showTransactionPinModal(
      BuildContext context,
      Function(String pin) onSuccess,
      ) {
    errorNotifier.value = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AuthorizeTransactionModal(
        errorNotifier: errorNotifier,
        onPinComplete: (pin) async {
          if (pin.length != 4) {
            errorNotifier.value = "PIN must be 4 digits";
            return;
          }
          // Navigator.pop(context); // close modal
          onSuccess(pin); // return pin back to parent
        },
      ),
    );
  }


  /// Wrapper for fingerprint/face ID auth
  Future<bool> _authenticate(String reason) async {
    try {
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric auth error: $e");
      return false;
    }
  }

  /// Toggle biometric login
  Future<void> _toggleLoginBiometric(BuildContext context, bool enable) async {
    if (enable) {
      if (await _authenticate("Enable biometric login")) {
        final creds = await SecureAuthService.getStoredLoginCredentials();
        if (creds != null) {
          await _setPref("biometric_login_enabled", true);
          setState(() => loginEnabled = true);
          snack_success(message: "Biometric login enabled", context: context);
        } else {
          snack_error(
            message: "No saved login credentials found. Please log in first.",
            context: context,
          );
        }
      }
    } else {
      if (await _authenticate("Disable biometric login")) {
        await _setPref("biometric_login_enabled", false);
        setState(() => loginEnabled = false);
        snack_success(message: "Biometric login disabled", context: context);
      }
    }
  }

  /// Toggle biometric transactions
  Future<void> _toggleTransactionBiometric(
      BuildContext context, bool enable) async {
    final authProvider =
    Provider.of<AuthenticationProvider>(context, listen: false);

    if (enable) {
      // ✅ First check if user has created a transaction PIN on backend
      final hasPin = await authProvider.hasTransactionPin(context: context);
      print(hasPin);
      if (!hasPin) {
        snack_error(
          message: "You must create a transaction PIN before enabling biometrics.",
          context: context,
        );
        return;
      }

      // ✅ Show modal to capture transaction PIN
      showTransactionPinModal(context, (pin) async {
        // Verify entered pin with backend
        final verified = await authProvider.verifyTransactionPin(pin, context: context);
        print(verified);

        if (verified) {
          // Save securely after backend confirms
          await SecureAuthService.saveTransactionPin(pin);
          await _setPref("biometric_tx_enabled", true);

          if (mounted) {
            setState(() => transactionsEnabled = true);
            Navigator.of(context).pop();
            snack_success(message: "Biometric transactions enabled", context: context);
          }
        } else {
          errorNotifier.value = "Invalid transaction PIN";
          // error(message: "Invalid transaction PIN", context: context);
        }
      });
    } else {
      // ✅ Re-authenticate biometrically before disabling
      if (await _authenticate("Disable biometric transactions")) {
        await _setPref("biometric_tx_enabled", false);

        if (mounted) {
          setState(() => transactionsEnabled = false);
          snack_success(message: "Biometric transactions disabled", context: context);
        }
      }
    }
  }


  /// Login with biometrics
  Future<void> _loginWithBiometric(BuildContext context) async {
    if (await _authenticate("Log in with biometrics")) {
      final creds = await SecureAuthService.getStoredLoginCredentials();
      if (creds != null) {
        final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

        final result = await authProvider.loginUser(
          identifier: creds["identifier"]!,
          password: creds["password"]!,
        );

        if (result['success'] == true) {
          snack_success(message: "Logged in successfully", context: context);
        } else {
          snack_error(message: "Biometric login failed", context: context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        title: const Text(
          'Biometrics',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            /// Biometric Login
            SwitchListTile(
              title: const Text("Enable Touch ID / Face ID for Login"),
              value: loginEnabled,
              onChanged: (v) => _toggleLoginBiometric(context, v),
              activeColor: white,
              inactiveThumbColor: primaryColor,
              activeTrackColor: primaryColor,
            ),

            const SizedBox(height: 28),

            /// Biometric Transactions
            SwitchListTile(
              title: const Text("Enable Touch ID / Face ID for Transactions"),
              value: transactionsEnabled,
              onChanged: (v) => _toggleTransactionBiometric(context, v),
              activeColor: white,
              inactiveThumbColor: primaryColor,
              activeTrackColor: primaryColor,
            ),

          ],
        ),
      ),
    );
  }
}
