import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/Transaction/transaction_model.dart';
import '../../../providers/TransactionProvider/transaction_provider.dart';
import '../../../styles/colors.dart';
import '../../../utils/currency.dart';
import '../../../utils/routers.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../TransactionPage/detail_page.dart';
import '../../TransactionPage/transaction_page.dart';
import '../../../widgets/custom_progress.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final txs = provider.transactions;
    final isLoading = provider.status;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Transactions",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => PageNavigator(ctx: context).nextPage(
                page: const TransactionPage(),
              ),
              child: Row(
                children: const [
                  Text("View All", style: TextStyle(fontSize: 15)),
                  SizedBox(width: 10),
                  Icon(LucideIcons.chevronRight, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // ✅ Logic: Cache → No shimmer. Empty + loading → Shimmer.
        if (txs.isEmpty && isLoading)
          _buildShimmer()
        else if (txs.isEmpty)
          const Center(child: Text("No transactions found"))
        else
          Column(
            children: txs.take(6).map((tx) {
              return GestureDetector(
                onTap: () => PageNavigator(ctx: context).nextPage(
                  page: DetailPage(detail: tx),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CachedNetworkImage(
                    imageUrl:
                    tx.subcategory?.image ?? tx.category?.image ?? "",
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) =>
                        Image.asset('assets/images/default_image.png'),
                  ),
                  title: Text(
                    tx.category?.description ?? "-",
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    tx.status ?? "-",
                    style: TextStyle(
                      color: tx.status == "confirmed"
                          ? green
                          : tx.status == "failed"
                          ? red
                          : tx.status == "pending"
                          ? amber
                          : tx.status == "reversed"
                          ? purple
                          : amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNaira(double.tryParse(tx.amount ?? "0") ?? 0.0),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          color: green,
                        ),
                      ),
                      Text(
                        tx.createdAt != null
                            ? DateFormat("d MMM yyyy").format(tx.createdAt!)
                            : "-",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}


Widget _buildShimmer() {
  return Column(
    children: List.generate(6, (index) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const ShimmerLoader(height: 50, width: 50, radius: 25),
        title: const ShimmerLoader(height: 14, width: 120),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 6.0),
          child: ShimmerLoader(height: 12, width: 80),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            ShimmerLoader(height: 14, width: 60),
            SizedBox(height: 6),
            ShimmerLoader(height: 12, width: 40),
          ],
        ),
      );
    }),
  );
}

