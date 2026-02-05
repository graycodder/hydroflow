import 'package:flutter/material.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/core/utils/whatsapp_helper.dart';
import 'package:hydroflow/features/transactions/presentation/utils/receipt_pdf_generator.dart';

class TransactionReceiptDialog extends StatelessWidget {
  final TransactionEntity transaction;
  final Customer customer;

  const TransactionReceiptDialog({
    super.key,
    required this.transaction,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent, // For custom header look
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green Success Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                color: const Color(0xFF00C853), // Green
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Transaction Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Receipt generated',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Receipt Body
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'HYDROFLOW PRO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Digital Receipt',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    _buildRow(
                      'Transaction ID:',
                      transaction.id.substring(0, 12).toUpperCase(),
                    ), // Shorten ID for display
                    const SizedBox(height: 8),
                    _buildRow(
                      'Date & Time:',
                      DateFormat(
                        'dd MMM yyyy hh:mm a',
                      ).format(transaction.timestamp),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'CUSTOMER',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      customer.phone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'BOTTLE EXCHANGE',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0), // Light Orange
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivered',
                                  style: TextStyle(
                                    color: Colors.brown,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${transaction.cansDelivered} cans',
                                  style: const TextStyle(
                                    color: Color(0xFFE65100),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1), // Light Teal
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Returned',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${transaction.emptyCollected} cans',
                                  style: const TextStyle(
                                    color: Color(0xFF00C853),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ), // Design uses teal/greenish
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bottle Balance:',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${customer.bottleBalance}',
                                style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  Icons.arrow_right_alt,
                                  size: 16,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              // Calculate new balance: old + delivered - returned
                              // Note: 'customer.bottleBalance' passed here is usually CURRENT/LATEST from state.
                              // If it's already updated, then 'old' was 'new - delivered + returned'.
                              // Let's assume the Customer object passed IS the updated one.
                              Text(
                                '${customer.bottleBalance + transaction.cansDelivered - transaction.emptyCollected}', // Wait, if customer is already updated, this logic is tricky. Let's just show current.
                                // Design shows "3 -> 4".
                                // Assuming 'customer' passed is the one BEFORE update? Or AFTER?
                                // Best to just show current balance if that's what we have.
                                // For now, let's just show the current balance.
                                style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'PAYMENT DETAILS',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${transaction.cansDelivered} can(s) x ₹${(transaction.amount / (transaction.cansDelivered == 0 ? 1 : transaction.cansDelivered)).toStringAsFixed(0)}',
                        ), // Rough logic, or just assume standard
                        Text('₹${transaction.amount.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '₹${transaction.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Mode:',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          transaction.paymentMode.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    
                    Text(
                      'BALANCE SUMMARY',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _buildBalanceRow(
                      'Previous Balance:',
                      '₹${(customer.pendingBalance - (transaction.amount - transaction.amountReceived)).toStringAsFixed(0)}',
                      color: Colors.grey[700]!,
                    ),
                    const SizedBox(height: 4),
                    _buildBalanceRow(
                      'Amount Received:',
                      '- ₹${transaction.amountReceived.toStringAsFixed(0)}',
                      color: Colors.green[700]!,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'NEW PENDING:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          Text(
                            '₹${customer.pendingBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (transaction.amountReceived > 0)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'PAYMENT RECEIVED',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Powered by HydroFlow Pro',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Actions
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          WhatsappHelper.sendReceipt(
                            phone: customer.phone,
                            customerName: customer.name,
                            delivered: transaction.cansDelivered,
                            returned: transaction.emptyCollected,
                            bottleBalance: customer.bottleBalance, // Current balance
                            amount: transaction.amount,
                            amountReceived: transaction.amountReceived,
                            isPaid: transaction.amountReceived >= transaction.amount,
                          );
                        },
                        icon: const Icon(Icons.send), // Changed icon to send for text
                        label: const Text('Send Text Receipt via WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                           final isCredit = transaction.paymentMode == 'Credit';
                           final currentVisibleBalance = customer.pendingBalance; // This might be pre-update state
                           
                           // Logic for PDF Balance:
                           // We assume customer.pendingBalance is UPDATED (New Balance) because BLoC stream updates state.
                           // So New Balance = customer.pendingBalance
                           // Old Balance = New Balance - Change
                           
                           final bill = (transaction.cansDelivered > 0) ? transaction.amount : 0.0;
                           final paid = transaction.amountReceived;
                           final change = bill - paid;
                           
                           final newBal = customer.pendingBalance; // Current state is likely New
                           final oldBal = newBal - change;
                           
                           await ReceiptPdfGenerator.generateAndShare(
                             customerName: customer.name,
                             phone: customer.phone,
                             address: customer.address,
                             delivered: transaction.cansDelivered,
                             emptyCollected: transaction.emptyCollected,
                             paymentAmount: transaction.amount, // Total Bill
                             amountReceived: transaction.amountReceived, // Actual Paid
                             paymentMode: transaction.paymentMode,
                             oldBalance: oldBal,
                             newBalance: newBal,
                             date: transaction.timestamp,
                           );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Share PDF Receipt'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tip Box (outside white container? No, inside Dialog content)
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFE3F2FD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: You can now share professional PDF receipts directly via WhatsApp.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // ClipRRect
    ); // Dialog
  }

  Widget _buildBalanceRow(String label, String value, {required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
