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
                         setState(() {
                           isActive = val;
                         });
                         widget.customerBloc.add(UpdateCustomerStatus(
                           widget.customer.id, 
                           val ? 'Active' : 'Inactive',
                           widget.customer.salesmanId
                         ));
                       },
                     ),
                  ],
                ),
              ),
              
              // Refund Warning (if Inactive)
              if (!isActive) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7EF), // Light warning orange
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFFE65100), fontSize: 15),
                          children: [
                            const TextSpan(
                              text: 'Deposit Refund Pending: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '₹${widget.customer.securityDeposit.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Refund this amount when closing the account',
                        style: TextStyle(
                          color: Color(0xFFF57C00),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
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
