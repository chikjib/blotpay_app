import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:blotpay/constants/app_constants.dart';
import 'package:blotpay/models/Package/ExamModel.dart';
import 'package:blotpay/providers/PackageProvider/exam_provider.dart';
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
import '../DashboardPage/fund_page.dart';
import '../DashboardPage/fund_with_card_page.dart';
import 'authorize_transaction.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  // String initialValue = "Select Provider";
  // List<String>packages = [];
  String dropDownValue = "Select Exam";
  String planTitle = "Select a Plan";
  int? packageId;

  Future<ExamModel>? examPackages;
  bool isLoading = false;

  UserModel? user;

  TextEditingController _profileId = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _amount = TextEditingController();

  String customerName = "";
  String type = "";
  String serviceId = "";

  double? variationAmount;
  String? variationCode;

  double? newAmount;
  double? discount;

  Datum? selectedExam;
  List<Datum> exams = [];

  String? wallet_balance;
  double walletBalance = 0.00;

  bool _isLoading = true;
  bool _isCancelled = false;
  bool _isSubmitting = false;

  List<Product>? content;
  String? description;

  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    examPackages = ExamProvider().getPackage(6, context: context);

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
    _profileId.dispose();
    super.dispose();
  }

  void getExamPlans(List<Datum> packages, int? packageId) {
    selectedExam = packages.firstWhere(
      (exam) => exam.id == packageId,
      orElse: () => Datum(), // return empty Datum if not found
    );

    if (selectedExam != null) {
      content = selectedExam!.products;
      description = selectedExam!.description;
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
                  "${selectedExam?.title} Pin Purchase",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Recipient Info
                Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        "${selectedExam?.image!}",
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
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
                        _profileId.text.isNotEmpty
                            ? Text(
                                _profileId.text,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              )
                            : Text(
                                _phone.text,
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

              final exam = Provider.of<ExamProvider>(context, listen: false);

              // 🔥 Call API & capture result directly
              final result = await exam.buyExam(
                packageId: packageId.toString(),
                phone: _phone.text,
                profileCode: _profileId.text.isNotEmpty ? _profileId.text : null,
                variationCode: variationCode.toString(),
                serviceId: serviceId,
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
                    "Exam Purchase",
                    const Dashboard(),
                  );

                  debugPrint("exam success response: ${result["message"]}");
                  sendNotification("Exam Purchase", result["message"]);
                }
              } else {
                // ❌ Error handling
                if (result["message"] == "Invalid transaction pin") {
                  // Show inline error without closing modal
                  errorNotifier.value = "Invalid transaction pin";
                } else {
                  if (context.mounted) {
                    Navigator.pop(context); // Close modal first
                    customDialogError(
                      context,
                      result["message"],
                      "Exam Purchase",
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
            'Buy Exam Pins',
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
                    future: examPackages,
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
                        exams = snapshot.data!.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select Exam Provider",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Opacity(
                              opacity: (exams.isEmpty) ? 0.5 : 1.0,
                              // 👈 dim if empty
                              child: IgnorePointer(
                                ignoring: exams.isEmpty,
                                // 👈 disable interaction
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
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
                                  width: MediaQuery.of(context).size.width,
                                  child: InkWell(
                                    onTap: () {
                                      if (exams.isEmpty) return;

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
                                                              "Select Exam",
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
                                                          itemCount:
                                                              exams.length,
                                                          itemBuilder: (context, index) {
                                                            final exam =
                                                                exams[index];
                                                            final isSelected =
                                                                selectedExam
                                                                    ?.id ==
                                                                exam.id;
                                                            final imageUrl =
                                                                exam
                                                                        .image
                                                                        ?.isNotEmpty ==
                                                                    true
                                                                ? exam.image!
                                                                : '';

                                                            return ListTile(
                                                              leading:
                                                                  imageUrl
                                                                      .isNotEmpty
                                                                  ? ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            50,
                                                                          ),
                                                                      child: CachedNetworkImage(
                                                                        imageUrl:
                                                                            exam.image!,
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        fit: BoxFit
                                                                            .contain,
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
                                                                exam.title ??
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
                                                                  selectedExam =
                                                                      exam;
                                                                  packageId =
                                                                      exam.id;
                                                                  serviceId =
                                                                      exam.title ??
                                                                      '';
                                                                  type =
                                                                      exam.title ??
                                                                      '';
                                                                  _amount
                                                                      .clear();
                                                                  planTitle =
                                                                      "Select Exam Type";
                                                                  getExamPlans(
                                                                    exams,
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
                                      children: [
                                        if (selectedExam?.image?.isNotEmpty ==
                                            true)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: selectedExam!.image!,
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
                                            selectedExam?.title ??
                                                "Select Exam",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: exams.isNotEmpty
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 30,
                                          color: exams.isNotEmpty
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
                  if (type == "JAMB")
                    customTextField(
                      title: "Profile ID",
                      hint: "Enter your profile ID",
                      controller: _profileId,
                      type: TextInputType.number,
                      myIcon: const Icon(Icons.verified_user),
                      onChanged: ((value) {}),
                      validator: (value) =>
                          validations.validateText(value, "Profile ID"),
                    ),

                  if (customerName != "")
                    Text(
                      customerName.toString(),
                      style: TextStyle(color: primaryColor),
                    ),
                  if (type == "JAMB")
                    Consumer<ExamProvider>(
                      builder: (context, exam, child) {
                        return customButton(
                          tap: () async {
                            if (_profileId.text.isEmpty) {
                              snack_error(
                                message: "Profile Id is required",
                                context: context,
                              );
                            } else {
                              setState(() => isLoading = true);

                              final result = await exam.verifyExam(
                                packageId: packageId.toString(),
                                profileId: _profileId.text,
                                context: context,
                              );

                              if (result["success"]) {
                                setState(() {
                                  customerName = result["customerName"];
                                  isLoading = false;
                                });
                              } else {
                                snack_error(message: result["message"], context: context);
                                setState(() => isLoading = false);
                              }
                            }
                          },
                          text: "Verify",
                          context: context,
                          status: exam.status, // now only one status
                        );
                      },
                    ),

                  isLoading
                      ? customProgress(20, 20)
                      : Column(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Select Exam Type",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: (content?.isEmpty ?? true) ? 0.5 : 1.0,
                              child: IgnorePointer(
                                ignoring: (content?.isEmpty ?? true),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
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
                                  width: MediaQuery.of(context).size.width,
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
                                                              "Select Exam Type",
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
                                                          itemCount:
                                                              content!.length,
                                                          itemBuilder: (context, index) {
                                                            final item =
                                                                content![index];
                                                            final value =
                                                                "${item.title}_${item.code}_${item.amount}_${item.airtimeNgPackageCode}";
                                                            final isSelected =
                                                                planTitle ==
                                                                item.title;

                                                            return ListTile(
                                                              title: Text(
                                                                item.title
                                                                    .toString(),
                                                              ),
                                                              // subtitle: Text(formatNaira(item.amount.toString()), ),
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
                                                                  planTitle =
                                                                      item.title!;
                                                                  variationCode =
                                                                      item.code;
                                                                  serviceId =
                                                                      planTitle
                                                                          .toLowerCase();
                                                                  variationAmount =
                                                                      double.parse(
                                                                        item.amount
                                                                            .toString(),
                                                                      );
                                                                  _amount.text =
                                                                      variationAmount
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: (content?.isEmpty ?? true)
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: (content?.isEmpty ?? true)
                                              ? Colors.grey
                                              : Colors.black,
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
                    title: "Amount",
                    hint: "Amount",
                    controller: _amount,
                    type: TextInputType.number,
                    myIcon: const Icon(Icons.money),
                    readOnly: true,
                    validator: (value) =>
                        validations.validateText(value, "amount"),
                  ),

                  customTextField(
                    title: "Phone Number",
                    hint: "Enter phone number",
                    controller: _phone,
                    autoValidate: AutovalidateMode.onUserInteraction,
                    type: TextInputType.phone,
                    myIcon: const Icon(Icons.phone),
                    validator: (value) =>
                        validations.validatePhone(value, "Phone Number"),
                  ),

                  const SizedBox(height: 16),
                  customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () {
                      if (selectedExam == null) {
                        snack_error(
                          message: "Please select an exam provider",
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
      ),
    );
  }
}
