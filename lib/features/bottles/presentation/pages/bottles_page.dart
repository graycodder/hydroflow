import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming google_fonts is available
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_state.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';

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
      final salesman = authState.salesman;
      final prefs = sl<SharedPreferences>();
      final isAgencyView = prefs.getBool('dashboard_is_agency_view') ?? false;

      if (salesman.role == 'owner' && isAgencyView) {
        context.read<BottleBloc>().add(LoadAgencyBottleLedger(salesman.agencyId));
      } else {
        context.read<BottleBloc>().add(LoadBottleLedger(salesman.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final salesman = authState.salesman;
          
          // Recalculate isAgency based on prefs
          final prefs = sl<SharedPreferences>();
          final isAgencyViewPref = prefs.getBool('dashboard_is_agency_view') ?? false;
          final isOwner = salesman.role == 'owner';

          // Access BottleBloc state
          final bottleState = context.watch<BottleBloc>().state;
          
          // Check for view mismatch and trigger reload
          if (isOwner) {
             bool currentBlocIsAgency = bottleState.isAgencyView;

             if (isAgencyViewPref != currentBlocIsAgency) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (isAgencyViewPref) {
                      context.read<BottleBloc>().add(LoadAgencyBottleLedger(salesman.agencyId));
                   } else {
                      context.read<BottleBloc>().add(LoadBottleLedger(salesman.id));
                   }
                });
                return const Scaffold(body: Center(child: HydroFlowLoader(message: 'Switching View...', isOverlay: false)));
             }
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
                  } else if (state is BottleLoaded) {
                      final prefs = sl<SharedPreferences>();
                      final isAgencyView = prefs.getBool('dashboard_is_agency_view') ?? false;
                      final isAgency = salesman.role == 'owner' && isAgencyView;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             if(!isAgency)
                            Text(
                              isAgency ? 'Agency Bottle Ledger' : 'Bottle Debt Ledger',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Dark text
                              ),
                            ),
                             if(!isAgency)
                            const SizedBox(height: 4),
                             if(!isAgency)
                            Text(
                              isAgency ? 'Consolidated view of all salesmen' : 'Track bottles held by customers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                             if(!isAgency)
                            const SizedBox(height: 20),

                            // Top Stats Row
                            if(!isAgency)
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                ],
                              ),
                            if(!isAgency)
                            
                            const SizedBox(height: 24),

                            // Alert Card (High Balance)
                            if(!isAgency)
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFBF360C)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${state.highBalanceCount} customer(s) has high bottle balance',
                                            style: const TextStyle(
                                              color: Color(0xFF3E2723),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
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

                            // // Formula Card
                            // Container(
                            //   width: double.infinity,
                            //   padding: const EdgeInsets.all(16),
                            //   decoration: BoxDecoration(
                            //     color: const Color(0xFFE3F2FD), // Light Blue
                            //     borderRadius: BorderRadius.circular(12),
                            //     border: Border.all(color: const Color(0xFFBBDEFB)),
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       const Row(
                            //         children: [
                            //           Icon(Icons.refresh, color: Color(0xFF1565C0), size: 20),
                            //           SizedBox(width: 8),
                            //           Text(
                            //             'Bottle Balance Formula',
                            //             style: TextStyle(
                            //               color: Color(0xFF0D47A1),
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 16,
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //       const SizedBox(height: 12),
                            //       Container(
                            //         width: double.infinity,
                            //         padding: const EdgeInsets.all(12),
                            //         decoration: BoxDecoration(
                            //           color: Colors.white,
                            //           borderRadius: BorderRadius.circular(8),
                            //         ),
                            //         child: const Text(
                            //           'Net Bottles = (Previous Balance + Delivered) - Returned',
                            //           style: TextStyle(
                            //             fontFamily: 'Courier',
                            //             color: Color(0xFF263238),
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //         ),
                            //       ),
                            //       const SizedBox(height: 8),
                            //       const Text(
                            //         'This formula tracks the circular economy of bottle exchange',
                            //         style: TextStyle(
                            //           color: Color(0xFF1565C0),
                            //           fontSize: 12,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            //const SizedBox(height: 10),

                            // Customer/Salesman List Header
                            if(isAgency ? state.salesmen.isNotEmpty : state.customers.isNotEmpty)
                            Text(
                              isAgency ? 'Salesman Bottle Ledger' : 'Customer Bottle Ledger',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                             if(isAgency ? state.salesmen.isNotEmpty : state.customers.isNotEmpty)
                            const SizedBox(height: 4),
                             if(isAgency ? state.salesmen.isNotEmpty : state.customers.isNotEmpty)
                            Text(
                              isAgency ? 'Net bottles held by each salesman' : 'Net bottles held by each customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                             if(isAgency ? state.salesmen.isNotEmpty : state.customers.isNotEmpty)
                            const SizedBox(height: 16),

                            // List
                            if (isAgency)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.salesmen.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final salesman = state.salesmen[index];
                                  return _buildSalesmanCard(salesman);
                                },
                              )
                            else
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
                                  _buildSummaryRow(isAgency ? 'Total Salesmen' : 'Total Customers', '${isAgency ? state.salesmen.length : state.customers.length}'),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    'Total Bottles Out', 
                                    '${state.totalBottles} bottles', 
                                    isHighlight: true
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow(
                                    isAgency ? 'Salesmen with 0 Bottles' : 'Customers with 0 Bottles', 
                                    '${isAgency ? state.salesmen.where((s) => (s.currentStock + (s.emptyBottles ?? 0)) == 0).length : state.customers.where((c) => c.bottleBalance == 0).length}',
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
                bottomNavigationBar: const AppBottomBar(currentIndex: 2),
              );
            }
           return const Scaffold(body: HydroFlowLoader(isOverlay: false));
      },
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
        padding: const EdgeInsets.only(top:16,bottom:16,left:7,right:7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                  fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesmanCard(Salesman salesman) {
    final int balance = salesman.currentStock + (salesman.emptyBottles ?? 0);
    final bool isHigh = balance > 5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFFFF8E1) : Colors.white,
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
              const Icon(Icons.delivery_dining, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          salesman.name.isNotEmpty
                              ? salesman.name[0].toUpperCase() + salesman.name.substring(1)
                              : 'Staff',
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
                              color: const Color(0xFFC62828),
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
                      '${salesman.phoneNumber} | ${salesman.zone}',
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
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF2962FF), size: 20),
                  Text(
                    '${salesman.currentStock}',
                    style: const TextStyle(
                      color: Color(0xFF2962FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                   const Text(
                    'total',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          // const SizedBox(height: 12),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     _buildSmallStockInfo('Full', salesman.currentStock, const Color(0xFF00C853)),
          //     _buildSmallStockInfo('Empty', salesman.emptyBottles ?? 0, const Color(0xFFFF6D00)),
          //   ],
          // ),
          // const SizedBox(height: 12),
          // // Progress Bar
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(4),
          //   child: LinearProgressIndicator(
          //     value: (balance / 10).clamp(0.0, 1.0),
          //     backgroundColor: Colors.grey[200],
          //     color: isHigh ? Colors.black : const Color(0xFF2962FF),
          //     minHeight: 8,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          //     const Text('Recommended: ≤5', style: TextStyle(fontSize: 12, color: Colors.grey)),
          //     const Text('10', style: TextStyle(fontSize: 12, color: Colors.grey)),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildSmallStockInfo(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Customer customer) { 
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
                            customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase() + customer.name.substring(1)
                            : '',
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
                     maxLines: 1,
              overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
     return "+91 00000 00000";
  }
}
