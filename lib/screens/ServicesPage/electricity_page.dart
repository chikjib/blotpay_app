import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/Package/ElectricityModel.dart';
import 'package:blotpay/providers/PackageProvider/electricity_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/currency.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';

import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/routers.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_progress.dart';
import '../DashboardPage/fund_page.dart';
import '../DashboardPage/fund_with_card_page.dart';
import 'authorize_transaction.dart';

class ElectricityPage extends StatefulWidget {
  const ElectricityPage({super.key});

  @override
  State<ElectricityPage> createState() => _ElectricityPageState();
}

class _ElectricityPageState extends State<ElectricityPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  Future<ElectricityModel>? electricityPackages;

  String dropDownValue = "Select a Provider";

  UserModel? user;

  TextEditingController _phone = TextEditingController();
  TextEditingController _meterNo = TextEditingController();
  TextEditingController _amount = TextEditingController();

  double? newAmount;
  double? discount;
  String? discountRate;

  String customerName = "";
  String serviceId = "";
  String meterType = "";
  String packageId = "";
  Datum? selectedDisco;
  List<Datum> discos = [];

  String? wallet_balance;
  double walletBalance = 0.00;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;

  Timer? _debounce;
  bool isVerifying = false;

  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  String initialValue = "Select Meter Type";
  var items = ["Prepaid", "Postpaid"];

  setValue(String? value) {
    setState(() {
      initialValue = value!;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    electricityPackages = ElectricityProvider().getPackage(4, context: context);

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
    _amount.dispose();
    _meterNo.dispose();
    _phone.dispose();
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
                  "You are paying ${formatNaira(double.tryParse(_amount.text))}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontFamily: 'Roboto',
                  ),
                ),

                const SizedBox(height: 4),

                // Subtext
                Text(
                  "${selectedDisco?.title}",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Recipient Info
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "${selectedDisco?.image!}",
                        width: 50,
                        height: 50,
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
                          _meterNo.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
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

              final electricity = Provider.of<ElectricityProvider>(
                context,
                listen: false,
              );

              // 🔥 Call API & capture result directly
              final result = await electricity.buyElectricity(
                packageId: packageId,
                serviceId: serviceId,
                variationCode: meterType.toLowerCase(),
                meterNo: _meterNo.text,
                phone: _phone.text,
                amount: double.tryParse(_amount.text) ?? 0.0,
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
                    "Electricity Purchase",
                    const Dashboard(),
                  );

                  debugPrint("electricity success response: ${result["message"]}");
                  sendNotification("Electricity Purchase", result["message"]);
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
                      "Electricity Purchase",
                    );
                  }
                }
              }
            },
            errorNotifier: errorNotifier,
          )
          ,
        );
      },
    );
  }

  showDiscount(double amt) {
    setState(() {
      discount = amt - (double.parse(discountRate!) / 100 * amt);
    });
    return discount;
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
            'Electricity Bills',
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
                    future: electricityPackages,
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
                        discos = snapshot.data!.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select disco",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Opacity(
                              opacity: (discos.isEmpty) ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: discos.isEmpty,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
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
                                        Radius.circular(12.0),
                                      ),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (discos.isEmpty) return;

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
                                                            const Text(
                                                              "Select Disco",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
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
                                                      const Divider(height: 1),
                                                      Expanded(
                                                        child: ListView.builder(
                                                          controller:
                                                              scrollController,
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              discos.length,
                                                          itemBuilder: (context, index) {
                                                            final disco =
                                                                discos[index];
                                                            final isSelected =
                                                                selectedDisco
                                                                    ?.id ==
                                                                disco.id;
                                                            final imageUrl =
                                                                disco
                                                                        .image
                                                                        ?.isNotEmpty ==
                                                                    true
                                                                ? disco.image!
                                                                : '';

                                                            return ListTile(
                                                              leading:
                                                                  imageUrl
                                                                      .isNotEmpty
                                                                  ? ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            20,
                                                                          ),
                                                                      child: CachedNetworkImage(
                                                                        imageUrl:
                                                                            imageUrl,
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        fadeInDuration: const Duration(
                                                                          milliseconds:
                                                                              200,
                                                                        ),
                                                                        // ✅ smooth
                                                                        placeholderFadeInDuration:
                                                                            Duration.zero,
                                                                        // ✅ no flash
                                                                        placeholder:
                                                                            (
                                                                              _,
                                                                              __,
                                                                            ) =>
                                                                                const SizedBox.shrink(),
                                                                        // ✅ no spinner,
                                                                        errorWidget:
                                                                            (
                                                                              context,
                                                                              url,
                                                                              error,
                                                                            ) => const Icon(
                                                                              Icons.image_not_supported,
                                                                              size: 24,
                                                                            ),
                                                                      ),
                                                                    )
                                                                  : const Icon(
                                                                      Icons
                                                                          .image_not_supported,
                                                                      size: 24,
                                                                    ),
                                                              title: Text(
                                                                disco.title ??
                                                                    '',
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
                                                                  selectedDisco =
                                                                      disco;
                                                                  packageId = disco
                                                                      .id
                                                                      .toString();
                                                                  serviceId =
                                                                      disco
                                                                          .title ??
                                                                      '';
                                                                  discountRate =
                                                                      disco
                                                                          .products
                                                                          ?.discount
                                                                          ?.toString() ??
                                                                      "0";
                                                                  _amount.text =
                                                                      "";
                                                                  initialValue =
                                                                      "Select Meter Type";
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
                                      children: [
                                        if (selectedDisco?.image?.isNotEmpty ==
                                            true)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: selectedDisco!.image!,
                                              width: 30,
                                              height: 30,
                                              fit: BoxFit.cover,
                                              fadeInDuration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              // ✅ smooth
                                              placeholderFadeInDuration:
                                                  Duration.zero,
                                              // ✅ no flash
                                              placeholder: (_, __) =>
                                                  const SizedBox.shrink(),
                                              // ✅ no spinner,
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => const Icon(
                                                    Icons.image_not_supported,
                                                    size: 24,
                                                  ),
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            selectedDisco?.title ??
                                                "Select Disco",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: discos.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 30,
                                          color: discos.isNotEmpty
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Center(child: Text("Error Occurred"));
                      } else {
                        return const Center(child: Text("No provider found"));
                      }
                    },
                  ),
                  Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Meter Type",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: black,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: (items.isEmpty) ? 0.5 : 1.0, // dim if empty
                        child: IgnorePointer(
                          ignoring: items.isEmpty, // disable if empty
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 10,
                            ),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: items.isNotEmpty
                                      ? primaryColor
                                      : Colors.grey,
                                  width: 2.0,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                            ),
                            width: MediaQuery.of(context).size.width,
                            child: InkWell(
                              onTap: () {
                                if (items.isEmpty) return;

                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  enableDrag: true,
                                  isDismissible: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (BuildContext context) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => Navigator.pop(context),
                                      // tap outside to dismiss
                                      child: GestureDetector(
                                        onTap: () {},
                                        // absorb taps inside sheet
                                        child: DraggableScrollableSheet(
                                          initialChildSize: 0.5,
                                          minChildSize: 0.5,
                                          maxChildSize: 0.9,
                                          builder: (context, scrollController) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      top: Radius.circular(20),
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
                                                        const Text(
                                                          "Select Meter Type",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
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
                                                  const Divider(height: 1),
                                                  Expanded(
                                                    child: ListView.builder(
                                                      controller:
                                                          scrollController,
                                                      itemCount: items.length,
                                                      itemBuilder: (context, index) {
                                                        final item =
                                                            items[index];
                                                        final isSelected =
                                                            initialValue ==
                                                            item;

                                                        return ListTile(
                                                          title: Text(item),
                                                          trailing: isSelected
                                                              ? Icon(
                                                                  Icons.check,
                                                                  color:
                                                                      primaryColor,
                                                                )
                                                              : null,
                                                          onTap: () {
                                                            setState(() {
                                                              initialValue =
                                                                  item;
                                                              meterType = item;
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
                                    initialValue,
                                    style: TextStyle(
                                      color: items.isNotEmpty
                                          ? Colors.black
                                          : Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: items.isNotEmpty
                                        ? Colors.black
                                        : Colors.grey,
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
                    title: "Meter no",
                    hint: "Enter meter number",
                    controller: _meterNo,
                    type: TextInputType.number,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    myIcon: const Icon(Icons.smart_screen),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();

                      _debounce = Timer(const Duration(milliseconds: 500), () async {
                        if (value!.length == 11) {
                          setState(() => isVerifying = true);

                          final electricity = Provider.of<ElectricityProvider>(
                            context,
                            listen: false,
                          );
                          final result = await electricity.verifyElectricity(
                            packageId: packageId.toString(),
                            meterNo: value,
                            meterType: meterType.toLowerCase(),
                            context: context,
                          );
                          if (result["success"]) {
                            setState(() {
                              customerName = result["customerName"];
                              isVerifying = false;
                            });
                          } else {
                            snack_error(message: result["message"], context: context);
                            setState(() => isVerifying = false);
                          }
                        }
                      });
                    },
                    validator: (value) =>
                        validations.validateText(value, "Meter Number"),
                  ),

                  if (customerName.isNotEmpty)
                    Text(
                      customerName.toString(),
                      style: TextStyle(color: primaryColor),
                    ),

                  Consumer<ElectricityProvider>(
                    builder: (context, electricity, child) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (isVerifying && !electricity.status) {
                          setState(() => isVerifying = false);
                        }
                      });

                      return isVerifying
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox();
                    },
                  ),

                  customTextField(
                    title: "Amount",
                    hint: "Enter amount",
                    controller: _amount,
                    type: TextInputType.number,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    myIcon: const Icon(Icons.money),
                    validator: (value) {
                      // First, check if it's empty
                      final textError = validations.validateText(
                        value,
                        "amount",
                      );
                      if (textError != null) return textError;

                      // Then check minimum amount
                      double? amt = double.tryParse(value!);
                      if (amt == null) return "Invalid number";
                      if (selectedDisco?.id == 24 ||
                          selectedDisco?.id == 39 ||
                          selectedDisco?.id == 40) {
                        if (amt < 2000) return "Minimum amount is 2000";
                      } else {
                        if (amt < 1000) return "Minimum amount is 1000";
                      }

                      return null; // valid
                    },
                    onChanged: ((value) {
                      if (value != "") {
                        showDiscount(double.parse(value!));
                      }
                    }),
                  ),

                  customTextField(
                    title: "Phone Number",
                    hint: "Enter phone number",
                    controller: _phone,
                    type: TextInputType.phone,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    myIcon: const Icon(Icons.phone),
                    validator: (value) =>
                        validations.validatePhone(value, "Phone Number"),
                  ),

                  if (discount != null)
                    Text(
                      "You will be charged: ${formatNaira(double.tryParse(discount.toString()) ?? 0.0)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (newAmount != null)
                    Text(
                      "Pay with Bank Charge: ${formatNaira(double.tryParse(newAmount.toString()) ?? 0.0)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),

                  customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () {
                      if (selectedDisco == null) {
                        snack_error(
                          message: "Please select a disco provider",
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

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
