import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../DashboardPage/dashboard.dart';

class RequestAccountPage extends StatefulWidget {
  final UserModel? user;
  const RequestAccountPage({super.key, required this.user});

  @override
  State<RequestAccountPage> createState() => _RequestAccountPageState();
}

class _RequestAccountPageState extends State<RequestAccountPage> {
  String? activeBank;
  final TextEditingController accountNameCtrl = TextEditingController();
  final TextEditingController ninCtrl = TextEditingController();
  // final TextEditingController ninCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;



  @override
  void dispose() {

    accountNameCtrl.dispose();
    ninCtrl.dispose();
    super.dispose();
  }

  // ✅ Helper: check if user already has a bank
  bool hasBank(String bankName) {
    switch (bankName.toLowerCase()) {
      case "palmpay":
        _isLoading = false;
        return widget.user?.data?.virtualAccount?.palmpayAccount.isNotEmpty ?? false;
      case "ninepayment":
        _isLoading = false;
        return widget.user?.data?.virtualAccount?.ninepaymentAccount.isNotEmpty ?? false;
      default:
        _isLoading = false;
        return false;
    }
  }



  @override
  Widget build(BuildContext context) {

    final banks = [
      {"key": "ninepayment", "title": "9Payment Service Bank", "logo": "assets/images/ninepayment_bank.svg"},
      {"key": "palmpay", "title": "Palmpay", "logo": "assets/images/palmpay.svg", "recommended": true},
    ];

    return PopScope(
        canPop: !_isSubmitting, // ✅ block back if still loading
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
            if (!_isSubmitting) {
              Navigator.of(context).pop();
            } else {
              debugPrint("Back blocked during submit");
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Request Account Number",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Please select a preferred bank account for your wallet",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Banks
              ...banks.map((bank) {
                final key = bank["key"] as String;
                final title = bank["title"] as String;
                final logo = bank["logo"] as String;
                final recommended = bank["recommended"] == true;

                // Check if user already has this account
                final existingAccount = _getUserBankAccount(key);
                final disabled = hasBank(key);

                return Column(
                  children: [
                    GestureDetector(
                      onTap: disabled
                          ? null
                          : () {
                        setState(() {
                          activeBank = activeBank == key ? null : key;
                          accountNameCtrl.clear();
                          ninCtrl.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: activeBank == key
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                  logo,
                                  width: 32,
                                  height: 32,
                                  colorFilter: disabled ? ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.srcIn,
                                  ) : null
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                    disabled ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ),
                              if (recommended)
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    "Recommended",
                                    style: TextStyle(
                                        color: Colors.teal, fontSize: 12),
                                  ),
                                ),
                              Icon(
                                disabled
                                    ? LucideIcons.circleCheck
                                    : (activeBank == key
                                    ? LucideIcons.circleCheck
                                    : LucideIcons.circle),
                                size: 18,
                                color: disabled
                                    ? Colors.grey
                                    : (activeBank == key
                                    ? primaryColor
                                    : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dropdown Section
                    if (activeBank == key && !disabled)
                      _buildBankForm(context, key),

                    // Show existing account
                    // if (disabled && existingAccount != null)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 12),
                    //     child: Container(
                    //       padding: const EdgeInsets.all(14),
                    //       decoration: BoxDecoration(
                    //         color: Colors.white,
                    //         borderRadius: BorderRadius.circular(12),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: Colors.black.withOpacity(0.05),
                    //             blurRadius: 6,
                    //             offset: const Offset(0, 3),
                    //           ),
                    //         ],
                    //       ),
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Row(
                    //             children: [
                    //               const Icon(Icons.account_circle, size: 22, color: Colors.teal),
                    //               const SizedBox(width: 8),
                    //               Expanded(
                    //                 child: Text(
                    //                   existingAccount.accountName ?? "N/A",
                    //                   style: const TextStyle(
                    //                     fontSize: 16,
                    //                     fontWeight: FontWeight.w600,
                    //                     color: Colors.black87,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //           const Divider(height: 20, thickness: 1, color: Color(0xFFEAEAEA)),
                    //           Row(
                    //             children: [
                    //               const Icon(Icons.credit_card, size: 22, color: Colors.blueGrey),
                    //               const SizedBox(width: 8),
                    //               Text(
                    //                 existingAccount.accountNumber ?? "N/A",
                    //                 style: const TextStyle(
                    //                   fontSize: 15,
                    //                   fontWeight: FontWeight.w500,
                    //                   letterSpacing: 1.2,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    //

                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    )

    );
  }

  /// Simulated: Get user’s existing account for a bank
  Account? _getUserBankAccount(String bank) {
    switch (bank) {
      case "ninepayment":
        return widget.user?.data?.virtualAccount?.ninepaymentAccount.isNotEmpty == true
            ? widget.user!.data!.virtualAccount!.ninepaymentAccount.first
            : null;
      case "palmpay":
        return widget.user?.data?.virtualAccount?.palmpayAccount.isNotEmpty == true
            ? widget.user!.data!.virtualAccount!.palmpayAccount.first
            : null;
      default:
        return null;
    }
  }


  Widget _buildBankForm(BuildContext context, String bank) {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            bank == "ninepayment"
                ? "Charges ₦30 on all deposits"
                : "1.4% per deposit",
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontFamily: 'Roboto'),
          ),
          const SizedBox(height: 12),

          // Account Name Input
          TextField(
            controller: accountNameCtrl,
            decoration: const InputDecoration(
              labelText: "Account Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // NIN Input
          TextField(
            controller: ninCtrl,
            maxLength: 11,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "NIN",
              border: const OutlineInputBorder(),
              errorText: ninCtrl.text.isNotEmpty && ninCtrl.text.length != 11
                  ? "Please enter a valid 11-digit NIN"
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Consumer<UserProvider>(
            builder: (context, provider, child) {
              return customButton(
                text: 'Create Account',
                fontSize: 16,
                tap: (accountNameCtrl.text.isNotEmpty && ninCtrl.text.length == 11)
                    ? () async {
                  if (_isSubmitting) return; // prevent double taps

                  setState(() => _isSubmitting = true);

                  final result = await provider.createVirtualAccount(
                    accountName: accountNameCtrl.text.trim(),
                    bankName: bank,
                    nin: ninCtrl.text.trim(),
                    context: context, // ✅ if provider requires context
                  );

                  if (!mounted) return;
                  setState(() => _isSubmitting = false);

                  // ✅ Handle result directly
                  if (result["success"] == true) {
                    customDialogSuccess(
                      context,
                      result["message"],
                      "Request Account",
                      const Dashboard(),
                    );
                  } else {
                    customDialogError(
                      context,
                      result["message"],
                      "Request Account",
                    );
                  }
                }
                    : null,
                context: context,
                status: provider.status,
              );
            },
          )


        ],
      ),
    );
  }
}
