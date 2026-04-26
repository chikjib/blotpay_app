import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/ReferralProvider/referral_provider.dart';
import '../../utils/currency.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';

class ReferralPage extends StatefulWidget {
  final UserModel? user;

  const ReferralPage({super.key, required this.user});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String referralCode = "";
  String referralEarnings = "";
  String referralCount = "";

  @override
  void initState() {
    super.initState();
    referralCode = widget.user!.data!.username.toString();
    referralEarnings = widget.user!.data!.referralEarnings.toString();
    referralCount = widget.user!.data!.referralCount.toString();
  }

  String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _openGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Referral guidelines",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                  "1. You are required to complete all account verification steps."),
              const SizedBox(height: 10),
              const Text(
                  "2. Make sure to keep your account active by using it to transact frequently"),
              const SizedBox(height: 10),
              const Text(
                  "3. You can cash out your earnings to your wallet when it accumulates to a total sum of ₦5,000.00 and above.", style: TextStyle(fontFamily: 'Roboto'),),
              const SizedBox(height: 10),
              const Text(
                  "4. Fraudulent referrals or misuse of the program may result in disqualification and removal of rewards."),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                  ),
                  child: const Text(
                    "Okay, Got it",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _shareInvite() {
    Share.share(
      "Download Blotpay mobile app to buy cheap data, airtime and convert airtime to cash.\n"
          "Download link: https://blotpay.com/app?os=android\n"
          "You can earn using my referral code: ${toSentenceCase(referralCode)}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text("Refer & Earn",
            style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      /// MAIN LAYOUT
      body: Column(
        children: [
          /// SCROLLABLE TOP
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),

                Icon(Icons.campaign, size: 150, color: primaryColor),

                const SizedBox(height: 20),

                const Text(
                  "Earn extra bonus with every referral",
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Earn up to ₦500 for each friend you refer. The referred friend must complete an order valued at over ₦2,000 for the bonus to be credited.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontFamily: 'Roboto'),
                ),

                const SizedBox(height: 25),

                /// REFERRAL CODE BOX
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Copy your referral code",
                            style: TextStyle(
                                color: grey,
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                toSentenceCase(
                                    referralCode),
                                style: const TextStyle(
                                    fontWeight:
                                    FontWeight.w500,
                                    fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Copied to clipboard")),
                                  );
                                },
                                child: Icon(
                                  Icons.copy,
                                  size: 18,
                                  color: primaryColor,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),

                      /// RECTANGULAR BUTTON
                      ElevatedButton(
                        onPressed: _shareInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.white,
                          shape:
                          const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          "Invite a friend",
                          style:
                          TextStyle(color: primaryColor),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                /// GUIDELINES BUTTON
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10)),
                  title:
                  const Text("Referral guidelines"),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16),
                  onTap: () =>
                      _openGuidelines(context),
                ),
              ],
            ),
          ),

          /// FIXED BOTTOM SECTION
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 20.0, top: 20.0),
            child: Column(
              children: [
                ListTile(
                  tileColor: Colors.white,
                  leading:
                  Icon(LucideIcons.users300),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10)),
                  title:
                  const Text("My Referrals", style: TextStyle(fontWeight: FontWeight.w500),),
                  trailing: Text(referralCount, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
                ),
                const SizedBox(height: 15),
                Container(
                  padding:
                  const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                        10),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Referral Earnings", style: TextStyle(color: grey, fontSize: 15),),
                          const SizedBox(height: 10,),
                          Text(
                            formatNaira(double.tryParse(referralEarnings)),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold, fontFamily: 'Roboto'),
                          ),
                        ],
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: Consumer<ReferralProvider>(
                          builder: (context, cashout, child) {
                            return customButton(
                              text: 'Cash Out',
                              fontSize: 16,
                              tap: () async {
                                double earnings =
                                    double.tryParse(referralEarnings) ?? 0;

                                /// 🔥 Prevent cash out below ₦5,000
                                if (earnings < 5000) {
                                  customDialogError(
                                    context,
                                    "Minimum cash out amount is ₦5,000",
                                    "Referral Cash Out",
                                  );
                                  return;
                                }

                                final result = await cashout.cashOutReferral(
                                  context: context,
                                );

                                if (!mounted) return;

                                if (result["success"] == true) {
                                  setState(() {
                                    referralEarnings = "0";
                                  });

                                  customDialogSuccess(
                                    context,
                                    result["message"],
                                    "Referral Cash Out",
                                    const Dashboard(), // or Dashboard() if you want redirect
                                  );
                                } else {
                                  customDialogError(
                                    context,
                                    result["message"],
                                    "Referral Cash Out",
                                  );
                                }
                              },
                              context: context,
                              status: cashout.status,
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
