import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/core/service_locator.dart' as di;

class PendingBalanceAdjustmentDialog extends StatefulWidget {
  final Customer customer;
  final CustomerBloc customerBloc;

  const PendingBalanceAdjustmentDialog({
    super.key,
    required this.customer,
    required this.customerBloc,
  });

  @override
  State<PendingBalanceAdjustmentDialog> createState() => _PendingBalanceAdjustmentDialogState();
}

class _PendingBalanceAdjustmentDialogState extends State<PendingBalanceAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountReceivedController;
  String? _selectedPaymentMode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountReceivedController = TextEditingController();
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      bloc: widget.customerBloc,
      listener: (context, state) {
        if (_isSubmitting) {
          if (state.status == CustomerStatus.submitting) {
            HydroFlowLoader.show(context, message: 'Processing Adjustment...');
          } else if (state.status == CustomerStatus.failure || 
                     (state.status == CustomerStatus.success && state.successMessage != null)) {
            HydroFlowLoader.hide(context);
            if (state.status == CustomerStatus.success) {
              _isSubmitting = false;
              Navigator.of(context).pop(); // Close dialog
            } else if (state.status == CustomerStatus.failure) {
              _isSubmitting = false;
              // Ideally show error snackbar or dialog here if needed, 
              // but loader hide + state update might be enough for now or rely on parent listener
            }
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adjust Pending Balance',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Pending Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.customer.pendingBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Amount Received',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountReceivedController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter received amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount > 0';
                      }
                      if (amount > widget.customer.pendingBalance) {
                        return 'Cannot exceed pending balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Payment Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentMode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: 'Select Payment Mode',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: ['Cash', 'Online', 'UPI'].map((String mode) {
                      return DropdownMenuItem<String>(
                        value: mode,
                        child: Text(mode),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPaymentMode = newValue;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select payment mode';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitAdjustment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1117),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitAdjustment() {
    if (_formKey.currentState!.validate()) {
      final receivedAmount = double.parse(_amountReceivedController.text.trim());
      
      showDialog(
        context: context,
        builder: (confirmContext) => AlertDialog(
          title: const Text('Confirm Adjustment'),
          content: Text(
            'Are you sure you want to adjust ₹$receivedAmount from pending balance using $_selectedPaymentMode?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(confirmContext); // Close confirmation
                
                setState(() {
                  _isSubmitting = true;
                });

                try {
                  // 1. Calculate new pending balance
                  final newPendingBalance = widget.customer.pendingBalance - receivedAmount;

                  // 2. Create updated customer object
                  final updatedCustomer = Customer(
                    id: widget.customer.id,
                    salesmanId: widget.customer.salesmanId,
                    name: widget.customer.name,
                    phone: widget.customer.phone,
                    address: widget.customer.address,
                    status: widget.customer.status,
                    securityDeposit: widget.customer.securityDeposit,
                    bottleBalance: widget.customer.bottleBalance,
                    paymentMode: widget.customer.paymentMode,
                    pendingBalance: newPendingBalance,
                    isRefunded: widget.customer.isRefunded,
                    createdAt: widget.customer.createdAt,
                  );

                  // 3. Dispatch UpdateCustomer event
                  // This will update the customer in UI and Repo
                  widget.customerBloc.add(UpdateCustomer(updatedCustomer));

                  // 4. Record Transaction
                  // We do this manually here similar to generic edit dialog, 
                  // or we could move this logic to Bloc closer to UseCase. 
                  // Given the requirement to match "edit screen logic", we do it here.
                  final tx = TransactionEntity(
                    id: 'adj_pay_${DateTime.now().millisecondsSinceEpoch}',
                    salesmanId: widget.customer.salesmanId,
                    customerId: widget.customer.id,
                    timestamp: DateTime.now(),
                    type: 'Payment Adjustment',
                    amount: 0,
                    amountReceived: receivedAmount,
                    paymentMode: _selectedPaymentMode!, // Use selected mode (bang operator safe due to validation)
                    notes: 'Quick Balance Adjustment via $_selectedPaymentMode',
                  );
                  
                  await di.sl<TransactionRepository>().recordAdjustment(tx);

                  // Note: The BlocListener will handle the success state from UpdateCustomer event
                  // and close the dialog.
                } catch (e) {
                  setState(() {
                    _isSubmitting = false;
                  });
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1117),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }
}
