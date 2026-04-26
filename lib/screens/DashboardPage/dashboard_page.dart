import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../models/User/user_model.dart';
import '../../providers/Database/db_provider.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../providers/TransactionProvider/transaction_provider.dart';
import '../../providers/SlideProvider/slides_provider.dart';
import '../../styles/colors.dart';
import 'dashboard_widgets/quick_actions.dart';
import 'dashboard_widgets/top_bar.dart';
import 'dashboard_widgets/transactions_list.dart';
import 'dashboard_widgets/wallet_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  UserModel? user;
  bool _toggleWalletVisibility = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    final txProvider = context.read<TransactionProvider>();

    // ✅ Load cached immediately
    await txProvider.loadCachedTransactions();

    // ✅ Fetch fresh in background
    txProvider.getTransactions(context: context);

    // ✅ User (load cached first)
    final cachedUser = await DatabaseProvider().getUserDetails();
    if (mounted) setState(() => user = cachedUser);

    final freshUser = await UserProvider().getUser(context: context);
    if (mounted) setState(() => user = freshUser);

    // ✅ Wallet visibility
    final pref = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _toggleWalletVisibility = pref.getBool("VISIBILITY_STATUS") ?? false;
        pref.setBool("biometric_login_enabled", true);
      });
    }
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      // ✅ Refresh transactions
      await context.read<TransactionProvider>().getTransactions(context: context);

      // ✅ Refresh user
      final freshUser = await UserProvider().getUser(context: context);
      if (mounted) setState(() => user = freshUser);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: myLightGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TopBar(user: user),
              const SizedBox(height: 20),
              WalletCard(
                user: user,
                toggleVisibility: _toggleWalletVisibility,
                onToggle: () async {
                  final pref = await SharedPreferences.getInstance();
                  setState(() {
                    _toggleWalletVisibility = !_toggleWalletVisibility;
                    pref.setBool("VISIBILITY_STATUS", _toggleWalletVisibility);
                  });
                },
              ),
              const SizedBox(height: 25),
              const QuickActions(),
              const SizedBox(height: 25),
              // ✅ Now TransactionsList reads directly from Provider
              const TransactionsList(),
            ],
          ),
        ),
      ),
    );
  }
}
