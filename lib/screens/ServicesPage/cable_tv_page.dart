import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/Package/CableModel.dart';
import 'package:blotpay/providers/PackageProvider/cable_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/currency.dart';
import '../../utils/routers.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_progress.dart';
import '../../widgets/shimmer_loader.dart';
import '../DashboardPage/fund_page.dart';
import '../DashboardPage/fund_with_card_page.dart';
import 'authorize_transaction.dart';

class CableTvPage extends StatefulWidget {
  const CableTvPage({super.key});

  @override
  State<CableTvPage> createState() => _CableTvPageState();
}

class _CableTvPageState extends State<CableTvPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  // String initialValue = "Select Provider";
  // List<String>packages = [];
  String dropDownValue = "Select a Provider";
  String planTitle = "Select a Plan";
  int? packageId;
  UserModel? user;
  String? wallet_balance;
  double walletBalance = 0.00;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;

  Future<CableModel>? tvPackages;
  List<Datum> allPackages = [];
  Datum? selectedService;

  TextEditingController _smartNo = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _amount = TextEditingController();

  String customerName = "";
  String currentBouquet = "";
  String type = "";

  double? variationAmount;
  String? variationCode;

  double? newAmount;
  double? discount;
  Timer? _debounce;
  bool isVerifying = false;

  bool isLoading = false;

  List<Product>? content;
  String? description;

  String subscriptionTitle = "Select type";
  String? subscriptionValue;

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tvPackages = CableProvider().getPackage(3, context: context);
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
                  planTitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Recipient Info
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "${selectedService?.image!}",
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
                          customerName,
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

              final cable = Provider.of<CableProvider>(context, listen: false);

              // 🔥 Call API & capture result directly
              final result = await cable.buyTv(
                packageId: packageId.toString(),
                phone: _phone.text,
                variationCode: variationCode.toString(),
                smartNo: _smartNo.text,
                planName: planTitle,
                amount: _amount.text,
                subscriptionType: subscriptionValue.toString(),
                transactionPin: pin,
                context: context,
              );

              if (!mounted) return;

              setState(() => _isSubmitting = false);

              // ✅ Handle response directly from result
              if (result["success"] == true) {
                if (context.mounted) {
                  Navigator.pop(context); // Close modal first
                  customDialogSuccess(
                    context,
                    result["message"],
                    "Cable Purchase",
                    const Dashboard(),
                  );

                  print("cable success response: ${result["message"]}");
                  sendNotification("Cable Purchase", result["message"]);
                }
              } else {
                // Error handling
                if (result["message"] == "Invalid transaction pin") {
                  // Show inline error without closing modal
                  errorNotifier.value = "Invalid transaction pin";
                } else {
                  if (context.mounted) {
                    Navigator.pop(context); // Close modal first
                    customDialogError(
                      context,
                      result["message"],
                      "Cable Purchase",
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
            'Pay Cable/Tv',
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
                    future: tvPackages,
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
                              "Select a provider",
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
                                      screenWidth * 0.20; // 20% of screen width
                                  final imageSize =
                                      circleSize * 0.75; // 75% of circle

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: allPackages.map((service) {
                                        final isSelected =
                                            selectedService?.id == service.id;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedService = service;
                                              packageId = service.id;
                                              type = service.title.toString();
                                              customerName = "";
                                              planTitle = "Select a Plan";
                                              content = [];
                                              _amount.text = "";
                                              if (type == "SHOWMAX") {
                                                getServiceDetails(
                                                  allPackages,
                                                  packageId,
                                                );
                                              }
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
                                                    if (service.image != null &&
                                                        service
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
                                                                service.image!,
                                                            fit: BoxFit.cover,
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
                  const SizedBox(height: 12),
                  type != "SHOWMAX"
                      ? customTextField(
                          title: "Smart/IUC number",
                          hint: "Enter smart/iuc number",
                          controller: _smartNo,
                          type: TextInputType.number,
                          myIcon: const Icon(Icons.smart_screen),
                          autoValidate: AutovalidateMode.onUserInteraction,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();

                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              () async {
                                if (value?.length != null &&
                                    value!.length >= 10) {
                                  setState(() => isVerifying = true);

                                  final cable = Provider.of<CableProvider>(
                                    context,
                                    listen: false,
                                  );

                                  final result = await cable.verifyTv(
                                    packageId: packageId.toString(),
                                    smartNo: value.toString(),
                                    context: context,
                                  );

                                  if (result["success"]) {
                                    setState(() {
                                      customerName = result["customerName"];
                                      currentBouquet = result["currentBouquet"];
                                      getServiceDetails(allPackages, packageId);
                                      isVerifying = false;
                                    });
                                  } else {
                                    snack_error(message: result["message"], context: context);
                                    setState(() => isVerifying = false);
                                  }
                                }
                              },
                            );
                          },
                          validator: (value) => validations.validateText(
                            value,
                            "Smart/IUC number",
                          ),
                        )
                      : const SizedBox(),

                  if (customerName != "" || currentBouquet != "")
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(color: primaryColor),
                              // default style
                              children: [
                                const TextSpan(
                                  text: 'Customer Name: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // normal
                                TextSpan(text: customerName ?? ""),
                              ],
                            ),
                          ),
                          const Divider(),

                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(color: primaryColor),
                              // default style
                              children: [
                                const TextSpan(
                                  text: 'Current Bouquet: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // 👈 bold only bouquet), // normal
                                TextSpan(text: currentBouquet ?? ""),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  Consumer<CableProvider>(
                    builder: (context, cable, child) {
                      return cable.vstatus
                          ? ShimmerLoader(height: 50, width: double.infinity)
                          : const SizedBox();
                    },
                  ),

                  isLoading
                      ? customProgress(20, 20)
                      : Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select a Subscription Type",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: (subscriptionContent.isEmpty)
                                  ? 0.5
                                  : 1.0,
                              // 👈 dim if empty
                              child: IgnorePointer(
                                ignoring: (subscriptionContent.isEmpty),
                                // 👈 disable interaction
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
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
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                  child: InkWell(
                                    onTap: () {
                                      if (subscriptionContent.isEmpty) return;

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
                                              minChildSize: 0.5,
                                              maxChildSize:
                                                  0.5, // 👈 fixed height
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
                                                              "Select Subscription Type",
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
                                                              subscriptionContent
                                                                  .length,
                                                          itemBuilder: (context, index) {
                                                            final item =
                                                                subscriptionContent[index];
                                                            final isSelected =
                                                                item.value ==
                                                                subscriptionValue;
                                                            return ListTile(
                                                              title: Text(
                                                                item.title
                                                                    .toString(),
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
                                                                  subscriptionTitle =
                                                                      item.title;
                                                                  subscriptionValue =
                                                                      item.value;
                                                                  // if (subscriptionValue ==
                                                                  //     "renew") {
                                                                  //   // handle renew logic here
                                                                  // }
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
                                        Text(subscriptionTitle),
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

                            if (subscriptionValue == "change" ||
                                subscriptionValue == "renew")
                              Column(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Select a Plan",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: (content?.isEmpty ?? true)
                                        ? 0.5
                                        : 1.0,
                                    child: IgnorePointer(
                                      ignoring: (content?.isEmpty ?? true),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
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
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(8.0),
                                                ),
                                          ),
                                        ),
                                        width: MediaQuery.of(
                                          context,
                                        ).size.width,
                                        child: InkWell(
                                          onTap: () {
                                            if (content?.isEmpty ?? true)
                                              return;

                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              isDismissible: true,
                                              enableDrag: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (BuildContext context) {
                                                return GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () =>
                                                      Navigator.pop(context),
                                                  child: DraggableScrollableSheet(
                                                    initialChildSize: 0.5,
                                                    minChildSize: 0.5,
                                                    maxChildSize: 0.5,
                                                    builder: (context, scrollController) {
                                                      return Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        12,
                                                                  ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    "Select Plan",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .close,
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
                                                                    content!
                                                                        .length,
                                                                itemBuilder: (context, index) {
                                                                  final item =
                                                                      content![index];
                                                                  final isSelected =
                                                                      item.code ==
                                                                      variationCode;
                                                                  return ListTile(
                                                                    title: Text(
                                                                      item.title
                                                                          .toString(),
                                                                    ),
                                                                    // subtitle: Text(formatNaira(double.parse(item.amount.toString())),style: TextStyle(fontFamily: 'Roboto'),),
                                                                    trailing:
                                                                        isSelected
                                                                        ? Icon(
                                                                            Icons.check,
                                                                            color:
                                                                                primaryColor,
                                                                          )
                                                                        : null,
                                                                    onTap: () {
                                                                      setState(() {
                                                                        planTitle =
                                                                            item.title!;
                                                                        variationCode =
                                                                            item.code;
                                                                        variationAmount = double.tryParse(
                                                                          item.amount
                                                                              .toString(),
                                                                        );
                                                                        _amount.text =
                                                                            variationAmount?.toString() ??
                                                                            "";
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
                                              Text(planTitle),
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
                          ],
                        ),

                  customTextField(
                    title: "Amount",
                    hint: "Amount",
                    controller: _amount,
                    type: TextInputType.number,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    myIcon: const Icon(Icons.money),
                    readOnly: true,
                    validator: (value) =>
                        validations.validateText(value, "amount"),
                  ),

                  customTextField(
                    title: "Phone Number",
                    hint: "Enter phone number",
                    controller: _phone,
                    type: TextInputType.phone,
                    myIcon: const Icon(Icons.phone),
                    validator: (value) =>
                        validations.validatePhone(value, "Phone Number"),
                  ),

                  if (discount != null)
                    Text(
                      "You will be charged: ${formatNaira(double.tryParse(discount.toString()) ?? 0.0)}",
                      style: const TextStyle(fontSize: 16),
                    ),

                  const SizedBox(height: 16),

                  customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () {
                      if (selectedService == null) {
                        snack_error(
                          message: "Please select a service provider",
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionType {
  String title;
  String value;

  SubscriptionType(this.title, this.value);
}

List<SubscriptionType> subscriptionContent = [
  SubscriptionType('Renew', "renew"),
  SubscriptionType('Change', "change"),
];
