import 'package:flutter/material.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/widgets/edit_customer_dialog.dart';

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;
  final CustomerBloc customerBloc;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
    required this.customerBloc,
  });

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  late bool isActive;

  @override
  void initState() {
    super.initState();
    isActive = widget.customer.status == 'Active';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  const Column(
                    children: [
                      Text(
                        'Customer Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View and manage customer information',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name
              const Text(
                'Name',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                widget.customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone
              const Text(
                'Phone',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                widget.customer.phone,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Address
              const Text(
                'Address',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
               const SizedBox(height: 4),
              Text(
                widget.customer.address,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              
               // Financials Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Security Deposit', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.customer.securityDeposit.toStringAsFixed(0)}',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Text('(Cash)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Balance', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.customer.pendingBalance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Bottle Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF), // Soft Blue
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0E4FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                         Icon(Icons.water_drop_outlined, color: Color(0xFF2962FF), size: 20),
                         SizedBox(width: 8),
                         Text(
                           'Bottle Balance',
                           style: TextStyle(
                             color: Color(0xFF0039CB),
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.customer.bottleBalance}',
                      style: const TextStyle(
                        color: Color(0xFF2962FF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer is holding ${widget.customer.bottleBalance} empty bottles',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Status Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Customer Status', style: TextStyle(color: Colors.grey, fontSize: 13)),
                         Text(
                           isActive ? 'Active' : 'Inactive',
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                       ],
                     ),
                     Switch(
                       value: isActive,
                       activeColor: Colors.white,
                       activeTrackColor: Colors.black,
                       inactiveThumbColor: Colors.white,
                       inactiveTrackColor: Colors.grey[300],
                       onChanged: (val) {
                         if (!val) {
                           // User is turning it OFF (Inactive) -> Trigger Settle Flow
                            // Calculate potential refund/adjustment
                             final double deposit = widget.customer.securityDeposit;
                             final double pending = widget.customer.pendingBalance;
                             
                             double refundAmount = 0;
                             double adjustedPending = 0;
                             
                             if (deposit >= pending) {
                               refundAmount = deposit - pending;
                               adjustedPending = 0;
                             } else {
                               refundAmount = 0;
                               adjustedPending = pending - deposit;
                             }

                            showDialog(
                              context: context,
                              barrierDismissible: false, // Force choice
                              builder: (context) => AlertDialog(
                                title: const Text('Deactivate & Settle?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('This will deactivate the customer and settle their account.'),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Security Deposit:'),
                                        Text('₹${deposit.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Pending Balance:'),
                                        Text('₹${pending.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const Divider(),
                                    if (refundAmount > 0)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Refund to Customer:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          Text('₹${refundAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Remaining Due:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                          Text('₹${adjustedPending.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'This action is irreversible.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Cancel: Revert toggle visually (it didn't change state yet technically if we didn't setState before, 
                                      // but Switch might assume it did. Better to enforce 'true'.)
                                      setState(() {
                                        isActive = true;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isActive = false;
                                      });
                                      widget.customerBloc.add(SettleCustomer(widget.customer));
                                      Navigator.pop(context); // Close Alert
                                      // Navigator.pop(context); // Close Details? Maybe keep it open to show updated status?
                                      // Usually better to close details or show updated 'Inactive' state.
                                      // Let's keep it open so they see it became inactive.
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                         } else {
                           // User is turning it ON (Active) -> Normal update
                           setState(() {
                             isActive = val;
                           });
                           widget.customerBloc.add(UpdateCustomerStatus(
                             widget.customer.id, 
                             'Active',
                             widget.customer.salesmanId
                           ));
                         }
                       },
                     ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Edit Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => EditCustomerDialog(
                        customer: widget.customer,
                        customerBloc: widget.customerBloc,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit Customer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
