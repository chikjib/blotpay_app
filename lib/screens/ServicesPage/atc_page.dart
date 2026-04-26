import 'package:blotpay/utils/currency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/Package/Airtime2CashModel.dart';
import 'package:blotpay/providers/PackageProvider/airtime2cash_provider.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/routers.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_progress.dart';

class AtcPage extends StatefulWidget {
  const AtcPage({super.key});

  @override
  State<AtcPage> createState() => _AtcPageState();
}

class _AtcPageState extends State<AtcPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  Future<Airtime2CashModel>? atcPackages;


  UserModel? user;

  String dropDownValue = "Select a Provider";

  TextEditingController _phone = TextEditingController();
  TextEditingController _amount = TextEditingController();

  double? newAmount;
  int? commission;
  String? amount;
  String txtBody = "";
  String packageId = "";
  String amountToReceive = "";
  String description = "";

  List<Datum> networks = [];

  Datum? selectedNetwork;
  String? networkType;
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  bool visibilityStatus = false;

  String? wallet_balance;
  double walletBalance = 0.00;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;

  checkVisibility() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      visibilityStatus = pref.getBool("VISIBILITY_STATUS") ?? false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    atcPackages = Airtime2CashProvider().getPackage(5, context: context);

    checkVisibility();
    UserProvider().getUser(context: context).then((data) {
      _isCancelled = true;
      user = data;

      setState(() {
        // first_name = user?.data?.firstName ?? "";
        wallet_balance = user?.data?.walletBalance ?? "0.00";
        walletBalance = double.tryParse(wallet_balance!)!;
        _isLoading = false;
      });

      // print(user?.data!.firstName);
    }).catchError((error) {
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
    // _phone.clear();
  }

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

                const SizedBox(height: 15),

                // Subtext
                Text.rich(
                  TextSpan(
                    text: "Please transfer ",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(
                        text: formatNaira(double.tryParse(_amount.text)),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold, // 🔥 Bold for amount
                        ),
                      ),
                      const TextSpan(
                        text: " to the phone number below",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        description.split("|")[1],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(width: 8), // spacing between text and icon
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: description.split("|")[1]),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phone number copied"),
                            ),
                          );
                        },
                        child: Icon(Icons.copy, size: 20, color: primaryColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                  width: double.infinity,
                  child: Text(
                    "Note: Please do not call this phone number",
                    style: TextStyle(color: black, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 3,
                  color: white,
                  shadowColor: white,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // remove divider line
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: const Text(
                        "How to transfer/set share pin",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            // ✅ aligns to start
                            child: Text(
                              description.split("|")[0],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign:
                                  TextAlign.start, // ✅ ensures text aligns left
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Proceed Button
                customButton(
                  text: 'Proceed',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  tap: () {
                    Navigator.pop(context);
                    showConfirmTransferSheet(context);
                  },
                  context: context,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void showConfirmTransferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // makes it flexible in height
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                "Confirm Transfer",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                "Are you sure you have transferred the sum of ${formatNaira(double.tryParse(_amount.text))} to",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),

              // Recipient phone number
              Text(
                description.split("|")[1],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("No, Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Consumer<Airtime2CashProvider>(
                      builder: (context, atc, child) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: atc.status
                              ? null
                              : () async {

                              if (int.parse(_amount.text) < 1000) {
                                Navigator.pop(context);
                                snack_error(
                                  message: "Transfer of less than N1,000 not allowed!",
                                  context: context,
                                );
                              } else {
                                final result = await atc.convertAtc(
                                  packageId: packageId,
                                  phoneNumber: _phone.text.trim(),
                                  amountTransferred: double.parse(_amount.text.trim()),
                                  amountToReceive: double.parse(amountToReceive.trim()),
                                  context: context,
                                );

                                if (result["success"]) {
                                  sendNotification("Airtime to Cash", result["message"]);
                                  customDialogSuccess(
                                    context,
                                    result["message"],
                                    "Airtime to Cash",
                                    const Dashboard(),
                                  );
                                } else {
                                  sendNotification("Airtime to Cash", result["message"]);
                                  customDialogError(
                                    context,
                                    result["message"],
                                    "Airtime to Cash",
                                  );
                                }
                              }

                          },
                          child: atc.status
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("Yes, Confirm"),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
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
          'Airtime to Cash',
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
              PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
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
                  future: atcPackages,
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
                      networks = snapshot.data!.data!;
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
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: white.withValues(alpha: 0.2),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final screenWidth = constraints.maxWidth;

                                // 🔹 Dynamic sizes
                                final circleSize = screenWidth * 0.20; // 20% of screen width
                                final imageSize = circleSize * 0.75;   // 75% of the circle

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: networks.map((network) {
                                      final isSelected = selectedNetwork?.id == network.id;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedNetwork = network;
                                            packageId = network.id.toString();
                                            commission = network.products?.commission ?? 0;
                                            description = network.description ?? "";
                                            amountToReceive = "";
                                          });
                                        },
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: circleSize,
                                              height: circleSize,
                                              margin: const EdgeInsets.symmetric(horizontal: 6),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isSelected ? white : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(circleSize / 2),
                                                border: Border.all(
                                                  color: isSelected ? primaryColor : myLightGrey,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (network.image != null &&
                                                      network.image!.isNotEmpty)
                                                    SizedBox(
                                                      width: imageSize,
                                                      height: imageSize,
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(imageSize / 2),
                                                        child: CachedNetworkImage(
                                                          imageUrl: network.image!,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context, url) =>
                                                          const Center(
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                          errorWidget: (context, url, error) =>
                                                          const Icon(
                                                            Icons.image_not_supported,
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // ✅ Responsive checkmark
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
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    bottom: 10,
                  ),
                  child: HtmlWidget(txtBody),
                ),
                customTextField(
                  title: "Phone Number",
                  hint: "Enter phone number",
                  controller: _phone,
                  type: TextInputType.phone,
                  autoValidate: AutovalidateMode.onUserInteraction,
                  myIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                    onPressed: _pickContact,
                    icon: Icon(
                      LucideIcons.idCard,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  validator: (value) =>
                      validations.validatePhone(value, "Phone Number"),
                ),
                customTextField(
                  title: "Amount",
                  hint: "Enter amount",
                  controller: _amount,
                  type: TextInputType.number,
                  autoValidate: AutovalidateMode.onUserInteraction,
                  myIcon: const Icon(Icons.money),
                  walletShow: true,
                  walletBalance: !visibilityStatus
                      ? "*****"
                      : formatNaira(double.tryParse(walletBalance.toString())),
                  validator: (value) =>
                      validations.validateAtc(value, "amount"),
                  onChanged: ((value) {
                    if (value != "") {
                      // showBankAmount(double.parse(value!));
                      // showDiscount(double.parse(value));
                      setState(() {
                        amountToReceive =
                            (double.parse(value!) -
                                (double.parse(value) *
                                    (double.parse(commission.toString()) /
                                        100)))
                                .toString();
                      });
                    }
                  }),
                ),
                amountToReceive.isNotEmpty
                    ? Text(
                  "You will receive ${formatNaira(double.tryParse(amountToReceive))}",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : SizedBox(),

                const SizedBox(height: 16),
                // Consumer<Airtime2CashProvider>(builder: (context, atc, child) {
                //   WidgetsBinding.instance!.addPostFrameCallback((_) {
                //     if (atc.errorResponse != '') {
                //       // error(message: upgrade.errorResponse, context: context);
                //       customDialogError(
                //           context, atc.errorResponse, "Airtime to Cash");
                //       sendNotification("Airtime to Cash", atc.errorResponse);
                //
                //       atc.clearError();
                //     } else if (atc.response != '') {
                //       sendNotification("Airtime to Cash", atc.response);
                //
                //       customDialogSuccess(context, atc.response,
                //           "Airtime to Cash", const Dashboard());
                //       // success(message: upgrade.response, context: context);
                //       atc.clearSuccess();
                //     }
                //   });
                //   return customButton(
                //     text: 'Convert',
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //     tap: () {
                //       print(_formKey.currentState!.validate());
                //       if (_formKey.currentState!.validate()) {
                //         _formKey.currentState!.save();
                //         if (int.parse(_amount.text) < 5000) {
                //           error(
                //               message:
                //                   "Transfer of less than N5,000 not allowed!",
                //               context: context);
                //         } else {
                //           atc.convertAtc(
                //               packageId: packageId,
                //               phoneNumber: _phone.text.trim(),
                //               amountTransferred: double.parse(
                //                   _amount.text.trim()),
                //               amountToReceive: double.parse(
                //                   amountToReceive.trim()));
                //         }
                //       }
                //     },
                //     context: context,
                //     status: atc.status,
                //   );
                // }),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }
}
