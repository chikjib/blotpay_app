import 'package:blotpay/models/User/user_model.dart' show UserModel;
import 'package:blotpay/screens/DashboardPage/fund_page.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/models/Package/BulkSmsModel.dart';
import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/utils/snack_message.dart';
import 'package:blotpay/utils/validations.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:blotpay/widgets/custom_text_field.dart';
import '../../providers/PackageProvider/bulk_sms_provider.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/currency.dart';
import '../../utils/routers.dart';
import '../../utils/send_notification.dart';
import '../DashboardPage/fund_with_card_page.dart';
import 'authorize_transaction.dart';

class BulkSmsPage extends StatefulWidget {
  const BulkSmsPage({super.key});

  @override
  State<BulkSmsPage> createState() => _BulkSmsPageState();
}

class _BulkSmsPageState extends State<BulkSmsPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  Future<BulkSmsModel>? bulkSmsPackages;
  List<Datum>? bulksmsDetails;

  TextEditingController _phone = TextEditingController();
  TextEditingController _senderId = TextEditingController();
  TextEditingController _message = TextEditingController();

  UserModel? user;

  String? wallet_balance;
  double walletBalance = 0.00;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;

  double? discount;
  double? amount = 0.00;
  double? totalAmount = 0.00;

  int pages = 0;
  int numCharacters = 0;
  int numPhones = 0;
  String packageId = "";

  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

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
                  formatNaira(totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontFamily: 'Roboto',
                  ),
                ),

                const SizedBox(height: 4),

                // Subtext
                Text(
                  "Total SMS Cost",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // Recipient Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Valid Recipient",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      numPhones.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total pages",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      pages.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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
                      totalAmount! <= walletBalance
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
                    if (totalAmount! > walletBalance) {
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
          child: AuthorizeTransactionModal(
            onPinComplete: (pin) async {
              final sms = Provider.of<BulkSmsProvider>(context, listen: false);

              // Validate Sender ID length
              if (_senderId.text.length > 11) {
                snack_error(
                  message: "Sender ID cannot be more than 11 characters",
                  context: context,
                );
                return;
              }

              setState(() => _isSubmitting = true);

              // 🔥 Call API & capture result directly
              final result = await sms.sendSms(
                packageId: packageId,
                recipients: _phone.text,
                senderName: _senderId.text,
                message: _message.text,
                transactionPin: pin,
                context: context,
              );

              if (!mounted) return;

              setState(() => _isSubmitting = false);

              // ✅ Handle success case
              if (result["success"] == true) {
                if (context.mounted) {
                  Navigator.pop(context); // Close modal first
                  customDialogSuccess(
                    context,
                    result["message"],
                    "Bulk SMS",
                    const Dashboard(),
                  );

                  debugPrint("bulk sms success: ${result["message"]}");
                  sendNotification("Bulk SMS", result["message"]);
                }
              }
              // ❌ Handle error case
              else {
                if (result["message"] == "Invalid transaction pin") {
                  // Show inline error without closing modal
                  errorNotifier.value = "Invalid transaction pin";
                } else {
                  if (context.mounted) {
                    Navigator.pop(context); // Close modal first
                    customDialogError(
                      context,
                      result["message"],
                      "Bulk SMS",
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
    bulkSmsPackages = BulkSmsProvider().getPackage(10, context: context);
    bulkSmsPackages!.then((value) {
      bulksmsDetails = value.data;

      if (bulksmsDetails != null) {
        setState(() {
          amount = bulksmsDetails?[0].products?.amount ?? 0.00;
          packageId = bulksmsDetails?[0].id.toString() ?? "";
        });
      }
    });

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
    _senderId.dispose();
    _message.dispose();
    super.dispose();
  }

  showDiscount(double amt) {
    // setState(() {
    //   discount = amt - (double.parse(discountRate!)/100 * amt);
    // });
    // return discount;
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
            'Bulk Sms',
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
                  customTextField(
                    title: "Sender ID",
                    hint: "Enter Sender ID",
                    controller: _senderId,
                    type: TextInputType.text,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    myIcon: const Icon(Icons.home),
                    validator: (value) =>
                        validations.validateText(value, "sender ID"),
                    onChanged: ((value) {
                      if (value != "") {
                        // showBankAmount(double.parse(value!));
                        // showDiscount(double.parse(value));
                        // _amount_to_receive.text = (double.parse(value!) - (double.parse(value) * double.parse(amount!)/100)).toString();
                      }
                    }),
                  ),
                  customTextField(
                    title: "Phone Number(s) (e.g 08011111111,08022222222)",
                    hint: "Phone number separated by commas",
                    controller: _phone,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    type: TextInputType.text,
                    myIcon: const Icon(Icons.phone),
                    maxLines: 3,
                    validator: (value) =>
                        validations.validateText(value, "Phone Number"),
                    onChanged: (val) {
                      // ✅ Only clean when user finishes a number (after a comma or space)
                      if (val!.endsWith(",") || val.endsWith(" ")) {
                        final helper = MessageFormHelper(recipients: val);

                        // Cleaned list of valid numbers
                        final cleaned = helper.validRecipients().join(", ");

                        // Update textfield without wiping in-progress typing
                        _phone.value = TextEditingValue(
                          text: cleaned + ",",
                          selection: TextSelection.collapsed(
                            offset: (cleaned + ",").length,
                          ),
                        );

                        setState(() {
                          numPhones = helper.recipientsCount;
                        });
                      } else {
                        // Just update count while typing
                        final helper = MessageFormHelper(
                          recipients: val.toString(),
                        );
                        setState(() {
                          numPhones = helper.recipientsCount;
                        });
                      }
                    },
                  ),

                  customTextField(
                    title: "Message",
                    hint: "Enter your message",
                    controller: _message,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    type: TextInputType.text,
                    myIcon: const Icon(Icons.message),
                    maxLines: 5,
                    enabled: true,
                    validator: (value) =>
                        validations.validateText(value, "Message"),
                    onChanged: ((value) {
                      if (value != "") {
                        setState(() {
                          numCharacters = value!.toString().length;
                          pages = (numCharacters ~/ 160).toInt() + 1;
                          var totalAmt =
                              double.parse(pages.toString()) *
                              amount! *
                              numPhones;
                          totalAmount = totalAmt.toDouble();
                        });
                      }
                    }),
                  ),

                  Text(
                    "Page(s):  $numCharacters / $pages",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Sms Rate:  $amount / per page",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

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

class MessageFormHelper {
  String recipients;
  String message;

  MessageFormHelper({this.recipients = "", this.message = ""});

  /// ✅ Clean and return valid recipients only
  List<String> validRecipients() {
    if (recipients.trim().isEmpty) return [];

    final numbers = recipients
        .split(",")
        .map((n) => n.trim())
        .map(
          (n) => n.replaceAll(RegExp(r'[^0-9]'), ""),
        ) // remove +, spaces, etc.
        .where(
          (n) => RegExp(r"^0\d{10}$").hasMatch(n),
        ) // must be 11 digits & start with 0
        .toSet() // remove duplicates
        .toList();

    return numbers;
  }

  /// ✅ Number of valid recipients
  int get recipientsCount => validRecipients().length;

  /// ✅ Message page count (like SMS segments)
  int get messagePageCount {
    final len = message.length;
    if (len <= 160) return 1;
    return (len / 153).ceil(); // after first page, each segment = 153 chars
  }

  /// ✅ Replace recipients string with cleaned unique numbers
  void cleanRecipients() {
    final unique = validRecipients();
    recipients = unique.join(", ");
  }
}
