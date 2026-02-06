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
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';

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
    return BlocProvider(
      create: (_) => sl<CustomerBloc>(), // Ideally create in top-level or ensure existing context is used if provided above
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final salesman = authState.salesman;
            // Trigger load if using new bloc instance provided by BlocProvider above
            // Best practice: Create bloc with event.
             return BlocProvider(
              create: (_) => sl<CustomerBloc>()..add(LoadCustomers(salesman.id)),
              child: Scaffold(
                backgroundColor: Colors.grey[50], // Match design background
                appBar: const HydroFlowAppBar(),
                body: BlocConsumer<CustomerBloc, CustomerState>(
                  listener: (context, state) {
                    if (state.status == CustomerStatus.failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage ?? 'Error')),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.status == CustomerStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
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
                bottomNavigationBar: const AppBottomBar(currentIndex: 3), // Index 3 for Customers
              ),
            );
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
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
                  customer.name,
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
      builder: (context) => _AddCustomerDialog(salesmanId: salesmanId, bloc: pageContext.read<CustomerBloc>()),
    );
  }
}

class _AddCustomerDialog extends StatefulWidget {
  final String salesmanId;
  final CustomerBloc bloc; // Pass the bloc from the page context

  const _AddCustomerDialog({required this.salesmanId, required this.bloc});

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _depositController = TextEditingController(text: '500'); // Default
  String _paymentMode = 'Cash';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align labels left
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Spacer for centering
                  const Text(
                    'Add New Customer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildLabel('Customer Name'),
              _buildTextField(_nameController, 'Enter name'),
              const SizedBox(height: 16),
              
              _buildLabel('Phone Number'),
              _buildTextField(_phoneController, '+91 98765 43210', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              
              _buildLabel('Address'),
              _buildTextField(_addressController, 'Enter address'),
               const SizedBox(height: 16),

              _buildLabel('Security Deposit (₹)'),
              _buildTextField(_depositController, '500', keyboardType: TextInputType.number),
               const SizedBox(height: 16),

              _buildLabel('Payment Mode'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMode,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: ['Cash', 'Online', 'UPI'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                         _paymentMode = newValue!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text;
                    final phone = _phoneController.text;
                    final address = _addressController.text;
                    final deposit = double.tryParse(_depositController.text) ?? 0.0;
                    
                    if (name.isNotEmpty && phone.isNotEmpty) {
                      widget.bloc.add(AddCustomer(
                        salesmanId: widget.salesmanId,
                        name: name,
                        phone: phone,
                        address: address,
                        securityDeposit: deposit,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700], // Dark grey button from screenshot
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300), // Subtle border
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
