import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'report_ui_helpers.dart';

class DailyReportView extends StatelessWidget {
  final ReportEntity report;
  final String salesmanId;
  final DateTime selectedDate;
  final VoidCallback onSharedPressed;
  final VoidCallback onSelectDatePressed;
  final VoidCallback onLeftChevronPressed;
  final VoidCallback onRightChevronPressed;
  final bool isCurrentDate;

  const DailyReportView({
    super.key,
    required this.report,
    required this.salesmanId,
    required this.selectedDate,
    required this.onSharedPressed,
    required this.onSelectDatePressed,
    required this.onLeftChevronPressed,
    required this.onRightChevronPressed,
    required this.isCurrentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildSummaryCards(),
        const SizedBox(height: 16),
        _buildStockReconciliation(),
        const SizedBox(height: 16),
        _buildBottleReconciliation(),
        const SizedBox(height: 16),
        _buildFinancialSummary(),
        const SizedBox(height: 16),
        _buildPerformanceMetrics(),
        const SizedBox(height: 24),
        // Action buttons are currently commented out in the parent, keeping that structure
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return 
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "End of Day Report",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onSelectDatePressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(selectedDate),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.blue),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildLargeSummaryCard(
                title: "Total Sales",
                value: "₹${report.totalRevenue.toStringAsFixed(0)}",
                subtitle: "Total bill value",
                color: const Color(0xFF2962FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildLargeSummaryCard(
                title: "Collected",
                value: "₹${report.totalCollected.toStringAsFixed(0)}",
                subtitle: "Cash + UPI",
                color: const Color(0xFF00C853),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildLargeSummaryCard(
                title: "Credit Given",
                value: "₹${report.totalCreditPending.toStringAsFixed(0)}",
                subtitle: "Pending payment",
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildLargeSummaryCard(
                title: "Deliveries",
                value: "${report.totalDeliveries}",
                subtitle: "Cans delivered",
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockReconciliation() {
    return buildCard(
      title: "Stock Reconciliation",
      icon: Icons.inventory_2_outlined,
      subtitle: "Opening to closing stock summary",
      child: Column(
        children: [
          buildRow("Opening Stock", "${report.openingStock} cans"),
          buildRow(" + Stock Loaded", "+${report.stockLoaded} cans", valueColor: Colors.green),
          const Divider(height: 24),
          buildRow("Total Available", "${report.totalAvailable} cans", isBold: true),
          const Divider(height: 24),
          buildRow(" - Delivered", "-${report.deliveredStock} cans", valueColor: Colors.red),
          buildRow(" - Damaged/Return", "-${report.damagedStock} cans", valueColor: Colors.red),
          const Divider(height: 24),
          buildRow(
            "Closing Stock",
            "${report.closingStock} cans",
            isBold: true,
            valueColor: Colors.blue,
          ),
          if (report.stockMismatch != 0)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Stock Mismatch: Expected ${report.closingStock + report.stockMismatch} | Actual ${report.closingStock}",
                      style: const TextStyle(color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottleReconciliation() {
    return buildCard(
      title: "Bottle Reconciliation",
      icon: Icons.loop,
      subtitle: "Circular economy tracking for today",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildStatBox(
                  "Delivered",
                  "↓ ${report.bottlesDelivered}",
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildStatBox("Returned", "↑ ${report.bottlesReturned}", Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Net Bottles Out Today",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
              Text(
                (report.netBottlesOut > 0 ? "+${report.netBottlesOut}" : "${report.netBottlesOut}"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: report.netBottlesOut > 0 ? Colors.orange : Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue[100]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Bottles with Customers", style: TextStyle(color: Colors.grey)),
                    Text(
                      "All-time outstanding",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  "${report.totalBottlesWithCustomers}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return buildCard(
      title: "Financial Summary",
      icon: Icons.attach_money,
      subtitle: "Revenue breakdown by payment mode",
      child: Column(
        children: [
          buildRow(
            "Total Sales Value",
            "₹${report.salesRevenue.toStringAsFixed(0)}",
            isBold: true,
            valueColor: Colors.blue,
          ),
          buildRow(
            "Total Collected",
            "₹${report.totalCollected.toStringAsFixed(0)}",
            isBold: true,
            valueColor: Colors.green,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Column(
              children: [
                buildRow("• Cash", "₹${report.cashSales.toStringAsFixed(0)}"),
                buildRow("• UPI/Online", "₹${report.onlineSales.toStringAsFixed(0)}"),
              ],
            ),
          ),
          buildRow(
            "Credit Given",
            "₹${report.totalCreditPending.toStringAsFixed(0)}",
            isBold: true,
            valueColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          buildRow("Security Deposits", ""),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Column(
              children: [
                buildRow(
                  "• Collected",
                  "+₹${report.securityDepositsCollected.toStringAsFixed(0)}",
                  valueColor: Colors.green,
                ),
                buildRow(
                  "• Refunded",
                  "-₹${report.securityDepositsRefunded.toStringAsFixed(0)}",
                  valueColor: Colors.red,
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          buildRow(
            "Net Deposits",
            "₹${report.netDeposits.toStringAsFixed(0)}",
            valueColor: Colors.green,
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cash in Hand", style: TextStyle(fontSize: 16, color: Colors.black87)),
                    Text(
                      "(Cash Sales + Deposits - Refunds)",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  "₹${report.cashInHand.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("UPI Collections", style: TextStyle(fontSize: 16, color: Colors.black87)),
                    Text("(To be transferred to bank)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  "₹${report.upiCollections.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return buildCard(
      title: "Performance Metrics",
      icon: Icons.show_chart,
      subtitle: "",
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Avg Price/Can", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    "₹${report.avgPricePerCan.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Stock Turnover", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    "${report.stockTurnover.toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
