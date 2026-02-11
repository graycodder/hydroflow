import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'report_ui_helpers.dart';

class MonthlyReportView extends StatelessWidget {
  final ReportEntity report;
  final String salesmanId;
  final DateTime selectedMonth;
  final VoidCallback onLeftChevronPressed;
  final VoidCallback onRightChevronPressed;
  final bool isCurrentMonth;
  final VoidCallback onExportPressed;
  final VoidCallback onSharePressed;

  const MonthlyReportView({
    super.key,
    required this.report,
    required this.salesmanId,
    required this.selectedMonth,
    required this.onLeftChevronPressed,
    required this.onRightChevronPressed,
    required this.isCurrentMonth,
    required this.onExportPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMonthlyHeader(),
        const SizedBox(height: 24),
        _buildMonthlySummaryCards(),
        const SizedBox(height: 16),
        _buildRevenueBreakdown(),
        const SizedBox(height: 16),
        _buildMonthlyBottleTracking(),
        const SizedBox(height: 16),
        _buildCustomerStatistics(),
        const SizedBox(height: 16),
        _buildStockSummary(),
        const SizedBox(height: 16),
        _buildMonthlyPerformanceMetrics(),
        const SizedBox(height: 24),
        _buildMonthlyActionButtons(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMonthlyHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildChevronButton(
              icon: Icons.chevron_left,
              onTap: onLeftChevronPressed,
            ),
            Column(
              children: [
                const Text(
                  "Monthly Report",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM y').format(selectedMonth),
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            buildChevronButton(
              icon: Icons.chevron_right,
              onTap: isCurrentMonth ? null : onRightChevronPressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCards() {
    return Row(
      children: [
        Expanded(
          child: buildLargeSummaryCard(
            title: "Total Revenue",
            value: "₹${NumberFormat('#,##,###').format(report.totalRevenue)}",
            subtitle: "${report.workingDays} working days",
            color: const Color(0xFF9155FD), // Purple
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildLargeSummaryCard(
            title: "Total Deliveries",
            value: "${report.totalDeliveries}",
            subtitle: "Cans Delivered",
            color: const Color(0xFFFF9F43), // Orange
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown() {
    return buildCard(
      title: "Revenue Breakdown",
      icon: Icons.attach_money,
      subtitle: "Monthly financial summary",
      child: Column(
        children: [
          buildRow(
            "Sales Revenue",
            "₹${NumberFormat('#,##,###').format(report.salesRevenue)}",
            isBold: true,
            valueColor: Colors.blue[700],
          ),
          buildSubRow("Cash", "₹${NumberFormat('#,##,###').format(report.cashSales)}"),
          buildSubRow("UPI/Online", "₹${NumberFormat('#,##,###').format(report.onlineSales)}"),
          const Divider(height: 24),
          buildRow("Security Deposits", "", isBold: true),
          buildSubRow(
            "Collected",
            "+₹${NumberFormat('#,##,###').format(report.securityDepositsCollected)}",
            color: Colors.green,
          ),
          buildSubRow(
            "Refunded",
            "-₹${NumberFormat('#,##,###').format(report.securityDepositsRefunded)}",
            color: Colors.red,
          ),
          buildRow(
            "Net Deposits",
            "₹${NumberFormat('#,##,###').format(report.netDeposits)}",
            isBold: true,
            valueColor: Colors.green[700],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Monthly Revenue", style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("Sales + Net Deposits", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  "₹${NumberFormat('#,##,###').format(report.totalRevenue)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBottleTracking() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0E1FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.opacity, color: Color(0xFF2962FF)),
              const SizedBox(width: 8),
              Text(
                "Monthly Bottle Tracking",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const Text(
            "Circular economy summary for the month",
            style: TextStyle(color: Color(0xFF2962FF), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSmallBottleStat("Delivered", "${report.bottlesDelivered}", Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallBottleStat("Returned", "${report.bottlesReturned}", Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Net Bottles Out This Month", style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("Added to customer inventory", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  "+${report.netBottlesOut}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text(
                  "Return Rate: ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                Text(
                  "${report.bottlesDelivered > 0 ? (report.bottlesReturned / report.bottlesDelivered * 100).toStringAsFixed(0) : 0}% bottles returned",
                  style: const TextStyle(color: Color(0xFF1A237E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBottleStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == "Delivered" ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCustomerStatistics() {
    return buildCard(
      title: "Customer Statistics",
      icon: Icons.people_outline,
      subtitle: "",
      child: Row(
        children: [
          Expanded(
            child: _buildCustomerStatBox(
              "Active",
              "${report.activeCustomers}",
              const Color(0xFFE8EAF6),
              const Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCustomerStatBox(
              "New",
              "${report.newCustomers}",
              const Color(0xFFE8F5E9),
              const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCustomerStatBox(
              "Inactive",
              "${report.inactiveCustomers}",
              const Color(0xFFF9F9F9),
              const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatBox(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStockSummary() {
    return buildCard(
      title: "Stock Summary",
      icon: Icons.inventory_2_outlined,
      subtitle: "",
      child: Column(
        children: [
          buildRow(
            "Opening Stock",
            "${report.openingStock} cans",
            valueColor: Colors.black87,
          ),
          buildRow(
            "Total Stock Loaded",
            "${report.stockLoaded} cans",
            valueColor: const Color(0xFF2E7D32),
          ),
          buildRow(
            "Total Available",
            "${report.totalAvailable} cans",
            valueColor: Colors.black,
            isBold: true,
          ),
          const Divider(height: 16),
          buildRow(
            "Total Delivered",
            "${report.deliveredStock} cans",
            valueColor: const Color(0xFF1976D2),
          ),
          buildRow("Damaged/Returned", "${report.damagedStock} cans", valueColor: Colors.red),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Stock Utilization",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${report.stockTurnover.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPerformanceMetrics() {
    return buildCard(
      title: "Performance Metrics",
      icon: Icons.show_chart,
      subtitle: "",
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildMetricBox("Avg Daily Revenue", "₹${report.avgDailyRevenue.toStringAsFixed(0)}"),
          _buildMetricBox("Avg Deliveries/Day", "${report.avgDailyDeliveries.toStringAsFixed(1)}"),
          _buildMetricBox("Avg Price/Can", "₹${report.avgPricePerCan.toStringAsFixed(0)}"),
          _buildMetricBox("Working Days", "${report.workingDays}"),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMonthlyActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onExportPressed,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              "Export Monthly Report",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11142A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      //  const SizedBox(height: 12),
        // SizedBox(
        //   width: double.infinity,
        //   height: 50,
        //   child: OutlinedButton.icon(
        //     onPressed: onSharePressed,
        //     icon: const Icon(Icons.people_outline, color: Colors.black),
        //     label: const Text(
        //       "Share with Admin",
        //       style: TextStyle(color: Colors.black, fontSize: 16),
        //     ),
        //     style: OutlinedButton.styleFrom(
        //       backgroundColor: Colors.white,
        //       side: BorderSide(color: Colors.grey[300]!),
        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
