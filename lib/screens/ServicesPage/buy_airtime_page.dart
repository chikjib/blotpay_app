import 'dart:convert';

import 'package:blotpay/models/User/beneficiary_model.dart';
import 'package:blotpay/providers/PackageProvider/beneficiary_provider.dart';
import 'package:blotpay/screens/DashboardPage/fund_with_card_page.dart';
import 'package:blotpay/screens/ServicesPage/authorize_transaction.dart';
import 'package:blotpay/screens/ServicesPage/services_widgets/all_beneficiaries.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/providers/PackageProvider/airtime_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/currency.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../models/Package/AirtimeModel.dart';
import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_progress.dart';
import '../DashboardPage/fund_page.dart';

class BuyAirtimePage extends StatefulWidget {
  const BuyAirtimePage({super.key});

  @override
  State<BuyAirtimePage> createState() => _BuyAirtimePageState();
}

class _BuyAirtimePageState extends State<BuyAirtimePage> {
  final _formKey = GlobalKey<FormState>();

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  final validations = Validations();

  Future<AirtimeModel>? airtimePackages;

  TextEditingController _phone = TextEditingController();
  TextEditingController _amount = TextEditingController();

  UserModel? user;

  Future<BeneficiaryModel>? beneficiaries;

  String? wallet_balance;
  double walletBalance = 0.00;
  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;
  bool saveBeneficiary = false;
  List beneficiaryList = [];
  int? beneficiaryClickedIndex;

  double? newAmount;
  double? discount;
  String? discountRate;
  String packageId = "";
  Datum? selectedNetwork;
  bool visibilityStatus = false;
  String error = "";
  final formatter = NumberFormat("#,##0.00");

  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  Future<void> _pickContact() async {
    FocusScope.of(context).unfocus();
    Contact? contact = await _contactPicker.selectPhoneNumber();
    setState(() {
      _phone.text = validations.validateNumber(
        contact!.selectedPhoneNumber.toString(),
      );
    });
  }

  void showPaymentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close Icon
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ),

                const SizedBox(height: 8),

                // Amount
                Text(
                  formatNaira(double.tryParse(_amount.text)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontFamily: 'Roboto',
                  ),
                ),

                const SizedBox(height: 4),

                // Subtext
                Text(
                  "${selectedNetwork?.title} Airtime Purchase",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Recipient Info
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "${selectedNetwork?.image!}",
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        // ✅ smooth
                        placeholderFadeInDuration: Duration.zero,
                        // ✅ no flash
                        placeholder: (_, __) => const SizedBox.shrink(),
                        // ✅ no spinner,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recipient",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _phone.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferred Method Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Preferred Method",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 12),

                // Wallet Option
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.wallet),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Wallet (${formatNaira(double.tryParse(walletBalance.toString()))})",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      double.tryParse(_amount.text)! <= walletBalance
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : GestureDetector(
                              child: Text(
                                "Add Funds",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                PageNavigator(
                                  ctx: context,
                                ).nextPage(page: FundWalletPage(user: user));
                              },
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Debit Card Option
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.creditCard),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Debit Card",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Fund with Card",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        child: Text(
                          "Add Funds",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          PageNavigator(
                            ctx: context,
                          ).nextPage(page: FundWithCardPage(user: user));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.banknoteArrowUp),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bank Transfer",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Fund with Bank Transfer",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        child: Text(
                          "Add Funds",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          PageNavigator(
                            ctx: context,
                          ).nextPage(page: FundWalletPage(user: user));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Proceed Button
                customButton(
                  text: 'Proceed',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  tap: () {
                    if (double.tryParse(_amount.text)! > walletBalance) {
                      return;
                    } else {
                      //Go and enter transaction pin
                      showPinEntryModal(context);
                    }
                  },
                  context: context,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPinEntryModal(BuildContext context) {
    print("airtime pin context $context");
    errorNotifier.value = null; // Reset error when opening
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return PopScope(
          canPop: !_isSubmitting,
          // ✅ block back if still loading
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              debugPrint("Back press blocked while loading...");
            }
          },
          child: AuthorizeTransactionModal(
            onPinComplete: (pin) async {
              print("airtime pin2 context $context");
              setState(() => _isSubmitting = true);

              final airtime = Provider.of<AirtimeProvider>(
                context,
                listen: false,
              );
              final beneficiary = Provider.of<BeneficiaryProvider>(
                context,
                listen: false,
              );

              // 🔥 Call API & get direct result
              final result = await airtime.buyAirtime(
                packageId: packageId,
                phone: _phone.text,
                amount: double.parse(_amount.text),
                transactionPin: pin,
                context: context,
              );

              if (saveBeneficiary) {
                await beneficiary.saveBeneficiary(
                  phoneNo: _phone.text,
                  category: 1,
                  networkType: selectedNetwork!.networkType.toString(),
                  name: _phone.text,
                  context: context,
                );
              }

              if (!mounted) return;

              setState(() => _isSubmitting = false);

              // ✅ Handle API result directly
              if (result["success"] == true) {
                if (context.mounted) {
                  Navigator.pop(context); // Close modal
                  print("close4");

                  customDialogSuccess(
                    context,
                    result["message"],
                    "Airtime Purchase",
                    const Dashboard(),
                  );

                  print("airtime success response");
                  print(result["message"]);
                  sendNotification("Airtime Purchase", result["message"]);
                }
              } else {
                // Error case
                if (result["message"] == "Invalid transaction pin") {
                  // Show inline error without closing modal
                  errorNotifier.value = "Invalid transaction pin";
                } else {
                  print("close1");
                  if (context.mounted) {
                    Navigator.pop(context); // Close modal

                    customDialogError(
                      context,
                      result["message"],
                      "Airtime Purchase",
                    );
                  }
                }
              }
            },
            errorNotifier: errorNotifier,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    airtimePackages = AirtimeProvider().getPackage(1, context: context);
    checkVisibility();

    UserProvider()
        .getUser(context: context)
        .then((data) {
          if (_isCancelled) return;
          user = data;

          setState(() {
            // first_name = user?.data?.firstName ?? "";
            wallet_balance = user?.data?.walletBalance ?? "0.00";
            walletBalance = double.tryParse(wallet_balance!)!;

            _isLoading = false;
          });

          // print(user?.data!.firstName);
        })
        .catchError((error) {
          if (_isCancelled) return; // 👈 ignore error if disposed
          setState(() {
            _isLoading = false;
          });
        });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _isCancelled = true;
    errorNotifier.dispose();
    _phone.dispose();
    _amount.dispose();

    super.dispose();
  }

  checkVisibility() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      visibilityStatus = pref.getBool("VISIBILITY_STATUS") ?? false;
    });
  }

  showDiscount(double amt) {
    setState(() {
      discount = amt - (double.parse(discountRate!) / 100 * amt);
    });
    return discount;
  }

  @override
  Widget build(BuildContext context) {
    print(_isLoading);
    print(_isSubmitting);

    return PopScope(
      canPop: !_isLoading, // ✅ block back if still loading
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
          title: const Text(
            'Buy Airtime',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft600, color: black),
            onPressed: () {
              PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
            },
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16),
            child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<AirtimeModel>(
                    future: airtimePackages,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // show global overlay
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showLoader(context, message: "");
                        });
                      } else {
                        // hide when done
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          hideLoader();
                        });
                      }

                      if (snapshot.hasData && snapshot.data!.data != null) {
                        final List<Datum> networks = snapshot.data!.data!;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: white.withValues(alpha: 0.2),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: networks.map((network) {
                                final isSelected =
                                    selectedNetwork?.id == network.id;

                                // 🔑 Get dynamic sizing
                                double screenWidth = MediaQuery.of(
                                  context,
                                ).size.width;
                                double itemSize =
                                    screenWidth *
                                    0.185; // each item = 20% of screen width

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedNetwork = network;
                                      packageId = network.id.toString();
                                      discountRate =
                                          network.products?.discount
                                              ?.toString() ??
                                          "0";
                                      _amount.text = "";

                                      beneficiaries = BeneficiaryProvider()
                                          .getBeneficiaries(
                                            categoryId: 1,
                                            networkType: selectedNetwork!
                                                .networkType
                                                .toString(),
                                          );
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: itemSize,
                                        height: itemSize,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : myLightGrey,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            child:
                                                network.image != null &&
                                                    network.image!.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: network.image!,
                                                    fit: BoxFit.contain,
                                                    fadeInDuration:
                                                        const Duration(
                                                          milliseconds: 200,
                                                        ),
                                                    placeholderFadeInDuration:
                                                        Duration.zero,
                                                    placeholder: (_, __) =>
                                                        const SizedBox.shrink(),
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 24,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.image_not_supported,
                                                    size: 24,
                                                  ),
                                          ),
                                        ),
                                      ),

                                      // ✅ Checkmark circle
                                      if (isSelected)
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Error Occurred"));
                      } else {
                        return const Center(child: Text("No provider found"));
                      }
                    },
                  ),

                  /// ================= BENEFICIARY LIST =================
                  FutureBuilder<BeneficiaryModel>(
                    future: beneficiaries,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.data!.isEmpty) {
                        return const SizedBox();
                      }

                      final list = snapshot.data!.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Beneficiaries",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// BENEFICIARY LIST
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: list.isNotEmpty
                                  ? (list.length > 3 ? 4 : list.length + 1)
                                  : 0,
                              itemBuilder: (context, index) {
                                final maxVisible = list.length > 3 ? 3 : list.length;

                                /// SEE ALL (always last)
                                if (index == maxVisible) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final selected = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AllBeneficiariesPage(categoryId: 1),
                                        ),
                                      );

                                      if (selected != null) {
                                        setState(() {
                                          _phone.text = selected.phoneNo ?? "";
                                          beneficiaryClickedIndex = null;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 55,
                                            height: 55,
                                            decoration: const BoxDecoration(
                                              color: Color(0xffc6daf5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.more_horiz,
                                              size: 26,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "See All",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                /// BENEFICIARY ITEM
                                if (index < list.length) {
                                  final beneficiary = list[index];

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _phone.text = beneficiary.phoneNo ?? "";
                                        beneficiaryClickedIndex = index;
                                      });
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 55,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              color: beneficiaryClickedIndex == index ? Colors.blue.shade200: Colors.grey.shade200,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.sentiment_satisfied,
                                              size: 26,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            user?.data?.phoneNo == beneficiary.phoneNo ? "My Number" : beneficiary.name.toString(),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }



                                return const SizedBox();
                              },
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  customTextField(
                    title: "Phone Number",
                    hint: "Enter phone number",
                    controller: _phone,
                    type: TextInputType.phone,
                    myIcon: const Icon(Icons.phone),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        validations.validatePhone(value, "Phone Number"),
                    suffixIcon: IconButton(
                      onPressed: _pickContact,
                      icon: Icon(
                        LucideIcons.idCard,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  customTextField(
                    title: "Amount",
                    hint: "Enter amount",
                    controller: _amount,
                    type: TextInputType.number,
                    myIcon: const Icon(Icons.money),
                    walletShow: true,
                    walletBalance: !visibilityStatus
                        ? "*****"
                        : formatNaira(
                            double.tryParse(walletBalance.toString()),
                          ),
                    autoValidate: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                        validations.validateAmount(value, "amount"),
                    onChanged: ((value) {
                      if (value != "") {
                        showDiscount(double.parse(value!));
                      }
                    }),
                  ),

                  if (discount != null)
                    Text(
                      "You will be charged: ${formatNaira(discount!)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            saveBeneficiary = !saveBeneficiary;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36,
                          height: 20,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Align(
                            alignment: saveBeneficiary
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: saveBeneficiary
                                    ? primaryColor
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Save Beneficiary",
                        style: TextStyle(
                          color: black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () {
                      if (selectedNetwork == null) {
                        snack_error(
                          message: "Please select a network provider",
                          context: context,
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        errorNotifier.value = null;
                        showPaymentBottomSheet(context);
                      }
                    },
                    context: context,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
