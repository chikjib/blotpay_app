import 'dart:convert';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/screens/AccountPage/pricing_page.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/currency.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:blotpay/widgets/custom_progress.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../models/User/user_model.dart';
import '../../providers/Database/db_provider.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';

class AccountLevelsPage extends StatefulWidget {
  final UserModel? user; // ✅ Now plain Map

  const AccountLevelsPage({super.key, required this.user});

  @override
  State<AccountLevelsPage> createState() => _AccountLevelsPageState();
}

class _AccountLevelsPageState extends State<AccountLevelsPage> {
  List<dynamic> packages = [];
  bool isLoading = false;

  String requestBaseUrl = AppConstant.baseUrl;

  bool _isCancelled = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    getLevels();
  }

  @override
  void dispose(){
    _isCancelled = true;
    super.dispose();
  }

  /// Convert to sentence case
  String sentenceCase(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Get the next level higher than current user level
  Map<String, dynamic>? getNextLevel() {
    if (packages.isEmpty || widget.user?.data?.userLevel == null) return null;

    final currentLevelTitle = widget.user?.data?.userLevel.toString().toLowerCase();

    // Find index of current level
    final currentIndex = packages.indexWhere(
          (level) => level["title"].toString().toLowerCase() == currentLevelTitle,
    );

    if (currentIndex == -1) return null; // current level not found
    if (currentIndex + 1 >= packages.length) return null; // already at max level

    // Return the next level
    return packages[currentIndex + 1];
  }

  /// Fetch available levels
  Future<void> getLevels() async {
    setState(() => isLoading = true);
    final token = await DatabaseProvider().getToken();
    final headers = {
      "Content-type": "application/json",
      "Authorization": "Bearer $token",
    };
    String url = "$requestBaseUrl/upgrade-user/";

    try {
      http.Response req = await http.get(Uri.parse(url), headers: headers);
      if (req.statusCode == 200) {
        if (_isCancelled) return;

        final data = json.decode(req.body);
        setState(() {
          packages = data["data"]["products"][0]["data"];
          isLoading = false;
        });
      } else {
        if (_isCancelled) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch levels")),
        );
      }
    } catch (e) {
      if (_isCancelled) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextLevel = getNextLevel();
    return PopScope(
        canPop: !isLoading && !_isSubmitting, // ✅ block back if still loading
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
            if (!isLoading && !_isSubmitting) {
              Navigator.of(context).pop();
            } else {
              debugPrint("Back blocked during submit");
            }
          },
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? Center(child: SizedBox())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: const Text(
                "Account Levels",
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 25),

            // Levels List
            Expanded(
              child: ListView.builder(
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final level = packages[index];
                  final isCurrent = level["title"].toString().toLowerCase() ==
                      widget.user?.data?.userLevel?.toString().toLowerCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sentenceCase(level["title"]),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                PageNavigator(ctx: context)
                                    .nextPage(page: const PricingPage());
                              },
                              child: const Text(
                                "See benefits →",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          ],
                        ),
                        Text(
                          formatNaira(double.tryParse(
                              level['amount'].toString()) ??
                              0.0),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: black,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // Upgrade Button
            Consumer<UserProvider>(
              builder: (context, level, child) {
                return customButton(
                  text: nextLevel != null
                      ? "Upgrade to ${sentenceCase(nextLevel['title'])}"
                      : "No higher level",
                  fontSize: 16,
                  tap: () async {
                    if (nextLevel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No higher level available")),
                      );
                      return;
                    }

                    if (_isSubmitting) return; // prevent double taps
                    setState(() => _isSubmitting = true);

                    final result = await level.upgradeUser(
                      userLevel: nextLevel["title"],
                      amount: nextLevel["amount"].toString(),
                      context: context,
                    );

                    if (!mounted) return;
                    setState(() => _isSubmitting = false);

                    // ✅ Handle result directly
                    if (result["success"] == true) {
                      customDialogSuccess(
                        context,
                        result["message"],
                        "Account Upgrade",
                        const Dashboard(),
                      );
                    } else {
                      customDialogError(
                        context,
                        result["message"],
                        "Account Upgrade",
                      );
                    }
                  },
                  context: context,
                  status: level.status,
                );
              },
            )

          ],
        ),
      ),
    )
    );
  }
}
