import 'package:blotpay/models/User/beneficiary_model.dart';
import 'package:blotpay/screens/ServicesPage/buy_airtime_page.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../providers/PackageProvider/beneficiary_provider.dart';
import '../../../utils/routers.dart';
import '../../../utils/validations.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../DashboardPage/dashboard.dart';


class EditBeneficiary extends StatefulWidget {
  final BeneficiaryData? beneficiary;
  const EditBeneficiary({super.key, required this.beneficiary});

  @override
  State<EditBeneficiary> createState() => _EditBeneficiaryState();
}

class _EditBeneficiaryState extends State<EditBeneficiary> {

  final _formKey = GlobalKey<FormState>();
  final validations = Validations();

  TextEditingController _phone = TextEditingController();
  TextEditingController _name = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState
    _name.text = widget.beneficiary?.name == null
        ? widget.beneficiary?.phoneNo ?? ""
        : widget.beneficiary!.name!;
    _phone.text = widget.beneficiary!.phoneNo!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Edit Beneficiary',
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
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: Column(
        children: [
          customTextField(
            title: "Name",
            hint: "Enter Name",
            controller: _name,
            type: TextInputType.text,
            autoValidate: AutovalidateMode.onUserInteraction,
            myIcon: const Icon(Icons.abc),
            validator: (value) =>
                validations.validateText(value, "Name"),
            onChanged: ((value) {
              if (value != "") {
                // showBankAmount(double.parse(value!));
                // showDiscount(double.parse(value));
                // _amount_to_receive.text = (double.parse(value!) - (double.parse(value) * double.parse(amount!)/100)).toString();
              }
            }),
          ),
          customTextField(
            title: "Beneficiary",
            hint: "Enter phone number",
            controller: _phone,
            type: TextInputType.phone,
            myIcon: const Icon(Icons.phone),
            autoValidate: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                validations.validatePhone(value, "Beneficiary"),
          ),
          const Spacer(),
            Consumer<BeneficiaryProvider>(
                builder: (context, beneficiary, child) {
                  return customButton(
                    text: 'Proceed',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    tap: () async {
                      if (_formKey.currentState!.validate()){
                        _formKey.currentState!.save();

                        final result = await beneficiary.updateBeneficiary(phoneNo: _phone.text, beneficiaryId: widget.beneficiary!.id.toString(), name: _name.text, context: context);
                        if (result["success"] == true) {
                          if (context.mounted) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (context.mounted) {
                                customDialogSuccess(
                                  context,
                                  result["message"],
                                  "Beneficiary update",
                                  const BuyAirtimePage(),
                                );
                              }
                            });

                            print("beneficiary update response");
                            print(result["message"]);
                          }
                        } else {
                          // Error case
                          print("close1");
                          if (context.mounted) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (context.mounted) {
                                customDialogSuccess(
                                  context,
                                  result["message"],
                                  "Beneficiary update",
                                  const BuyAirtimePage(),
                                );

                              }
                            });
                          }
                        }
                      }
                    },
                    status: beneficiary.status,
                    context: context,
                  );
                }
            ),
          const SizedBox(height: 30,)
        ],
      )
        ),
            ));
  }
}
