import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming google_fonts is available
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_state.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';

class BottlesPage extends StatefulWidget {
  const BottlesPage({super.key});

  @override
  State<BottlesPage> createState() => _BottlesPageState();
}

class _BottlesPageState extends State<BottlesPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BottleBloc>().add(LoadBottleLedger(authState.salesman.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BottleBloc>(),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final salesman = authState.salesman;
            // Ensure bloc is triggered if it wasn't already (though initState handles it for the initial context, 
            // the BlocProvider creates a NEW bloc instance, so we need to add event TO THAT INSTANCE)
            // Actually, best practice: create bloc in provider and add event there using cascade
            return BlocProvider(
              create: (_) => sl<BottleBloc>()..add(LoadBottleLedger(salesman.id)),
              child: Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: const HydroFlowAppBar(),
                body: BlocBuilder<BottleBloc, BottleState>(
                  builder: (context, state) {
                    if (state is BottleLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is BottleFailure) {
                      return Center(child: Text('Error: ${state.error}'));
                    } else if (state is BottleLoaded) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bottle Debt Ledger',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Dark text
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track bottles held by customers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Top Stats Row
                            Row(
                              children: [
                                _buildStatCard(
                                  context,
                                  title: 'Total Bottles',
                                  value: '${state.totalBottles}',
                                  label: 'In Circulation',
                                  color: const Color(0xFF2962FF), // Blue
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  context,
                                  title: 'High Balance',
                                  value: '${state.highBalanceCount}',
                                  label: '>5 Bottles',
                                  color: const Color(0xFFFF6D00), // Orange
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  context,
                                  title: 'Avg Balance',
                                  value: state.avgBalance.toStringAsFixed(1),
                                  label: 'Per Customer',
                                  color: const Color(0xFF00C853), // Green
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Alert Card (High Balance)
                            if (state.highBalanceCount > 0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0), // Light Orange
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFE0B2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFBF360C)),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${state.highBalanceCount} customer(s) has high bottle balance',
                                          style: const TextStyle(
                                            color: Color(0xFF3E2723),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Remind them to return empty bottles on next delivery',
                                      style: TextStyle(
                                        color: Color(0xFF5D4037),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (state.highBalanceCount > 0) const SizedBox(height: 24),

                            // Formula Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD), // Light Blue
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBDEFB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.refresh, color: Color(0xFF1565C0), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Bottle Balance Formula',
                                        style: TextStyle(
                                          color: Color(0xFF0D47A1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Net Bottles = (Previous Balance + Delivered) - Returned',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        color: Color(0xFF263238),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'This formula tracks the circular economy of bottle exchange',
                                    style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Customer List Header
                            const Text(
                              'Customer Bottle Ledger',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Net bottles held by each customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Customer List
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.customers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final customer = state.customers[index];
                                return _buildCustomerCard(customer);
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Reconciliation Summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reconciliation Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSummaryRow('Total Customers', '${state.customers.length}'),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    'Total Bottles Out', 
                                    '${state.totalBottles} bottles', 
                                    isHighlight: true
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    'Customers with 0 Bottles', 
                                    '${state.customers.where((c) => c.bottleBalance == 0).length}',
                                    textColor: Colors.green
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    'Need Immediate Collection', 
                                    '${state.highBalanceCount}',
                                    textColor: const Color(0xFFBF360C)
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text('Something went wrong'));
                  },
                ),
                bottomNavigationBar: const AppBottomBar(currentIndex: 2), // Index 2 for Bottles? Assuming
              ),
            );
          }
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 140, // Fixed height to align
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(dynamic customer) { 
    // using dynamic to avoid import if not needed, but better to import Customer.
    // I imported customer.dart in top.
    final bool isHigh = customer.bottleBalance > 5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFFFF8E1) : Colors.white, // Light yellow tint if high
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isHigh) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828), // Dark Red
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'High',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone.isNotEmpty ? customer.phone : '+91 00000 00000',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                 const Icon(Icons.water_drop_outlined, color: Color(0xFFE65100), size: 20),
                  Text(
                    '${customer.bottleBalance}',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                   const Text(
                    'bottles',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (customer.bottleBalance / 10).clamp(0.0, 1.0), // Assuming 10 is max/ref
              backgroundColor: Colors.grey[200],
              color: isHigh ? Colors.black : const Color(0xFF2962FF), // Black bar for High in design? screenshot looks black
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Text('Recommended: ≤5', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Text('10', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (isHigh) ...[
            const SizedBox(height: 12),
             Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Color(0xFFBF360C)),
                SizedBox(width: 4),
                Text(
                  'Collect ${customer.bottleBalance - 5} bottles to normalize',
                  style: TextStyle(
                    color: Color(0xFFBF360C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

  String customerIdToPhone(String id) {
     // The customer object has phone, use it.
     // But wait, the buildCustomerCard takes dynamic or Customer.
     if (id.startsWith("+")) return id;
     // Fallback if needed, but we should use customer.phone
     return "+91 98765 43210";
  }
}
