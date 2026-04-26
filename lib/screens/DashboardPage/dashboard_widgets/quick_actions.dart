import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../styles/colors.dart';
import '../../../utils/routers.dart';
import '../../ServicesPage/atc_page.dart';
import '../../ServicesPage/bulksms_page.dart';
import '../../ServicesPage/buy_airtime_page.dart';
import '../../ServicesPage/buy_data_page.dart';
import '../../ServicesPage/cable_tv_page.dart';
import '../../ServicesPage/electricity_page.dart';
import '../../ServicesPage/exam_page.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionItem(context, LucideIcons.smartphone, "Airtime", const BuyAirtimePage()),
              _actionItem(context, LucideIcons.wifi, "Data", const BuyDataPage()),
              _actionItem(context, LucideIcons.tv, "Cable", const CableTvPage()),
              _actionItem(context, Icons.more_horiz, "More", () => _showPayBillsSheet(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionItem(BuildContext ctx, IconData icon, String label, dynamic action) {
    return GestureDetector(
        onTap: () {
          if (action is Widget) {
            // Navigate to the page
            PageNavigator(ctx: ctx).nextPage(page: action);
          } else if (action is Function) {
            // Call the callback function
            action();
          }
        },
      child: Column(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

void _showPayBillsSheet(BuildContext context) {
    final DraggableScrollableController _controller =
    DraggableScrollableController();
    final sheetContext = context;
    bool _isClosing = false;
    bool _isAnimating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: myLightGrey,
      builder: (context) {
        return DraggableScrollableSheet(
          controller: _controller,
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.55,
          maxChildSize: 0.55,
          builder: (context, scrollController) {
            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final size = notification.extent;

                if (size > 0.55 && !_isAnimating) {
                  _isAnimating = true;
                  _controller
                      .animateTo(
                    0.55,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
                      .whenComplete(() {
                    _isAnimating = false;
                  });
                }

                if (size < 0.55 && !_isClosing) {
                  _isClosing = true;
                  Navigator.of(sheetContext).pop();
                }

                return true;
              },
              child: SingleChildScrollView(
                controller: scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "More",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "What will you like to do?",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        buildOptionTile(
                          LucideIcons.smartphone,
                          "Airtime To Cash",
                          "Convert airtime to cash",
                              () {
                            PageNavigator(
                              ctx: context,
                            ).nextPage(page: const AtcPage());
                          },
                        ),
                        buildOptionTile(
                          LucideIcons.graduationCap,
                          "Exam Pins",
                          "Buy exam pins",
                              () {
                            PageNavigator(
                              ctx: context,
                            ).nextPage(page: const ExamPage());
                          },
                        ),
                        buildOptionTile(
                          LucideIcons.building2,
                          "Electricity",
                          "Buy electricity units",
                              () {
                            PageNavigator(
                              ctx: context,
                            ).nextPage(page: const ElectricityPage());
                          },
                        ),
                        buildOptionTile(
                          FontAwesomeIcons.commentSms,
                          "Bulk Sms",
                          "Send sms to your family and loved ones",
                              () {
                            PageNavigator(
                              ctx: context,
                            ).nextPage(page: const BulkSmsPage());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildOptionTile(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return Card(
      color: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 0,
      shadowColor: white,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: myLightGrey,
          radius: 30,
          child: Icon(icon, color: black, size: 30),
        ),
        title: Text(title, style: TextStyle(color: black, fontSize: 16)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }
