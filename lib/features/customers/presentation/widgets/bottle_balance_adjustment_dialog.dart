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

class BottleBalanceAdjustmentDialog extends StatefulWidget {
  final Customer customer;
  final CustomerBloc customerBloc;

  const BottleBalanceAdjustmentDialog({
    super.key,
    required this.customer,
    required this.customerBloc,
  });

  @override
  State<BottleBalanceAdjustmentDialog> createState() => _BottleBalanceAdjustmentDialogState();
}

class _BottleBalanceAdjustmentDialogState extends State<BottleBalanceAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bottlesCollectedController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bottlesCollectedController = TextEditingController();
  }

  @override
  void dispose() {
    _bottlesCollectedController.dispose();
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
                        'Adjust Bottle Balance',
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Bottle Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.customer.bottleBalance} Bottles',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Empty Bottles Collected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bottlesCollectedController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter number of bottles',
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
                        return 'Please enter count';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count <= 0) {
                        return 'Enter a valid count > 0';
                      }
                      if (count > widget.customer.bottleBalance) {
                        return 'Cannot exceed current balance';
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
      final collectedBottles = int.parse(_bottlesCollectedController.text.trim());
      
      showDialog(
        context: context,
        builder: (confirmContext) => AlertDialog(
          title: const Text('Confirm Adjustment'),
          content: Text(
            'Are you sure you want to adjust $collectedBottles bottles from customer balance?',
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
                  // 1. Calculate new bottle balance
                  final newBottleBalance = widget.customer.bottleBalance - collectedBottles;

                  // 2. Create updated customer object
                  final updatedCustomer = widget.customer.copyWith(
                    bottleBalance: newBottleBalance,
                  );

                  // 3. Dispatch UpdateCustomer event
                  widget.customerBloc.add(UpdateCustomer(updatedCustomer));

                  // 4. Record Transaction
                  final tx = TransactionEntity(
                    id: 'adj_bot_${DateTime.now().millisecondsSinceEpoch}',
                    salesmanId: widget.customer.salesmanId,
                    customerId: widget.customer.id,
                    timestamp: DateTime.now(),
                    type: 'Bottle Adjustment',
                    amount: 0,
                    amountReceived: 0,
                    paymentMode: 'System Adjustment',
                    emptyCollected: collectedBottles,
                    notes: 'Quick Bottle Adjustment',
                  );
                  
                  await di.sl<TransactionRepository>().recordAdjustment(tx);

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
