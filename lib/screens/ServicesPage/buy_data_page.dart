import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/providers/UserProvider/user_provider.dart';
import 'package:blotpay/screens/ServicesPage/services_widgets/all_beneficiaries.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' show LucideIcons;
import 'package:provider/provider.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/models/Package/DataModel.dart';
import 'package:blotpay/providers/PackageProvider/data_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

import '../../models/User/beneficiary_model.dart';
import '../../providers/PackageProvider/beneficiary_provider.dart';
import '../../styles/colors.dart';
import '../../utils/currency.dart';
import '../../utils/routers.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_progress.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';

import '../DashboardPage/fund_page.dart';
import '../DashboardPage/fund_with_card_page.dart';
import 'authorize_transaction.dart';

class BuyDataPage extends StatefulWidget {
  const BuyDataPage({super.key});

  @override
  State<BuyDataPage> createState() => _BuyDataPageState();
}

class _BuyDataPageState extends State<BuyDataPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  final validations = Validations();

  // String initialValue = "Select Provider";
  // List<String>packages = [];
  String dropDownValue = "Select a Package";
  String planTitle = "Select a Plan";
  int? packageId;

  Future<DataModel>? dataPackages;
  List<Datum> allPackages = [];

  Future<BeneficiaryModel>? beneficiaries;


  Datum? selectedNetwork;
  String? networkType;
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  List filteredPackages = [];
  List filteredPlans = [];

  Datum? selectedService;
  List<Product>? content;
  String? description;

  TextEditingController _phone = TextEditingController();
  TextEditingController _amount = TextEditingController();

  double? planAmount;
  String? variationCode;

  bool isLoading = false;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;
  bool saveBeneficiary = false;
  List beneficiaryList = [];
  int? beneficiaryClickedIndex;
  UserModel? user;

  String? wallet_balance;
  double walletBalance = 0.00;

  Future<void> _pickContact() async {
    FocusScope.of(context).unfocus();
    Contact? contact = await _contactPicker.selectPhoneNumber();
    setState(() {
      _phone.text = validations.validateNumber(
        contact!.selectedPhoneNumber.toString(),
      );
    });
  }

  List<Datum> getUniqueNetworks(List<Datum> packages) {
    final Map<String, Datum> networkMap = {};

    for (var pkg in packages) {
      if (pkg.networkType != null &&
          pkg.image != null &&
          pkg.image!.isNotEmpty) {
        if (!networkMap.containsKey(pkg.networkType)) {
          networkMap[pkg.networkType!] = pkg;
        }
      }
    }

    return networkMap.values.toList();
  }

  List<Datum> filterPackagesByNetwork(
    List<Datum> packages,
    String? selectedNetwork,
  ) {
    return packages
        .where((service) => service.networkType == selectedNetwork)
        .toList();
  }

  void getServiceDetails(List<Datum> packages, int? packageId) {
    selectedService = packages.firstWhere(
      (service) => service.id == packageId,
      orElse: () => Datum(), // return empty Datum if not found
    );

    if (selectedService != null) {
      content = selectedService!.products;
      description = selectedService!.description;
    }
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
                  "$dropDownValue $planTitle",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
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
                          style: TextStyle(fontSize: 14, color: Colors.grey),
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
    errorNotifier.value = null; // Reset error when opening
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
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
          child:
          AuthorizeTransactionModal(
            onPinComplete: (pin) async {
              setState(() => _isSubmitting = true);

              final data = Provider.of<DataProvider>(context, listen: false);
              final beneficiary = Provider.of<BeneficiaryProvider>(
                context,
                listen: false,
              );
              // 🔥 Call API & get direct result
              final result = await data.buyData(
                packageId: packageId.toString(),
                variationCode: variationCode.toString(),
                phone: _phone.text,
                transactionPin: pin,
                context: context,
              );

              if (saveBeneficiary) {
                await beneficiary.saveBeneficiary(
                  phoneNo: _phone.text,
                  category: 2,
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
                  Navigator.pop(context); // Close modal first
                  customDialogSuccess(
                    context,
                    result["message"],
                    "Data Purchase",
                    const Dashboard(),
                  );

                  print("data success response: ${result["message"]}");
                  sendNotification("Data Purchase", result["message"]);
                }
              } else {
                // Error case
                if (result["message"] == "Invalid transaction pin") {
                  // Show inline error without closing modal
                  errorNotifier.value = "Invalid transaction pin";
                } else {
                  if (context.mounted) {
                    Navigator.pop(context); // Close modal
                    customDialogError(
                      context,
                      result["message"],
                      "Data Purchase",
                    );
                  }
                }
              }
            },
            errorNotifier: errorNotifier,
          )

        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dataPackages = DataProvider().getPackage(2, context: context);

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
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            'Buy Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft600, color: black),
            onPressed: () {
              if (!_isLoading) {
                PageNavigator(
                  ctx: context,
                ).nextPageOnly(page: const Dashboard());
              } else {
                debugPrint("Back blocked during request");
              }
            },
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder(
                    future: dataPackages,
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
                        allPackages = snapshot.data!.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select network provider",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
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
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth = constraints.maxWidth;

                                  // 🔹 Dynamic sizes based on screen width
                                  final circleSize =
                                      screenWidth *
                                      0.215; // 20% of screen width
                                  final imageSize =
                                      circleSize * 0.75; // 75% of circle

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: getUniqueNetworks(snapshot.data!.data!).map((
                                        network,
                                      ) {
                                        final isSelected =
                                            selectedNetwork?.networkType ==
                                            network.networkType;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedNetwork = network;
                                              networkType = network.networkType
                                                  .toString();
                                              dropDownValue =
                                                  "Select a Package";
                                              planTitle = "Select a Plan";
                                              content = [];
                                              filteredPackages =
                                                  filterPackagesByNetwork(
                                                    allPackages,
                                                    selectedNetwork
                                                        ?.networkType,
                                                  );
                                              _amount.text = "";

                                              beneficiaries = BeneficiaryProvider()
                                                  .getBeneficiaries(
                                                categoryId: 2,
                                                networkType: selectedNetwork!
                                                    .networkType
                                                    .toString(),
                                              );
                                            });
                                          },
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: circleSize,
                                                height: circleSize,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        circleSize / 2,
                                                      ),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? primaryColor
                                                        : myLightGrey,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    if (network.image != null &&
                                                        network
                                                            .image!
                                                            .isNotEmpty)
                                                      SizedBox(
                                                        width: imageSize,
                                                        height: imageSize,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                imageSize / 2,
                                                              ),
                                                          child: CachedNetworkImage(
                                                            imageUrl:
                                                                network.image!,
                                                            fit: BoxFit.contain,
                                                            fadeInDuration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      200,
                                                                ),
                                                            placeholderFadeInDuration:
                                                                Duration.zero,
                                                            placeholder: (_, __) =>
                                                                const SizedBox.shrink(),
                                                            errorWidget:
                                                                (
                                                                  context,
                                                                  url,
                                                                  error,
                                                                ) => const Icon(
                                                                  Icons
                                                                      .image_not_supported,
                                                                  size: 24,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // ✅ Checkmark circle (scaled too)
                                              if (isSelected)
                                                Positioned(
                                                  top: circleSize * 0.12,
                                                  left: circleSize * 0.12,
                                                  child: Container(
                                                    width: circleSize * 0.22,
                                                    height: circleSize * 0.22,
                                                    decoration: BoxDecoration(
                                                      color: primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: circleSize * 0.14,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Error Occurred"));
                      } else {
                        return const Center(child: Text("No provider found"));
                      }
                    },
                  ),
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
                                          builder: (_) => const AllBeneficiariesPage(categoryId: 2),
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
                  isLoading
                      ? customProgress(20, 20)
                      : Column(
                          children: [
                            const SizedBox(height: 15),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select Package",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: primaryColor,
                                    width: 2.0,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: IgnorePointer(
                                ignoring: filteredPackages.isEmpty,
                                // 👈 disables tap if no packages
                                child: Opacity(
                                  opacity: filteredPackages.isEmpty ? 0.5 : 1.0,
                                  // 👈 visual feedback
                                  child: InkWell(
                                    onTap: () {
                                      if (filteredPackages.isEmpty)
                                        return; // 👈 extra safety check

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        isDismissible: true,
                                        enableDrag: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (BuildContext context) {
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => Navigator.pop(context),
                                            child: DraggableScrollableSheet(
                                              initialChildSize: 0.5,
                                              // 👈 50% of screen height
                                              minChildSize: 0.5,
                                              // 👈 prevent shrinking
                                              maxChildSize: 0.5,
                                              builder: (context, scrollController) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              "Select Package",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Divider(height: 1),
                                                      Expanded(
                                                        child: ListView.builder(
                                                          controller:
                                                              scrollController,
                                                          itemCount:
                                                              filteredPackages
                                                                  .length,
                                                          itemBuilder: (context, index) {
                                                            final item =
                                                                filteredPackages[index];
                                                            return ListTile(
                                                              title: Text(
                                                                item.title,
                                                              ),
                                                              onTap: () {
                                                                setState(() {
                                                                  planTitle =
                                                                      "Select a Plan";
                                                                  _amount.text =
                                                                      "";
                                                                  dropDownValue =
                                                                      item.title;
                                                                  packageId =
                                                                      item.id;
                                                                  getServiceDetails(
                                                                    allPackages,
                                                                    packageId,
                                                                  );
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(dropDownValue),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 30,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select Plan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: primaryColor,
                                    width: 2.0,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: IgnorePointer(
                                ignoring: content?.isEmpty ?? true,
                                // 👈 disables tap if empty
                                child: Opacity(
                                  opacity: content?.isEmpty ?? true ? 0.5 : 1.0,
                                  // 👈 visual feedback
                                  child: InkWell(
                                    onTap: () {
                                      if (content?.isEmpty ?? true) return;

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        isDismissible: true,
                                        enableDrag: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (BuildContext context) {
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => Navigator.pop(context),
                                            child: DraggableScrollableSheet(
                                              initialChildSize: 0.5,
                                              // 👈 50% of screen height
                                              minChildSize: 0.5,
                                              // 👈 prevent shrinking
                                              maxChildSize: 0.5,

                                              builder: (context, scrollController) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      // Header with close button
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              "Select a Plan",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Divider(height: 1),
                                                      // List of options
                                                      Expanded(
                                                        child: ListView.builder(
                                                          controller:
                                                              scrollController,
                                                          itemCount:
                                                              content!.length,
                                                          itemBuilder: (context, index) {
                                                            final item =
                                                                content![index];
                                                            final isSelected =
                                                                item.code ==
                                                                variationCode;
                                                            return ListTile(
                                                              title: Text(
                                                                "${item.title} at ${formatNaira(double.parse(item.amount.toString()))}",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Roboto',
                                                                ),
                                                              ),
                                                              trailing:
                                                                  isSelected
                                                                  ? Icon(
                                                                      Icons
                                                                          .check,
                                                                      color:
                                                                          primaryColor,
                                                                    )
                                                                  : null,
                                                              onTap: () {
                                                                setState(() {
                                                                  planAmount =
                                                                      double.parse(
                                                                        item.amount
                                                                            .toString(),
                                                                      );
                                                                  planTitle =
                                                                      "${item.title} at ${formatNaira(planAmount!)}";
                                                                  variationCode =
                                                                      item.code;
                                                                  _amount.text =
                                                                      planAmount!
                                                                          .toString();
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          planTitle,
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 30,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                  customTextField(
                    title: "Amount",
                    hint: "Amount",
                    controller: _amount,
                    type: TextInputType.number,
                    myIcon: const Icon(Icons.money),
                    readOnly: true,
                    validator: (value) =>
                        validations.validateText(value, "amount"),
                  ),
                  if (description != null)
                    Text(
                      description.toString(),
                      style: TextStyle(fontSize: 16, color: primaryColor),
                    ),
const SizedBox(height: 20,),
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
                  const SizedBox(height: 16),
                  customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        errorNotifier.value = null;
                        showPaymentBottomSheet(context);
                      }
                    },
                    context: context,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
