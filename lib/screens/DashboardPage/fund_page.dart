import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/screens/AccountPage/request_account_page.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/screens/DashboardPage/fund_with_card_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../styles/colors.dart';
import '../../utils/routers.dart';

class FundWalletPage extends StatefulWidget {
  final UserModel? user;

  const FundWalletPage({super.key, required this.user});

  @override
  State<FundWalletPage> createState() => _FundWalletPageState();
}

class _FundWalletPageState extends State<FundWalletPage> {
  Account? palmpay;
  // Account? moniepoint;
  // Account? wema;
  Account? ninepayment;

  void _initializeAccounts() {
    final virtual = widget.user?.data?.virtualAccount;

    if (virtual != null) {
      if (virtual.palmpayAccount.isNotEmpty) {
        palmpay = virtual.palmpayAccount.first;
      }
      if (virtual.ninepaymentAccount.isNotEmpty) {
        ninepayment = virtual.ninepaymentAccount.first;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAccounts();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Fund Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: black),
          onPressed: () => PageNavigator(ctx: context).nextPageOnly(page: const Dashboard()),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            /// Card Funding
            _buildOptionCard(
              icon: Icons.rocket_launch_outlined,
              title: "Request Account Number",
              subtitle: "Request an account number",
              onTap: () => PageNavigator(ctx: context)
                  .nextPage(page: RequestAccountPage(user: widget.user)),
            ),

            const SizedBox(height: 24),

            _buildOptionCard(
              icon: Icons.credit_card,
              title: "Card",
              subtitle: "Fund with your debit card",
              onTap: () => PageNavigator(ctx: context)
                  .nextPage(page: FundWithCardPage(user: widget.user)),
            ),

            const SizedBox(height: 24),

            /// Divider
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1, color: Colors.black26)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Or", style: TextStyle(color: black.withOpacity(0.5))),
                ),
                const Expanded(child: Divider(thickness: 1, color: Colors.black26)),
              ],
            ),

            const SizedBox(height: 24),

            /// Wallet Account Section
            const Text(
              "Wallet Account",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              "Make transfer to the below account",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),

            if (palmpay != null)
              _buildBankTile(
                  palmpay!.accountNumber ?? "",
                  palmpay!.accountName ?? "",
                  "Palmpay"),

            // if (moniepoint != null) ...[
            //   const SizedBox(height: 12),
            //   _buildBankTile(
            //       moniepoint!.accountNumber ?? "",
            //       moniepoint!.accountName ?? "",
            //       "Moniepoint MFB"),
            // ],
            // if (wema != null) ...[
            //   const SizedBox(height: 12),
            //   _buildBankTile(
            //       wema!.accountNumber ?? "",
            //       wema!.accountName ?? "",
            //       "Wema Bank"),
            // ],
            if (ninepayment != null) ...[
              const SizedBox(height: 12),
              _buildBankTile(
                  ninepayment!.accountNumber ?? "",
                  ninepayment!.accountName ?? "",
                  "9Payment Service Bank"),
            ],

            const SizedBox(height: 20),

            /// Request Alternative Account
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Need alternative account? ",
                      style: TextStyle(color: primaryColor, fontSize: 14),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: () {
                          PageNavigator(ctx: context).nextPage(
                            page: RequestAccountPage(user: widget.user),
                          );
                        },
                        child: Text(
                          "Request",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Funding Option Card
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                  ),
                  child: Icon(icon, size: 28, color: black),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(color: grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // adjust to how many lines you want
                    softWrap: true,
                  )

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bank Tile
  Widget _buildBankTile(String accountNumber, String accountName, String bank) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                accountNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.copy, color: Colors.black54, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard")),
                  );
                },
              ),
            ],
          ),
          Text(accountName,
              style: const TextStyle(color: Colors.black87, fontSize: 14)),
          Text(bank, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}
