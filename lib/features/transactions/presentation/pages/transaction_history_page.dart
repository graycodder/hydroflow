import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/customer_transactions_bloc.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/customer_transactions_event.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/customer_transactions_state.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/core/utils/whatsapp_helper.dart';

class TransactionHistoryPage extends StatelessWidget {
  final Customer customer;

  const TransactionHistoryPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CustomerTransactionsBloc>()..add(LoadCustomerTransactions(customer.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction History',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                customer.name,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: BlocBuilder<CustomerTransactionsBloc, CustomerTransactionsState>(
          builder: (context, state) {
            if (state.status == CustomerTransactionsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == CustomerTransactionsStatus.failure) {
              return Center(child: Text(state.errorMessage ?? 'Failed to load transactions'));
            } else if (state.status == CustomerTransactionsStatus.success) {
              if (state.transactions.isEmpty) {
                return const Center(child: Text('No transactions found'));
              }

              // Calculate Running Balances Working Backward
              // The list is Newest -> Oldest. 
              // The current customer.pendingBalance is the balance AFTER the newest transaction.
              double currentTrackingBalance = customer.pendingBalance;
              final List<double> newBalances = [];
              final List<double> oldBalances = [];

              for (final tx in state.transactions) {
                newBalances.add(currentTrackingBalance);
                final double change = tx.amount - tx.amountReceived;
                final double oldBal = currentTrackingBalance - change;
                oldBalances.add(oldBal);
                currentTrackingBalance = oldBal;
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tx = state.transactions[index];
                  final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp);
                  final txNewBalance = newBalances[index];
                  final txOldBalance = oldBalances[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getTransactionColor(tx.type).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTransactionIcon(tx.type),
                                  color: _getTransactionColor(tx.type),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.type[0].toUpperCase() +  tx.type.substring(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (tx.type.toLowerCase() == 'delivery')
                                IconButton(
                                  icon: const Icon(Icons.share, color: Color(0xFF00C853)),
                                  onPressed: () {
                                    WhatsappHelper.sendReceipt(
                                      phone: customer.phone,
                                      customerName: customer.name,
                                      address: customer.address,
                                      delivered: tx.cansDelivered,
                                      returned: tx.emptyCollected,
                                      bottleBalance: customer.bottleBalance,
                                      amount: tx.amount,
                                      amountReceived: tx.amountReceived,
                                      isPaid: tx.amountReceived >= tx.amount,
                                      oldBalance: txOldBalance,
                                      newBalance: txNewBalance,
                                      paymentMode: tx.paymentMode,
                                      date: tx.timestamp,
                                    );
                                  },
                                  tooltip: 'Share via WhatsApp',
                                ),
                            ],
                          ),
                          const Divider(height: 24),

                          if (tx.type.toLowerCase().contains('deposit') || tx.type.toLowerCase().contains('refund')) ...[
                             // DEPOSIT DETAILS ONLY
                             _buildSectionHeader('DEPOSIT DETAILS'),
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: tx.type.toLowerCase().contains('refund') ? Colors.red.shade50 : Colors.blue.shade50,
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: tx.type.toLowerCase().contains('refund') ? Colors.red.shade100 : Colors.blue.shade100),
                               ),
                               child: Column(
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         tx.type.toLowerCase().contains('refund') ? 'Refund Amount:' : 'Deposit Amount:',
                                         style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                                       ),
                                       Text(
                                         '₹${tx.amount.toStringAsFixed(0)}',
                                         style: TextStyle(
                                           fontWeight: FontWeight.bold, 
                                           fontSize: 18, 
                                           color: tx.type.toLowerCase().contains('refund') ? Colors.red.shade700 : Colors.blue.shade700
                                         ),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 8),
                                   _buildDetailRow('Payment Mode:', tx.paymentMode.toUpperCase(), Colors.black87, isBold: true),
                                 ],
                                ),
                             ),
                          ] else ...[
                            // FULL TRANSACTION BREAKDOWN
                            // BOTTLE EXCHANGE
                            _buildSectionHeader('BOTTLE EXCHANGE'),
                            const SizedBox(height: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivered: ${tx.cansDelivered} cans',
                                  style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'Returned: ${tx.emptyCollected} cans',
                                  style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // PAYMENT DETAILS
                            _buildSectionHeader('PAYMENT DETAILS'),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '${tx.cansDelivered} can(s) x ₹${(tx.amount / (tx.cansDelivered == 0 ? 1 : tx.cansDelivered)).toStringAsFixed(0)}',
                              '₹${tx.amount.toStringAsFixed(0)}',
                              Colors.black87,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                  '₹${tx.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Payment Mode:', tx.paymentMode.toUpperCase(), Colors.black, isBold: true),
                            
                            const Divider(height: 32),

                            // BALANCE SUMMARY
                            _buildSectionHeader('BALANCE SUMMARY'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Previous Balance:', '₹${txOldBalance.toStringAsFixed(0)}', Colors.grey.shade700),
                            const SizedBox(height: 4),
                            _buildDetailRow('Current Bill:', '+ ₹${tx.amount.toStringAsFixed(0)}', Colors.orange.shade800),
                            const Divider(height: 16),
                            _buildDetailRow('Total Outstanding:', '₹${(txOldBalance + tx.amount).toStringAsFixed(0)}', Colors.black, isBold: true),
                            const SizedBox(height: 4),
                            _buildDetailRow('Amount Received:', '- ₹${tx.amountReceived.toStringAsFixed(0)}', Colors.green.shade700),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'NEW PENDING:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD32F2F)),
                                  ),
                                  Text(
                                    '₹${txNewBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD32F2F)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (tx.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tx.notes,
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Color _getTransactionColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('delivery')) return Colors.blue;
    if (t.contains('collection') || t.contains('payment')) return Colors.green;
    if (t.contains('adjustment')) return Colors.orange;
    if (t.contains('settle')) return Colors.red;
    if (t.contains('deposit')) return Colors.blueAccent;
    if (t.contains('refund')) return Colors.redAccent;
    return Colors.grey;
  }

  IconData _getTransactionIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('delivery')) return Icons.local_shipping_outlined;
    if (t.contains('collection') || t.contains('payment')) return Icons.account_balance_wallet_outlined;
    if (t.contains('adjustment')) return Icons.edit_note_outlined;
    if (t.contains('settle')) return Icons.handshake_outlined;
    if (t.contains('deposit')) return Icons.payments_outlined;
    if (t.contains('refund')) return Icons.keyboard_return_outlined;
    return Icons.history_outlined;
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }


  Widget _buildDetailRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
