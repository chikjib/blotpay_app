import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:blotpay/models/Transaction/transaction_model.dart';
import 'package:blotpay/providers/TransactionProvider/transaction_provider.dart';
import 'package:blotpay/screens/TransactionPage/detail_page.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/currency.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:blotpay/widgets/shimmer_loader.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TransactionModelDatum> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TransactionProvider>().getTransactions();
      _filterTransactions(_searchController.text, context.read<TransactionProvider>().transactions);
    });
  }

  /// 🔍 Filter transactions by query
  void _filterTransactions(String query, List<TransactionModelDatum> allTx) {
    if (query.isEmpty) {
      setState(() => _filteredTransactions = List.from(allTx));
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredTransactions = allTx.where((tx) {
        final plan = tx.plan?.toLowerCase() ?? '';
        final amount = tx.amount.toString();
        final status = tx.status?.toLowerCase() ?? '';
        final description = tx.category?.description?.toLowerCase() ?? '';
        return plan.contains(lowerQuery) ||
            amount.contains(query) ||
            description.contains(lowerQuery) ||
            status.contains(lowerQuery);
      }).toList();
    });
  }
  /// ✅ Status color text
  Widget _buildStatus(String status) {
    switch (status) {
      case "pending":
        return Text("Pending", style: TextStyle(color: amber, fontWeight: FontWeight.bold, fontSize: 12));
      case "confirmed":
        return Text("Confirmed", style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 12));
      case "failed":
        return Text("Failed", style: TextStyle(color: red, fontWeight: FontWeight.bold, fontSize: 12));
      case "ignored":
        return Text("Ignored", style: TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 12));
      case "reversed":
        return Text("Reversed", style: TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 12));
      default:
        return const SizedBox();
    }
  }

  /// 📅 Format date with suffix
  String _formatDate(DateTime date) {
    final day = date.day.toString();
    final suffix = (day.endsWith('1') && day != '11')
        ? 'st'
        : (day.endsWith('2') && day != '12')
        ? 'nd'
        : (day.endsWith('3') && day != '13')
        ? 'rd'
        : 'th';
    final formatted = DateFormat("MMM yyyy").format(date);
    return "$day$suffix $formatted";
  }

  /// 📌 Single transaction item
  Widget _buildTransactionItem(TransactionModelDatum tx) {
    return GestureDetector(
      onTap: () => PageNavigator(ctx: context).nextPage(page: DetailPage(detail: tx)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: tx.subcategory?.image ?? tx.category?.image ?? "",
              height: 40,
              width: 40,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) =>
              const Icon(Icons.image_not_supported, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tx.category?.description ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatNaira(double.tryParse(tx.amount.toString()) ?? 0.0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: "Roboto",
                        fontSize: 14,
                        color: green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatus(tx.status ?? ""),
                    Text(
                      _formatDate(tx.createdAt!),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 Load More button
  Widget _buildLoadMore(TransactionProvider provider) {
    if (!provider.hasMore) return const SizedBox(); // hide permanently when no next
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: provider.status
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () async {
            await provider.getTransactions(loadMore: true);
            // 🔄 Refresh filtered list after new data
            _filterTransactions(_searchController.text, provider.transactions);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            "Load More",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: black),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            final transactions = provider.transactions;

            // Always keep filtered list in sync with provider
            if (_searchController.text.isEmpty) {
              _filteredTransactions = List.from(transactions);
            }

            // 🔄 Shimmer on first load
            if (provider.status && transactions.isEmpty) {
              return ListView.builder(
                itemCount: 10,
                itemBuilder: (_, __) => const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ShimmerLoader(height: 50, width: 50, radius: 25),
                  title: ShimmerLoader(height: 14, width: 120),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: ShimmerLoader(height: 12, width: 80),
                  ),
                  trailing: ShimmerLoader(height: 14, width: 60),
                ),
              );
            }

            if (transactions.isEmpty) {
              return const Center(
                child: Text(
                  "No Transactions Found!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            return Column(
              children: [
                // 🔍 Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search transactions...",
                    suffixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: myLightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (q) => _filterTransactions(q, transactions),
                ),
                const SizedBox(height: 25),

                // 📌 Transactions List + Load More
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.getTransactions(), // reload fresh
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredTransactions.length + (provider.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _filteredTransactions.length) {
                          return _buildLoadMore(provider);
                        }
                        return _buildTransactionItem(_filteredTransactions[index]);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
