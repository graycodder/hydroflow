import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_event.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:hydroflow/features/transactions/presentation/widgets/transaction_receipt_dialog.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryView();
  }
}

class DeliveryView extends StatefulWidget {
  const DeliveryView({super.key});

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _fullCansController = TextEditingController(text: '0');
  final TextEditingController _emptyCansController = TextEditingController(text: '0');
  final TextEditingController _priceController = TextEditingController(text: '60'); // Default price
  final TextEditingController _amountReceivedController = TextEditingController(text: '0');
  
  String _paymentMode = 'Cash'; // Default
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Trigger load if needed.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<DeliveryBloc>().add(LoadDeliveryPage(authState.salesman.id));
    }
  }

  @override
  void dispose() {
    _fullCansController.dispose();
    _emptyCansController.dispose();
    _priceController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    // 1. Calculate price if standard (e.g., 60 per can) - logic mostly manual for now based on user edit
    // But if we want auto-calc:
    // int quantity = int.tryParse(_fullCansController.text) ?? 0;
    // double price = quantity * 60.0;
    // _priceController.text = price.toStringAsFixed(0);
    
    // 2. Auto-fill Amount Received based on Mode
    _updateAmountReceived();
    setState(() {});
  }
  
  void _updateAmountReceived() {
    final total = double.tryParse(_priceController.text) ?? 0;
    if (_paymentMode == 'Cash' || _paymentMode == 'UPI') {
       // Default to full payment
       // Only update if it seems "untouched" or we enforce rule?
       // Better to just set it equal to total for convenience, user can edit if partial.
       _amountReceivedController.text = total.toStringAsFixed(0);
    } else if (_paymentMode == 'Credit') {
       _amountReceivedController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state.status == DeliveryStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        } else if (state.status == DeliveryStatus.submissionSuccess) {
            FocusScope.of(context).unfocus();
            if (state.todayTransactions.isNotEmpty) {
               final tx = state.todayTransactions.first;
               final customer = state.customers.firstWhere(
                 (c) => c.id == tx.customerId,
                 orElse: () => const Customer(id: '', salesmanId: '', name: 'Unknown', phone: '', address: '', status: '', securityDeposit: 0, pendingBalance: 0, bottleBalance: 0),
               );
               showDialog(
                 context: context,
                 builder: (_) => TransactionReceiptDialog(
                   transaction: tx,
                   customer: customer,
                 ),
               );
            }
            _resetForm();
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state; // Use watch for updates
        final salesman = (authState is AuthAuthenticated) ? authState.salesman : null;
        final salesmanId = salesman?.id ?? '';

        return Scaffold(
          backgroundColor: Colors.grey[50],
            appBar: const HydroFlowAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats Header
                _buildStatsHeader(state),
                const SizedBox(height: 24),
                
                // Form Card
                _buildDeliveryForm(context, state, salesmanId),
                
                const SizedBox(height: 24),
                
                // Transactions List
                const Text(
                  "Today's Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildTransactionsList(state),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomBar(currentIndex: 4), // Index 4 for Delivery
        );
      },
    );
  }

  Widget _buildStatsHeader(DeliveryState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('Total Sales', '₹${state.totalSales.toStringAsFixed(0)}', Colors.blue[50]!, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildInfoCard('Cash', '₹${state.totalCash.toStringAsFixed(0)}', Colors.green[50]!, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildInfoCard('UPI', '₹${state.totalUpi.toStringAsFixed(0)}', Colors.purple[50]!, Colors.purple)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Delivered', '↓ ${state.totalDelivered}', Colors.orange[50]!, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildInfoCard('Returned', '↑ ${state.totalReturned}', Colors.teal[50]!, Colors.teal)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm(BuildContext context, DeliveryState state, String salesmanId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 20),
                SizedBox(width: 8),
                Text("Record Delivery & Return", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
             const SizedBox(height: 16),
             
             // Customer Dropdown
             // Customer Dropdown with Search
             DropdownSearch<Customer>(
               items: (filter, loadProps) => state.customers,
               itemAsString: (Customer c) => c.name,
               compareFn: (i, s) => i.id == s.id,
               decoratorProps: DropDownDecoratorProps(
                 decoration: InputDecoration(
                   labelText: 'Select Customer',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   filled: true,
                   fillColor: Colors.grey[50],
                 ),
               ),
               popupProps: PopupProps.menu(
                 showSearchBox: true,
                 searchFieldProps: const TextFieldProps(
                   decoration: InputDecoration(
                     hintText: "Search customer...",
                     prefixIcon: Icon(Icons.search),
                     contentPadding: EdgeInsets.symmetric(horizontal: 12),
                     border: OutlineInputBorder(),
                   ),
                 ),
                 itemBuilder: (context, item, isSelected, isHovered) {
                   return ListTile(
                     title: Text(item.name),
                     subtitle: Text(item.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                     selected: isSelected,
                   );
                 },
               ),
               selectedItem: state.customers.any((c) => c == state.selectedCustomer) 
                   ? state.selectedCustomer 
                   : null,
               onChanged: (Customer? value) {
                 if (value != null) {
                   context.read<DeliveryBloc>().add(SelectCustomer(value));
                 }
               },
             ),
             
             const SizedBox(height: 16),
             
             // Quantities
             Row(
               children: [
                 Expanded(
                   child: TextFormField(
                     controller: _fullCansController,
                     keyboardType: TextInputType.number,
                     decoration: const InputDecoration(
                       labelText: 'Full Cans',
                       prefixIcon: Icon(Icons.arrow_downward, color: Colors.orange),
                       border: OutlineInputBorder(),
                     ),
                     onChanged: (_) => _calculateTotal(),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: TextFormField(
                     controller: _emptyCansController,
                     keyboardType: TextInputType.number,
                     decoration: const InputDecoration(
                       labelText: 'Empty Cans',
                       prefixIcon: Icon(Icons.arrow_upward, color: Colors.teal),
                       border: OutlineInputBorder(),
                     ),
                   ),
                 ),
               ],
             ),
             
             const SizedBox(height: 16),
             
             // Price
             TextFormField(
               controller: _priceController,
               keyboardType: TextInputType.number,
               decoration: const InputDecoration(
                 labelText: 'Total Amount (₹)',
                 prefixText: '₹ ',
                 border: OutlineInputBorder(),
               ),
                onChanged: (_) => _calculateTotal(),
             ),
             
             const SizedBox(height: 16),
             
             // Amount Received (Partial Payment)
             TextFormField(
               controller: _amountReceivedController,
               keyboardType: TextInputType.number,
               decoration: const InputDecoration(
                 labelText: 'Amount Received (₹)',
                 prefixText: '₹ ',
                 border: OutlineInputBorder(),
                 helperText: "Enter 0 for Credit, equals Total for Cash"
               ),
             ),
             
             const SizedBox(height: 16),
             
             // Payment Mode
             const Text("Payment Mode", style: TextStyle(fontWeight: FontWeight.w500)),
             const SizedBox(height: 8),
             Row(
                children: [
                  _buildPaymentRadio('Cash', Icons.money),
                  const SizedBox(width: 12),
                  _buildPaymentRadio('UPI', Icons.qr_code),
                  const SizedBox(width: 12),
                  _buildPaymentRadio('Credit', Icons.account_balance_wallet_outlined),
                ],
             ),
             
             const SizedBox(height: 24),
             
             // Submit Button
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: state.status == DeliveryStatus.loading ? null : () => _submitTransaction(context, salesmanId),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF2962FF),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 ),
                 child: state.status == DeliveryStatus.loading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Transaction', style: TextStyle(color: Colors.white, fontSize: 16)),
               ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentRadio(String mode, IconData icon) {
    final bool isSelected = _paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMode = mode;
            _updateAmountReceived();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? const Color(0xFF2962FF) : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? const Color(0xFF2962FF) : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                mode,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2962FF) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(DeliveryState state) {
    if (state.todayTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text("No transactions yet today.", style: TextStyle(color: Colors.grey[500])),
      );
    }
    
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: state.todayTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = state.todayTransactions[index];
        // Look up customer name from stats customers list? 
        // We might not have the name in TransactionEntity (only ID).
        // Let's try to find it in loaded customers.
        final customer = state.customers.firstWhere(
            (c) => c.id == tx.customerId, 
            orElse: () => const Customer(id: '', salesmanId: '', name: 'Unknown', phone: '', address: '', status: '', securityDeposit: 0, pendingBalance: 0, bottleBalance: 0)
        );

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Text('₹${tx.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2962FF))),
                ],
              ),
              const SizedBox(height: 8),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    '${_formatTime(tx.timestamp)} • ${tx.paymentMode}', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)
                   ),
                   Row(
                     children: [
                       if (tx.cansDelivered > 0) 
                         Text('↓ ${tx.cansDelivered}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                       if (tx.cansDelivered > 0 && tx.emptyCollected > 0)
                          const SizedBox(width: 8),
                       if (tx.emptyCollected > 0)
                         Text('↑ ${tx.emptyCollected}', style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                     ],
                   )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatTime(DateTime time) {
    // Simple formatter
    return "${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _submitTransaction(BuildContext context, String salesmanId) {
    if (_formKey.currentState!.validate()) {
      final selectedCustomer = context.read<DeliveryBloc>().state.selectedCustomer;
      if (selectedCustomer == null) return;
      
      final transaction = TransactionEntity(
        id: Uuid().v4(), 
        salesmanId: salesmanId,
        customerId: selectedCustomer.id,
        timestamp: DateTime.now(),
        type: 'delivery',
        amount: double.tryParse(_priceController.text) ?? 0,
        amountReceived: double.tryParse(_amountReceivedController.text) ?? 0,
        paymentMode: _paymentMode,
        cansDelivered: int.tryParse(_fullCansController.text) ?? 0,
        emptyCollected: int.tryParse(_emptyCansController.text) ?? 0,
        notes: '',
      );
      
      context.read<DeliveryBloc>().add(SubmitTransaction(transaction));
    }
  }

  void _resetForm() {
    _fullCansController.text = '0';
    _emptyCansController.text = '0';
    _priceController.text = '60'; // Updated to 60 as per user default change
    _amountReceivedController.text = '60'; 
    setState(() {
      _paymentMode = 'Cash';
      // Selected customer is reset by BLoC state change
    });
  }
}
