import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
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
                            subReport.salesmanName ?? "Unknown",
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
                      "Cash in Hand (Today)",
                      "₹${(subReport.cashInHand - subReport.settlementAmountToday).toStringAsFixed(0)}",
                      Colors.green,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      "Old Balance",
                      "₹${subReport.salesmanPreviousBalance.toStringAsFixed(0)}",
                      subReport.salesmanPreviousBalance > 0 ? Colors.red : Colors.grey,
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: subReport.isSettled
                            ? null
                            : () => _showSettlementDialog(context, subReport),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subReport.isSettled
                              ? Colors.grey[300]
                              : const Color(0xFF2962FF),
                          foregroundColor: subReport.isSettled
                              ? Colors.grey[600]
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          subReport.isSettled ? "Settled" : "Receive Payment",
                        ),
                      ),
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

  void _showSettlementDialog(BuildContext context, ReportEntity subReport) {
    if (subReport.salesmanId == null) return;

    final double totalOutstanding = subReport.cashInHand + subReport.salesmanPreviousBalance - subReport.settlementAmountToday;
    
    final TextEditingController amountController = TextEditingController(
      text: totalOutstanding > 0
          ? totalOutstanding.toStringAsFixed(0)
          : "",
    );

    bool isFinalSettlement = true;

    final reportsBloc = context.read<ReportsBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: reportsBloc,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Settle with ${subReport.salesmanName}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected Today:'),
                          Text('₹${subReport.cashInHand.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (subReport.settlementAmountToday > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Already Paid:'),
                            Text(
                              '- ₹${subReport.settlementAmountToday.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Old Balance:'),
                          Text(
                            '₹${subReport.salesmanPreviousBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: subReport.salesmanPreviousBalance > 0 ? Colors.red : Colors.green,
                              fontWeight: subReport.salesmanPreviousBalance > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Outstanding:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${totalOutstanding.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount Received Now (₹)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Any unpaid amount will be added to the salesman\'s future balance.',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text("Mark as Final Settlement", style: TextStyle(fontSize: 14)),
                        subtitle: const Text("Only check this if the salesman has finished paying for today.", style: TextStyle(fontSize: 11)),
                        value: isFinalSettlement,
                        onChanged: (val) {
                          setState(() {
                            isFinalSettlement = val ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final double? amount = double.tryParse(amountController.text);
                      if (amount != null && amount >= 0) {
                        context.read<ReportsBloc>().add(
                          SettleSalesmanDailyCash(
                            salesmanId: subReport.salesmanId!,
                            date: selectedDate,
                            amount: amount,
                            recordedBy: agencyId,
                            isFinal: isFinalSettlement,
                          ),
                        );
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFinalSettlement ? const Color(0xFF2962FF) : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isFinalSettlement ? 'Confirm Final Settlement' : 'Record Partial Payment'),
                  ),
                ],
              );
            },
          ),
        );
      },
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
      title: "Agency Stock Reconciliation",
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
            " - Total Damaged",
            "-${report.damagedStock} cans",
            valueColor: Colors.red,
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
      title: "Agency Bottle Reconciliation",
      icon: Icons.loop,
      subtitle: "Circular economy tracking for today",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildStatBox(
                  "Total Delivered",
                  "${report.bottlesDelivered}",
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildStatBox(
                  "Total Returned",
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
      title: "Agency Financial Summary",
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
                const SizedBox(height: 4),
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
      title: "Agency Performance Metrics",
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
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${report.avgPricePerCan.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
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
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${report.stockTurnover.toStringAsFixed(0)}%",
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
