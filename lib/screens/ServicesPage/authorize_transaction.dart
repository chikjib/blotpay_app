import 'package:blotpay/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/secure_auth_service.dart';

import 'package:blotpay/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_auth_service.dart';

class AuthorizeTransactionModal extends StatefulWidget {
  final Function(String pin) onPinComplete;
  final ValueNotifier<String?> errorNotifier;

  const AuthorizeTransactionModal({
    super.key,
    required this.onPinComplete,
    required this.errorNotifier,
  });

  @override
  State<AuthorizeTransactionModal> createState() =>
      _AuthorizeTransactionModalState();
}

class _AuthorizeTransactionModalState extends State<AuthorizeTransactionModal> with TickerProviderStateMixin{
  String pin = '';
  bool _hasTriggered = false;
  bool biometricEnabled = false;
  bool _isAuthenticating = false;

  late AnimationController _controller;


  // NEW FLAG
  @override
  void initState() {
    super.initState();
    widget.errorNotifier.addListener(_onErrorChange);
    _loadBiometricPreference();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  void _onErrorChange() {
    if (widget.errorNotifier.value != null && mounted) {
      setState(() {
        pin = '';
        _hasTriggered = false;
      });
    }
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      biometricEnabled = prefs.getBool("biometric_tx_enabled") ?? false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.errorNotifier.removeListener(_onErrorChange);
    super.dispose();
  }

  Future<void> _handlePinEntry(
    String enteredPin, {
    bool fromBiometric = false,
  }) async {
    if (_hasTriggered) return;
    setState(() => _hasTriggered = true);
    await widget.onPinComplete(enteredPin);
    if (mounted && !fromBiometric) {
      // 🔹 Only reset if it's manual pin entry
      setState(() {
        _hasTriggered = false;
        if (widget.errorNotifier.value != null) {
          pin = '';
        }
      });
    }
  }

  Future<void> _handleBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final auth = LocalAuthentication();
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: "Authenticate to authorize transaction",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      if (didAuthenticate) {
        final storedPin = await SecureAuthService.getTransactionPin();
        if (storedPin != null && mounted) {
          // 🔹 Pass flag to avoid resetting twice
          await _handlePinEntry(storedPin, fromBiometric: true);
        } else {
          widget.errorNotifier.value = "No stored transaction PIN found";
        }
      }
    } catch (e) {
      widget.errorNotifier.value = "Biometric authentication failed";
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: myLightGrey,
        appBar: AppBar(
          backgroundColor: myLightGrey,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: _hasTriggered ? Colors.grey : Colors.black,
                      size: 30,
                    ),
                    onPressed: _hasTriggered
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.errorNotifier.value = null;
                            _hasTriggered = false;
                          },
                  ),
                  const Text(
                    'Authorize Transaction',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: primaryColor,
                foregroundColor: white,
                child: Icon(FontAwesomeIcons.key, size: 45, color: white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter transaction pin",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Confirm by entering your 4-digit pin",
                style: TextStyle(color: Colors.grey),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: widget.errorNotifier,
                builder: (_, error, __) {
                  return error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    double scale = 1.0;

                    if (_hasTriggered) {
                      // Wave animation
                      final delay = index * 0.2;
                      final value = (_controller.value - delay) % 1;
                      scale = 0.6 + (value * 0.6);
                    }

                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasTriggered
                          ? primaryColor // all filled while loading
                          : index < pin.length
                          ? primaryColor
                          : Colors.transparent,
                      border: Border.all(color: primaryColor),
                    ),
                  ),
                );
              }),
            ),
              const SizedBox(height: 20),

              /// 🔹 Keypad is shrink-wrapped now
              buildKeypad(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildKeypad(Size size) {
    final buttonSize = size.width * 0.15;
    final iconSize = size.width * 0.05;
    final fontSize = size.width * 0.05;
    List<String> keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'back',
      '0',
      'submit',
    ];
    return GridView.builder(
      shrinkWrap: true,
      // ✅ Important
      physics: const NeverScrollableScrollPhysics(),
      // ✅ no inner scroll
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final key = keys[i];
        if (biometricEnabled && key == 'submit') {
          return ElevatedButton(
            onPressed: _hasTriggered ? null : _handleBiometricAuth,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(buttonSize * 0.25),
            ),
            child: Icon(LucideIcons.fingerprint, size: iconSize),
          );
        }
        return SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: ElevatedButton(
            onPressed: _hasTriggered
                ? null
                : () {
                    if (key == 'back') {
                      if (pin.isNotEmpty) {
                        setState(() => pin = pin.substring(0, pin.length - 1));
                      }
                    } else if (key == 'submit') {
                      if (pin.length == 4) _handlePinEntry(pin);
                    } else {
                      if (pin.length < 4) {
                        setState(() => pin += key);
                        if (pin.length == 4) _handlePinEntry(pin);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: key == 'submit'
                  ? primaryColor
                  : Colors.grey[200],
              foregroundColor: key == 'submit' ? Colors.white : Colors.black,
              padding: EdgeInsets.all(buttonSize * 0.25),
            ),
            child: switch (key) {
              'back' => Icon(Icons.arrow_back_outlined, size: iconSize),
              'submit' => Icon(Icons.arrow_forward_outlined, size: iconSize),
              _ => Text(key, style: TextStyle(fontSize: fontSize)),
            },
          ),
        );
      },
    );
  }
}
