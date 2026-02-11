import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:hydroflow/features/customers/presentation/widgets/customer_details_dialog.dart';
import 'package:hydroflow/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CustomerBloc>().add(LoadCustomers(authState.salesman.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final salesman = authState.salesman;
          
          return Scaffold(
              backgroundColor: Colors.grey[50], 
              appBar: const HydroFlowAppBar(),
              body: BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state.status == CustomerStatus.loading) {
                      return const HydroFlowLoader(message: 'Loading Customers...', isOverlay: false);
                    }
                    
                    return Column(
                      children: [
                        // Stats Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.grey[50],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('${state.totalCustomers}', 'Total', Colors.blue),
                              _buildStatItem('${state.activeCustomers}', 'Active', Colors.green),
                              _buildStatItem('${state.inactiveCustomers}', 'Inactive', Colors.orange), // Assuming inactive is orange based on screenshot (or red)
                            ],
                          ),
                        ),
                        
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            onChanged: (value) {
                              context.read<CustomerBloc>().add(SearchCustomers(value));
                            },
                            decoration: InputDecoration(
                              hintText: 'Search customers...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[200], // Simple faint grey
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Customer List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state.filteredCustomers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final customer = state.filteredCustomers[index];
                              return _buildCustomerCard(customer);
                            },
                          ),
                        ),
                        
                       // Add Customer Button (Bottom docked look from screenshot)
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: SizedBox(
                           width: double.infinity,
                           child: ElevatedButton.icon(
                              onPressed: () {
                                if (salesman.customerCount >= salesman.maxCustomers) {
                                  _showLimitExceededDialog(context);
                                } else {
                                  _showAddCustomerDialog(context, salesman.id);
                                }
                              },
                             icon: const Icon(Icons.add),
                             label: const Text('Add New Customer'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF0D1117), // Dark background
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             ),
                           ),
                         ),
                       ),
                      ],
                    );
                  },
                ),
                bottomNavigationBar: const AppBottomBar(currentIndex: 3),
              );
            }
            return const Scaffold(body: HydroFlowLoader(message: 'Authenticating...', isOverlay: false));
          },
        );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCustomerCard(dynamic customer) {
    // customer is Customer
    final bool isActive = customer.status == 'Active';
    
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => CustomerDetailsDialog(
            customer: customer,
            customerBloc: context.read<CustomerBloc>(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : Colors.grey[300], // Active tag black, else grey
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    customer.status.toLowerCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  customer.phone,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.address,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Pending: ₹${customer.pendingBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFE65100), // Orange
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF2962FF)),
                const SizedBox(width: 4),
                Text(
                  '${customer.bottleBalance} bottles held',
                  style: const TextStyle(
                    color: Color(0xFF2962FF), // Blue
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitExceededDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Limit Reached'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your plan limit is over.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact customer support to upgrade your plan and add more customers.',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1117),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext pageContext, String salesmanId) {
    showDialog(
      context: pageContext,
      builder: (context) => AddCustomerDialog(salesmanId: salesmanId, bloc: pageContext.read<CustomerBloc>()),
    );
  }
}
