import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:watermemo/features/reports/domain/entities/report_entity.dart';
import 'package:watermemo/features/reports/presentation/bloc/reports_bloc.dart';
import 'report_ui_helpers.dart';

class AgencyDailyReportView extends StatelessWidget {
  final ReportEntity report;
  final String agencyId;
  final DateTime selectedDate;
  final VoidCallback onSharedPressed;
  final VoidCallback onSelectDatePressed;
  final VoidCallback onLeftChevronPressed;
  final VoidCallback onRightChevronPressed;
  final bool isCurrentDate;

  const AgencyDailyReportView({
    super.key,
    required this.report,
    required this.agencyId,
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
        _buildSalesmanBreakdown(context), // Passed context here
        const SizedBox(height: 16),
        _buildStockReconciliation(),
        const SizedBox(height: 16),
        _buildBottleReconciliation(),
        const SizedBox(height: 16),
        _buildFinancialSummary(),
        const SizedBox(height: 16),
        _buildPerformanceMetrics(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSalesmanBreakdown(BuildContext context) {
    if (report.subReports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Salesman Breakdown",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: report.subReports.map((subReport) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (subReport.salesmanName?.isNotEmpty == true)
                                ? subReport.salesmanName![0].toUpperCase() +
                                    subReport.salesmanName!.substring(1)
                                : "Unknown",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subReport.isSettled)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildBreakdownRow(
                      "Total Sales",
                      "₹${subReport.totalRevenue.toStringAsFixed(0)}",
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Deliveries",
                      "${subReport.totalDeliveries} cans",
                      Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Cash in Hand (Today)",
                      "₹${subReport.cashInHand.toStringAsFixed(0)}",
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Old Balance",
                      "₹${subReport.salesmanPreviousBalance.toStringAsFixed(0)}",
                      subReport.salesmanPreviousBalance > 0 ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Amount Settled",
                      "-₹${subReport.settlementAmountToday.toStringAsFixed(0)}",
                      subReport.settlementAmountToday > 0 ? Colors.green : Colors.grey,
                    ),
                    const Divider(height: 16),
                    _buildBreakdownRow(
                      "Total Outstanding",
                      "₹${subReport.pendingCashBalance.clamp(0.0, double.infinity).toStringAsFixed(0)}",
                      subReport.pendingCashBalance > 0 ? Colors.red : Colors.green,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "UPI Collected",
                      "₹${subReport.upiCollections.toStringAsFixed(0)}",
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Closing Stock",
                      "${subReport.closingStock} cans",
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Damaged",
                      "${subReport.damagedStock} cans",
                      Colors.red,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Agency Daily Report",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange, // Distinct color for Agency View
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onSelectDatePressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.blue,
              ),
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
                title: "Total Collected",
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
                title: "Total Credit Given",
                value: "₹${report.totalCreditPending.toStringAsFixed(0)}",
                subtitle: "Pending payment",
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildLargeSummaryCard(
                title: "Total Deliveries",
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
      subtitle: "Aggregated opening to closing stock",
      child: Column(
        children: [
          buildRow("Total Opening Stock", "${report.openingStock} cans"),
          buildRow(
            " + Total Stock Loaded",
            "+${report.stockLoaded} cans",
            valueColor: Colors.green,
          ),
          const Divider(height: 24),
          buildRow(
            "Total Available",
            "${report.totalAvailable} cans",
            isBold: true,
          ),
          const Divider(height: 24),
          buildRow(
            " - Total Delivered",
            "-${report.deliveredStock} cans",
            valueColor: Colors.red,
          ),
          buildRow(
            " - Warehouse Damaged",
            "-${report.damagedStock} cans",
            valueColor: Colors.red,
          ),
          buildRow(
            "   (Salesman Damaged: ${report.salesmanDamagedStock} cans)",
            "",
            valueColor: Colors.orange,
          ),
          const Divider(height: 24),
          buildRow(
            "Total Closing Stock",
            "${report.closingStock} cans",
            isBold: true,
            valueColor: Colors.blue,
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
                  "${report.bottlesDelivered}",
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildStatBox(
                  "Returned",
                  "${report.manualBottlesCollected}",
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                (report.netBottlesOut > 0
                    ? "+${report.netBottlesOut}"
                    : "${report.netBottlesOut}"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: report.netBottlesOut > 0 ? Colors.orange : Colors.teal,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Return Rate (Warehouse)",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                "${report.bottlesDelivered > 0 ? (report.manualBottlesCollected / report.bottlesDelivered * 100).toStringAsFixed(0) : 0}%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
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
                buildRow(
                  "• UPI/Online",
                  "₹${report.onlineSales.toStringAsFixed(0)}",
                ),
              ],
            ),
          ),
          buildRow(
            "Total Credit Given",
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
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      buildRow("  - Cash", "₹${report.securityDepositsCollectedCash.toStringAsFixed(0)}"),
                      buildRow("  - UPI/Online", "₹${report.securityDepositsCollectedOnline.toStringAsFixed(0)}"),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                buildRow(
                  "• Refunded",
                  "-₹${report.securityDepositsRefunded.toStringAsFixed(0)}",
                  valueColor: Colors.red,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      buildRow("  - Cash", "₹${report.securityDepositsRefundedCash.toStringAsFixed(0)}"),
                      buildRow("  - UPI/Online", "₹${report.securityDepositsRefundedOnline.toStringAsFixed(0)}"),
                    ],
                  ),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Cash in Hand",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        "(Cash Sales + Deposits - Refunds)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "₹${report.cashInHand.toStringAsFixed(0)}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total UPI Collections",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        "(To be transferred to bank)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "₹${report.upiCollections.toStringAsFixed(0)}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
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
                  const Text(
                    "Avg Price/Can",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${report.avgPricePerCan.toStringAsFixed(0)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  const Text(
                    "Stock Turnover",
                    maxLines: 1,
          overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${report.stockTurnover.toStringAsFixed(0)}%",
                    maxLines: 1,
          overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
