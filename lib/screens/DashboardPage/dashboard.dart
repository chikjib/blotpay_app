import 'package:blotpay/screens/AccountPage/referral_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blotpay/screens/AccountPage/account_page.dart';
import 'package:blotpay/screens/DashboardPage/dashboard_page.dart';
import 'package:blotpay/screens/TransactionPage/transaction_page.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  List<Widget> _screens() => [
    const DashboardPage(),
    const TransactionPage(),
    // const ReferralPage(),
    const AccountPage(),
  ];
  void onItemTapped(int value) {
    setState(() {
      _currentIndex = value;
    });
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: myLightGrey,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: black,
        systemNavigationBarDividerColor: black,
        systemNavigationBarIconBrightness: Brightness.light
    ));
    final List<Widget> screens = _screens();
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house),
            label: 'Home',
            tooltip: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Transactions',
            tooltip: 'Transactions'
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(LucideIcons.layoutDashboard),
          //   label: 'Referrals',
          //   tooltip: 'Referrals'
          // ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
            tooltip: 'Profile'
          ),
        ],
        currentIndex: _currentIndex,
        showUnselectedLabels: true,
        selectedItemColor: primaryColor,
        unselectedItemColor:  Colors.grey[800],

        onTap: onItemTapped,
        selectedLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: TextStyle(color: black, fontSize: 12),
        // elevation: 2,
        backgroundColor: white,
      ),
    );
  }
}
