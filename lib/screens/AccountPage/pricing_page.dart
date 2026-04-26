import 'dart:convert';
import 'package:blotpay/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../styles/colors.dart';
import '../../utils/currency.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  List<dynamic> lists = [];
  bool isLoading = false;

  String baseUrl = AppConstant.baseUrl;

  @override
  void initState() {
    super.initState();
    getList();
  }


  Future<void> getList() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$baseUrl/get-prices/"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          lists = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint("Error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,

        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Pricing List",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    spreadRadius: 1,
                    color: Colors.black12,
                  )
                ],
              ),
              child: Column(
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 12),
                            Text("Loading..."),
                          ],
                        ),
                      ),
                    ),
                  ...lists.asMap().entries.map((entry) {
                    // final index = entry.key;
                    final list = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.network(
                                list['image'] ?? "",
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${list['title']} "
                                    "${list['category']['type'] == 'data' ? 'Data' : list['category']['type'] == 'airtime' ? 'Airtime' : ''}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columns: const [
                                DataColumn(label: Text("Plan")),
                                DataColumn(label: Text("Normal")),
                                DataColumn(label: Text("Agent")),
                                DataColumn(label: Text("Reseller")),
                                DataColumn(label: Text("API")),
                              ],
                              rows: list['category']['type'] == 'electricity' ||
                                  list['category']['type'] == 'airtime'
                                  ? [
                                DataRow(cells: [
                                  const DataCell(Text("Discount")),
                                  DataCell(Text("${list['products']['amount1']}%")),
                                  DataCell(Text("${list['products']['amount2']}%")),
                                  DataCell(Text("${list['products']['amount3']}%")),
                                  DataCell(Text("${list['products']['amount4']}%")),
                                ]),
                              ]
                                  : List.generate(
                                list['products'][0]['data'].length,
                                    (i) {
                                  final product = list['products'][0]['data'][i];
                                  return DataRow(cells: [
                                    DataCell(Text(product['plan'].toString())),
                                    DataCell(Text(formatNaira(double.tryParse(product['amount1'].toString())),style: TextStyle(fontFamily: 'Roboto'),)),
                                    DataCell(Text(formatNaira(double.tryParse(product['amount2'].toString())),style: TextStyle(fontFamily: 'Roboto'),)),
                                    DataCell(Text(formatNaira(double.tryParse(product['amount3'].toString())),style: TextStyle(fontFamily: 'Roboto'),)),
                                    DataCell(Text(formatNaira(double.tryParse(product['amount4'].toString())),style: TextStyle(fontFamily: 'Roboto'),)),
                                  ]);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
