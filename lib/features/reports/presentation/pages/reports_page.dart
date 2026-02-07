import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String salesmanId = '';
    String salesmanName = '';
    if (authState is AuthAuthenticated) {
      salesmanId = authState.salesman.id;
      salesmanName = authState.salesman.name;
    }

    return BlocProvider(
      create: (context) => sl<ReportsBloc>()..add(LoadDailyReport(salesmanId)),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const HydroFlowAppBar(),
        body: BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, state) {
            if (state is ReportsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReportsFailure) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is ReportsLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(state.report),
                    const SizedBox(height: 24),
                    _buildSummaryCards(state.report),
                    const SizedBox(height: 16),
                    _buildStockReconciliation(state.report),
                    const SizedBox(height: 16),
                    _buildBottleReconciliation(state.report),
                    const SizedBox(height: 16),
                    _buildFinancialSummary(state.report),
                    const SizedBox(height: 16),
                    _buildPerformanceMetrics(state.report),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                     const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return const Center(child: Text("Initializing..."));
          },
        ),
        bottomNavigationBar: const AppBottomBar(currentIndex: 5), // Index 5 for Reports
      ),
    );
  }

  Widget _buildHeader(ReportEntity report) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "End of Day Report",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, d MMMM y').format(report.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined),
          label: const Text("Export"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: BorderSide(color: Colors.grey[300]!),
          ),
        )
      ],
    );
  }

  Widget _buildSummaryCards(ReportEntity report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: "Total Sales",
                value: "₹${report.totalRevenue.toStringAsFixed(0)}",
                subtitle: "Total Bill Value",
                color: const Color(0xFF2962FF), // Blue
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: "Collected",
                value: "₹${report.totalCollected.toStringAsFixed(0)}",
                subtitle: "Cash + UPI Received",
                color: const Color(0xFF00C853), // Green
                textColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             Expanded(
              child: _buildSummaryCard(
                title: "Credit Given",
                value: "₹${report.totalCreditPending.toStringAsFixed(0)}",
                subtitle: "Pending Payment",
                color: Colors.orange,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: "Deliveries",
                value: "${report.totalDeliveries}",
                subtitle: "Cans Delivered",
                color: Colors.teal, 
                textColor: Colors.white,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(title, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16)),
           const SizedBox(height: 8),
           Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
           const SizedBox(height: 4),
           Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
         ],
      ),
    );
  }

  Widget _buildStockReconciliation(ReportEntity report) {
    return _buildCard(
      title: "Stock Reconciliation",
      icon: Icons.inventory_2_outlined,
      subtitle: "Opening to closing stock summary",
      child: Column(
        children: [
          _buildRow("Opening Stock", "${report.openingStock} cans"),
          _buildRow(" + Stock Loaded", "+${report.stockLoaded} cans", valueColor: Colors.green),
          const Divider(height: 24),
          _buildRow("Total Available", "${report.totalAvailable} cans", isBold: true),
          const Divider(height: 24),
          _buildRow(" - Delivered", "-${report.deliveredStock} cans", valueColor: Colors.red),
          _buildRow(" - Damaged/Return", "-${report.damagedStock} cans", valueColor: Colors.red),
          const Divider(height: 24),
          _buildRow("Closing Stock", "${report.closingStock} cans", isBold: true, valueColor: Colors.blue),
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
                 Expanded(child: Text("Stock Mismatch: Expected ${report.closingStock + report.stockMismatch} | Actual ${report.closingStock}", style: const TextStyle(color: Colors.brown))),
                ],
              ),
            )
        ],
      ),
    );
  }
  
  Widget _buildBottleReconciliation(ReportEntity report) {
    return _buildCard(
        title: "Bottle Reconciliation", 
        icon: Icons.loop, 
        subtitle: "Circular economy tracking for today",
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatBox("Delivered", "↓ ${report.bottlesDelivered}", Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("Returned", "↑ ${report.bottlesReturned}", Colors.teal)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Net Bottles Out Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                Text(
                  (report.netBottlesOut > 0 ? "+${report.netBottlesOut}" : "${report.netBottlesOut}"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: report.netBottlesOut > 0 ? Colors.orange : Colors.teal)
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
                       Text("All-time outstanding", style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   ),
                   Text("${report.totalBottlesWithCustomers}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                 ],
               ),
             )
          ],
        )
    );
  }

  Widget _buildFinancialSummary(ReportEntity report) {
    return _buildCard(
      title: "Financial Summary",
      icon: Icons.attach_money,
      subtitle: "Revenue breakdown by payment mode",
      child: Column(
        children: [
          _buildRow("Total Sales Value", "₹${report.salesRevenue.toStringAsFixed(0)}", isBold: true, valueColor: Colors.blue),
          _buildRow("Total Collected", "₹${report.totalCollected.toStringAsFixed(0)}", isBold: true, valueColor: Colors.green),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Column(
              children: [
                _buildRow("• Cash", "₹${report.cashSales.toStringAsFixed(0)}"),
                _buildRow("• UPI/Online", "₹${report.onlineSales.toStringAsFixed(0)}"),
              ],
            ),
          ),
          _buildRow("Credit Given", "₹${report.totalCreditPending.toStringAsFixed(0)}", isBold: true, valueColor: Colors.orange),
          const SizedBox(height: 16),
           _buildRow("Security Deposits", ""),
           Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Column(
              children: [
                _buildRow("• Collected", "+₹${report.securityDepositsCollected.toStringAsFixed(0)}", valueColor: Colors.green),
                _buildRow("• Refunded", "-₹${report.securityDepositsRefunded.toStringAsFixed(0)}", valueColor: Colors.red),
                //// Add total held
                //const SizedBox(height: 4),
                //_buildRow("• Total Held", "₹${report.totalDepositsHeld.toStringAsFixed(0)}", isBold: true, valueColor: Colors.blue[800]),
              ],
            ),
          ),
          const Divider(height: 24),
          _buildRow("Net Deposits", "₹${report.netDeposits.toStringAsFixed(0)}", valueColor: Colors.green),
          
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
                     Text("(Cash Sales + Deposits - Refunds)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text("₹${report.cashInHand.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
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
                Text("₹${report.upiCollections.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
          ),
        ],
      )
    );
  }
  
  Widget _buildPerformanceMetrics(ReportEntity report) {
      return _buildCard(
        title: "Performance Metrics", 
        icon: Icons.show_chart, 
        subtitle: "",
        child: Row(
          children: [
             Expanded(
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                 child: Column(
                   children: [
                     const Text("Avg Price/Can", style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 8),
                     Text("₹${report.avgPricePerCan.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                 child: Column(
                   children: [
                     const Text("Stock Turnover", style: TextStyle(color: Colors.grey)),
                     const SizedBox(height: 8),
                     Text("${report.stockTurnover.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
             ),
          ],
        )
      );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
             onPressed: () {}, 
             icon: const Icon(Icons.person_outline, color: Colors.white),
             label: const Text("Submit Report to Admin", style: TextStyle(color: Colors.white, fontSize: 16)),
             style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFF11142A), // Dark Navy
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
          ),
        ),
        const SizedBox(height: 12),
         SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
             onPressed: () {}, 
             icon: const Icon(Icons.calendar_today_outlined, color: Colors.black),
             label: const Text("View Previous Reports", style: TextStyle(color: Colors.black, fontSize: 16)),
             style: OutlinedButton.styleFrom(
               backgroundColor: Colors.white,
               side: BorderSide(color: Colors.grey[300]!),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
  
  Widget _buildStatBox(String label, String value, Color color) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey[200]! )
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Icon(label == "Delivered" ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: color),
               const SizedBox(width: 4),
               Text(label, style: const TextStyle(color: Colors.grey)),
             ],
           ),
           const SizedBox(height: 8),
           Text(value.split(" ")[1], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
         ],
       ),
     );
  }
}
