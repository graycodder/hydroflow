import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:watermemo/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:watermemo/features/dashboard/presentation/widgets/dashboard_stat_card.dart';

class AgencyStatusCards extends StatelessWidget {
  final DashboardSummary summary;

  const AgencyStatusCards({
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
          title: "Total Sales",
          value: '₹${summary.todaySales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          subtitle: 'All Salesmen Bill Amount',
          valueColor: const Color(0xFF6200EA),
          onTap: () {},
        ),
        DashboardStatCard(
          title: 'Total Deliveries',
          value: '${summary.todayDeliveries}',
          subtitle: 'Cans Delivered Today',
          valueColor: const Color(0xFFFF6D00),
          onTap: () {},
        ),
        DashboardStatCard(
          title: "Total Collection",
          value: '₹${summary.todayCollection.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          subtitle: 'All Collections',
          valueColor: const Color(0xFF00C853),
          onTap: () {},
        ),
        DashboardStatCard(
          title: "Pending Amounts",
          value: '₹${summary.pendingAmounts.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          subtitle: 'Pending from Salesmen',
          valueColor: const Color(0xFFD50000), // Red color for pending
          onTap: () {},
        ),
        DashboardStatCard(
          title: 'Active Customers',
          value: '${summary.activeCustomers}',
          subtitle: 'Total Active Customers',
          valueColor: const Color(0xFF00B8D4),
          onTap: () {},
        ),
        DashboardStatCard(
          title: 'Inactive Customers',
          value: '${summary.inactiveCustomers}',
          subtitle: 'Total Inactive Customers',
          valueColor: Colors.blueGrey,
          onTap: () {},
        ),
      ],
    );
  }
}
