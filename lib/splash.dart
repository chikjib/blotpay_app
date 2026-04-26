import 'package:blotpay/screens/Authentication/welcome_login.dart';
import 'package:blotpay/screens/services/secure_auth_service.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:blotpay/screens/Authentication/intro_page.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // longer cycle for smoothness
    )..repeat();

    // Scale between 0.9x and 1.1x
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Cycle through multiple colors
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(begin: primaryColor, end: black),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(begin: black, end: primaryColor),
          weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final size = MediaQuery.of(context).size; // get screen size

            return ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                "assets/images/splash_logo.png",
                width: size.width * 0.6,   // 60% of screen width
                height: size.height * 0.20, // 20% of screen height
                fit: BoxFit.contain, // ensures it scales proportionally
              ),
            );
          },
        ),
      ),
    );
  }

  void navigate() async {
    final creds = await SecureAuthService.getStoredLoginCredentials();

    Future.delayed(const Duration(seconds: 3), () {
      if (creds != null) {
        PageNavigator(ctx: context).nextPageOnly(page: const WelcomeLogin());
      } else {
        PageNavigator(ctx: context).nextPageOnly(page: const IntroPage());
      }
    });
  }
}
