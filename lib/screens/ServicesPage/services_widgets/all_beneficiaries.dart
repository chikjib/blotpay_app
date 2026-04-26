import 'package:blotpay/screens/DashboardPage/dashboard.dart';
import 'package:blotpay/screens/DashboardPage/dashboard_page.dart';
import 'package:blotpay/screens/ServicesPage/services_widgets/edit_beneficiary.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../models/User/beneficiary_model.dart';
import '../../../providers/PackageProvider/beneficiary_provider.dart';
import '../../../utils/routers.dart';

class AllBeneficiariesPage extends StatefulWidget {
  final int? categoryId;

  const AllBeneficiariesPage({super.key, required this.categoryId});

  @override
  State<AllBeneficiariesPage> createState() => _AllBeneficiariesPageState();
}

class _AllBeneficiariesPageState extends State<AllBeneficiariesPage> {
  late Future<BeneficiaryModel> beneficiaries;

  List<BeneficiaryData> allBeneficiaries = [];
  List<BeneficiaryData> filteredBeneficiaries = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    beneficiaries = BeneficiaryProvider().getAllBeneficiaries(
      categoryId: int.parse(widget.categoryId.toString()),
      context: context,
    );
  }

  void filterBeneficiaries(String query) {
    final results = allBeneficiaries.where((b) {
      final phone = b.phoneNo?.toLowerCase() ?? "";
      final name = b.name?.toLowerCase() ?? "";
      final input = query.toLowerCase();

      return phone.contains(input) || name.contains(input);
    }).toList();

    setState(() {
      filteredBeneficiaries = results;
    });
  }

  void showConfirmDeleteSheet(BeneficiaryData beneficiary, BuildContext context) {
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
                "Are you sure you delete this beneficiary?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
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
                    child: Consumer<BeneficiaryProvider>(
                      builder: (context, beneficiary_delete, child) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: beneficiary_delete.status
                              ? null
                              : () async {

                                final result = await beneficiary_delete.deleteBeneficiary(
                                  beneficiaryId: beneficiary.id.toString(),
                                  context: context,
                                );

                                if (result['success'] == true) {
                                  customDialogSuccess(
                                    context,
                                    result['message'],
                                    "Beneficiary",
                                    const Dashboard(), // redirect after closing
                                  );
                                } else {
                                  customDialogError(
                                    context,
                                    result['message'],
                                    "Beneficiary",
                                  );
                                }

                          },
                          child: beneficiary_delete.status
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


  void showBeneficiaryOptions(BeneficiaryData beneficiary) {
    showModalBottomSheet(
      backgroundColor: myLightGrey,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Text(
                  beneficiary.name != null
                      ? beneficiary.name![0].toUpperCase()
                      : beneficiary.phoneNo![1],
                  style: const TextStyle(fontSize: 22),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                beneficiary.name ?? beneficiary.phoneNo ?? "",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                beneficiary.phoneNo ?? "",
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 25),

              ListTile(
                leading: const Icon(LucideIcons.pencil),
                tileColor: Colors.white,
                title: const Text("Edit Name"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context); // close bottom sheet first

                  Future.delayed(const Duration(milliseconds: 200), () {
                    PageNavigator(ctx: this.context).nextPage(
                      page: EditBeneficiary(beneficiary: beneficiary),
                    );
                  });
                },
              ),

              const SizedBox(height: 20,),

              ListTile(
                leading: const Icon(LucideIcons.trash2),
                tileColor: Colors.white,
                title: const Text("Delete Beneficiary"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  showConfirmDeleteSheet(beneficiary,context);
                  // final beneficiary_provider = Provider.of<BeneficiaryProvider>(
                  //   context,
                  //   listen: false,
                  // );
                  // final result = await beneficiary_provider.deleteBeneficiary(beneficiaryId: beneficiary.id.toString(), context: context);
                  //
                  // if (result['success'] == true) {
                  //   customDialogSuccess(
                  //     context,
                  //     result['message'],
                  //     "Delete Beneficiary",
                  //     const Dashboard(), // redirect after closing
                  //   );
                  // } else {
                  //   customDialogError(
                  //     context,
                  //     result['message'],
                  //     "Delete Beneficiary",
                  //   );
                  // }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            PageNavigator(ctx: context).nextPageOnly(page: const Dashboard());
          },
        ),
        title: const Text("Beneficiaries"),
      ),

      body: FutureBuilder<BeneficiaryModel>(
        future: beneficiaries,
        builder: (context, snapshot) {
          /// Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Error
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load beneficiaries"));
          }

          /// Empty
          if (!snapshot.hasData ||
              snapshot.data?.data == null ||
              snapshot.data!.data!.isEmpty) {
            return const Center(child: Text("No beneficiaries found"));
          }

          if (allBeneficiaries.isEmpty) {
            allBeneficiaries = snapshot.data!.data!;
            filteredBeneficiaries = allBeneficiaries;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  onChanged: filterBeneficiaries,
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBeneficiaries.length,
                  itemBuilder: (context, index) {
                    final beneficiary = filteredBeneficiaries[index];

                    return ListTile(
                      onTap: () {
                        Navigator.pop(context, beneficiary); // 👈 send data back
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          beneficiary.name != null
                              ? beneficiary.name![0].toUpperCase()
                              : beneficiary.phoneNo![1],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      title: Text(
                        beneficiary.phoneNo ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        beneficiary.name ?? beneficiary.phoneNo ?? "",
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showBeneficiaryOptions(beneficiary);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
