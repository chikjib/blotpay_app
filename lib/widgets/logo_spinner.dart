import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoSpinner extends StatefulWidget {
  final double size;
  final Duration duration;
  final String assetPath;

  const LogoSpinner({
    Key? key,
    this.size = 24.0,
    this.duration = const Duration(seconds: 2),
    this.assetPath = "assets/images/logo_simple.svg",
  }) : super(key: key);

  @override
  State<LogoSpinner> createState() => _LogoSpinnerState();
}

class _LogoSpinnerState extends State<LogoSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true); // makes it zoom in & out

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SvgPicture.asset(
        widget.assetPath,
        height: widget.size,
      ),
    );
  }
}
