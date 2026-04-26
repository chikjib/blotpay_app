import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../styles/colors.dart';
import '../../../models/User/user_model.dart';
import '../../../utils/currency.dart';
import '../../../utils/routers.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../AccountPage/account_levels_page.dart';
import '../fund_page.dart';

class WalletCard extends StatelessWidget {
  final UserModel? user;
  final bool toggleVisibility;
  final VoidCallback onToggle;

  const WalletCard({
    super.key,
    this.user,
    required this.toggleVisibility,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final walletBalance =
        double.tryParse(user?.data?.walletBalance ?? "0.00") ?? 0.00;

    return Container(
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/pattern.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Wallet Balance",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (user == null)
                      const ShimmerLoader(height: 20, width: 100) // 👈 shimmer
                    else
                      toggleVisibility
                          ? Text(
                              formatNaira(walletBalance),
                              style: TextStyle(
                                color: white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto'
                              ),
                            )
                          : Text(
                              "*******",
                              style: TextStyle(
                                color: white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                        toggleVisibility
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _walletAction(
                      context,
                      LucideIcons.plus,
                      "Add Funds",
                      FundWalletPage(user: user),
                    ),
                    const SizedBox(width: 20),
                    _walletAction(
                      context,
                      LucideIcons.arrowUp,
                      "Upgrade",
                      AccountLevelsPage(user: user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletAction(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () => PageNavigator(ctx: context).nextPage(page: page),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: white),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
