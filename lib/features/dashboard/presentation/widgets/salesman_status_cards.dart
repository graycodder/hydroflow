import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:watermemo/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:watermemo/features/dashboard/presentation/widgets/dashboard_stat_card.dart';

class SalesmanStatusCards extends StatelessWidget {
  final DashboardSummary summary;

  const SalesmanStatusCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 1.0,
      children: [
        DashboardStatCard(
          title: 'Current Stock',
          value: '${summary.currentStock}',
          subtitle: 'Cans in Van',
          valueColor: const Color(0xFF2962FF),
          onTap: () {},
        ),
        DashboardStatCard(
          title: 'My Deliveries',
          value: '${summary.todayDeliveries}',
          subtitle: 'Cans Delivered',
          valueColor: const Color(0xFFFF6D00),
          onTap: () {},
        ),
        DashboardStatCard(
          title: "My Sales",
          value: '₹${summary.todaySales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          subtitle: 'My Bill Amount',
          valueColor: const Color(0xFF6200EA),
          onTap: () {},
        ),
        DashboardStatCard(
          title: "My Collection",
          value: '₹${summary.todayCollection.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          subtitle: 'Cash + UPI',
          valueColor: const Color(0xFF00C853),
          onTap: () {},
        ),
      ],
    );
  }
}
