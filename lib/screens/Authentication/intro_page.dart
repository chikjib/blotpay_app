import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/screens/DashboardPage/dashboard_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:blotpay/screens/Authentication/login.dart';
import 'package:blotpay/screens/Authentication/register.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../styles/colors.dart';
import '../../utils/routers.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int _currentIndex = 0;

  final List<Map<String, String>> carouselSlides = [
    {
      "image": "assets/images/onboarding-screen1.svg",
      "title": "Send Money & Pay Bills",
      "subtitle": "Enjoy seamless transactions on bill payments and money transfers."
    },
    {
      "image": "assets/images/onboarding-screen2.svg",
      "title": "Convert Airtime to Cash",
      "subtitle": "Easily convert unused airtime to cash directly to your wallet."
    },
    {
      "image": "assets/images/onboarding-screen1.svg",
      "title": "Fast & Secure",
      "subtitle": "Experience fast, reliable, and secure transactions anytime, anywhere."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 150,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carousel
                    CarouselSlider.builder(
                      itemCount: carouselSlides.length,
                      options: CarouselOptions(
                        height: height * 0.55,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        viewportFraction: 1.0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      ),
                      itemBuilder: (context, index, realIndex) {
                        final slide = carouselSlides[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              slide["image"] ?? "",
                              height: height * 0.36,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 24),
                            Text(
                              slide["title"] ?? "",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                slide["subtitle"] ?? "",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),


                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        carouselSlides.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index ? primaryColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  customButton(
                    text: "Join Blotpay",
                    tap: () => PageNavigator(ctx: context).nextPage(page: const RegisterPage()),
                    context: context,
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () => PageNavigator(ctx: context).nextPageOnly(page: const LoginPage()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      "Log in",
                      style: TextStyle(color: black, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}