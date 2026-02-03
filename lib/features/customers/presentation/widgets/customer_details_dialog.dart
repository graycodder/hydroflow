import 'package:flutter/material.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                const Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      const Text('Security Deposit', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.customer.securityDeposit.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text('(Cash)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Balance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.customer.pendingBalance.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                       const SizedBox(height: 14), // Spacer to align with Left side height if needed
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
                color: const Color(0xFFE3F2FD), // Light Blue
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                       const Icon(Icons.water_drop_outlined, color: Color(0xFF1565C0), size: 20),
                       const SizedBox(width: 8),
                       const Text(
                         'Bottle Balance',
                         style: TextStyle(
                           color: Color(0xFF0D47A1),
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.customer.bottleBalance}',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer is holding ${widget.customer.bottleBalance} empty bottles',
                    style: TextStyle(
                      color: Colors.blue[800],
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
                       const Text('Customer Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       Text(
                         isActive ? 'Active' : 'Inactive',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                     ],
                   ),
                   Switch(
                     value: isActive,
                     activeColor: Colors.black,
                     onChanged: (val) {
                       setState(() {
                         isActive = val;
                       });
                       // Dispatch update event
                       widget.customerBloc.add(UpdateCustomerStatus(
                         widget.customer.id, 
                         val ? 'Active' : 'Inactive',
                         widget.customer.salesmanId
                       ));
                       // Assuming we update backend here or on close.
                       // For demo, just toggle.
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
                  color: const Color(0xFFFFF3E0), // Light warning orange
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFFBF360C), fontSize: 14),
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
                        color: Color(0xFFD84315),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
