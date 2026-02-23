import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/bottles/domain/entities/salesman_bottle_ledger_stats.dart';

class SalesmanBottleLedgerPage extends StatefulWidget {
  const SalesmanBottleLedgerPage({super.key});

  @override
  State<SalesmanBottleLedgerPage> createState() => _SalesmanBottleLedgerPageState();
}

class _SalesmanBottleLedgerPageState extends State<SalesmanBottleLedgerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final salesman = authState.salesman;
      context.read<BottleBloc>().add(LoadSalesmanBottleLedger(salesman.id, _selectedDate));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: HydroFlowLoader(isOverlay: false));
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: const HydroFlowAppBar(),
          body: BlocBuilder<BottleBloc, BottleState>(
            builder: (context, state) {
              if (state is BottleLoading || state is BottleInitial) {
                return const HydroFlowLoader(isOverlay: false);
              } else if (state is BottleFailure) {
                return Center(child: Text('Error: ${state.error}'));
              } else if (state is SalesmanBottleLoaded) {
                final stats = state.salesmanLedgerStats as SalesmanBottleLedgerStats;
                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTodayDashboardTab(stats),
                          _buildCustomerBalancesTab(stats),
                          _buildTransactionHistoryTab(stats),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Loading classic view...')); // Fallback
            },
          ),
          bottomNavigationBar: const AppBottomBar(currentIndex: 2),
        );
      },
    );
  }

  Widget _buildHeader() {
    final bool isToday = _isSameDay(_selectedDate, DateTime.now());
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Physical Bottle Ledger',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your van inventory and market flow',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Date picker button
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF2962FF).withOpacity(0.08)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFF2962FF).withOpacity(0.3)
                            : Colors.orange.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isToday ? const Color(0xFF2962FF) : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isToday
                              ? 'Today'
                              : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isToday ? const Color(0xFF2962FF) : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2962FF),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF2962FF),
            tabs: const [
              Tab(text: "Today's Dash"),
              Tab(text: "Customers"),
              Tab(text: "History"),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2023),
      lastDate: now,
    );
    if (picked != null && !_isSameDay(picked, _selectedDate)) {
      setState(() => _selectedDate = picked);
      // ignore: use_build_context_synchronously
      context.read<BottleBloc>().add(
            LoadSalesmanBottleLedger(authState.salesman.id, _selectedDate));
    }
  }

  Widget _buildTodayDashboardTab(SalesmanBottleLedgerStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Opening Snapshot ─────────────────────────────────────────
          const Text('Opening Snapshot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOpeningItem(
                    'Carry-forward\nEmpties',
                    stats.openingEmptyBottles,
                    Icons.history,
                    Colors.blueGrey),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildOpeningItem(
                    'Loaded\nToday',
                    stats.fullBottlesLoaded,
                    Icons.upload_rounded,
                    const Color(0xFF2962FF)),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildOpeningItem(
                    'Returned to\nWarehouse',
                    stats.emptyBottlesReturnedToWarehouse,
                    Icons.download_rounded,
                    Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Live Van Inventory ────────────────────────────────────────
          const Text('Live Van Inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                title: 'Full Stock',
                value: '${stats.currentPhysicalFullCount}',
                label: 'In Van',
                color: const Color(0xFF2962FF),
                icon: Icons.water_drop,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                title: 'Empties',
                value: '${stats.currentPhysicalEmptyCount}',
                label: 'In Van',
                color: Colors.blueGrey,
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Market Movement (Today)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFlowIndicator('Delivered', stats.bottlesDeliveredToday,
                    Colors.red, Icons.arrow_upward),
                const Text('VS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                _buildFlowIndicator('Collected', stats.bottlesCollectedToday,
                    Colors.green, Icons.arrow_downward),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Column(
                  children: [
                    Text(
                      stats.netMarketMovement > 0
                          ? '+${stats.netMarketMovement}'
                          : '${stats.netMarketMovement}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stats.netMarketMovement > 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const Text('Net Flow',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Reconciliation & Liability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildSummaryRow('Total Market Liability',
                    '${stats.totalBottlesWithCustomers} bottles',
                    isHighlight: true),
                const Divider(),
                _buildSummaryRow('Avg. Customer Holding',
                    '${stats.averageCustomerHolding.toStringAsFixed(1)} bottles'),
                const Divider(),
                _buildSummaryRow('Damaged Bottles (Logged)',
                    '${stats.damagedBottles}',
                    textColor: Colors.orange),
                const Divider(),
                _buildSummaryRow('Unaccounted / Mismatched',
                    '${stats.mismatchCount}',
                    textColor: stats.mismatchCount > 0
                        ? Colors.red
                        : Colors.green),
                const Divider(),
                _buildSummaryRow('High Risk Customers',
                    '${stats.highBalanceCount}',
                    textColor: stats.highBalanceCount > 0
                        ? Colors.red
                        : Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningItem(
      String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }


  Widget _buildCustomerBalancesTab(SalesmanBottleLedgerStats stats) {
    if (stats.customers.isEmpty) {
       return const Center(child: Text("No customers assigned."));
    }

    // Sort by bottle balance descending
    final sortedCustomers = List.of(stats.customers)..sort((a, b) => b.bottleBalance.compareTo(a.bottleBalance));

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedCustomers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = sortedCustomers[index];
        final bool isHigh = customer.bottleBalance > 5;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHigh ? const Color(0xFFFFF8E1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isHigh ? Colors.orange.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Text(
                           customer.name,
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         if (isHigh) ...[
                           const SizedBox(width: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                             child: const Text('High', style: TextStyle(color: Colors.white, fontSize: 10)),
                           ),
                         ],
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(customer.phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                   ],
                 ),
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Text(
                     '${customer.bottleBalance}',
                     style: TextStyle(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: isHigh ? Colors.red : const Color(0xFF2962FF),
                     ),
                   ),
                   const Text('bottles', style: TextStyle(fontSize: 10, color: Colors.grey)),
                 ],
               ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistoryTab(SalesmanBottleLedgerStats stats) {
    if (stats.todayTransactions.isEmpty) {
      return const Center(child: Text('No bottle transactions for this date.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stats.todayTransactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final tx = stats.todayTransactions[index];
        final bool isDelivery = tx.type == 'Delivery';
        final timeStr = tx.timestamp.toString().length >= 16
            ? tx.timestamp.toString().substring(11, 16)
            : '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor:
                isDelivery ? Colors.blue[50] : Colors.green[50],
            child: Icon(
              isDelivery
                  ? Icons.local_shipping_rounded
                  : Icons.assignment_return_rounded,
              color: isDelivery ? Colors.blue : Colors.green,
            ),
          ),
          title: Text(
            tx.customerName.isNotEmpty ? tx.customerName : 'Unknown Customer',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${tx.type}  •  $timeStr',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (tx.cansDelivered > 0)
                Text('${tx.cansDelivered} Delivered',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              if (tx.emptyCollected > 0)
                Text('${tx.emptyCollected} Collected',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }


  Widget _buildStatCard({
    required String title,
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Icon(icon, color: Colors.white70, size: 24),
             const SizedBox(height: 12),
             Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 4),
             Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
             Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowIndicator(String label, int value, Color color, IconData icon) {
     return Column(
       children: [
          Row(
            children: [
               Icon(icon, color: color, size: 16),
               const SizedBox(width: 4),
               Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
       ],
     );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor ?? (isHighlight ? const Color(0xFF2962FF) : Colors.black),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
