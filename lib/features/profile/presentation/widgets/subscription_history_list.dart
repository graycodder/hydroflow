import 'package:flutter/material.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryList extends StatelessWidget {
  final List<SubscriptionRecord> history;

  const SubscriptionHistoryList({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: Colors.black87),
              SizedBox(width: 12),
              Text(
                'Subscription History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete history of your subscription payments',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No subscription history found.'),
              ),
            ),

          ...history.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildUsageItem(
              isActive: item.isActive,
              planName: item.planName,
              txnId: item.transactionId,
              paymentDate: DateFormat('dd MMM yyyy').format(item.paymentDate),
              amount: '₹${item.amount.toStringAsFixed(0)}',
              startDate: DateFormat('dd MMM').format(item.startDate),
              endDate: DateFormat('dd MMM').format(item.endDate),
              duration: item.duration,
              progress: _calculateProgress(item.startDate, item.endDate, item.isActive),
            ),
          )).toList(),
        ],
      ),
    );
  }

  double _calculateProgress(DateTime start, DateTime end, bool isActive) {
    if (!isActive) return 1.0;
    final total = end.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Widget _buildUsageItem({
    required bool isActive,
    required String planName,
    required String txnId,
    required String paymentDate,
    required String amount,
    required String startDate,
    required String endDate,
    required String duration,
    required double progress,
  }) {
    final bgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5);
    final statusText = isActive ? 'active' : 'expired';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: const Color(0xFFC8E6C9)) : Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey[500],
                  shape: BoxShape.circle,
                ),
                child: Icon(isActive ? Icons.check : Icons.access_time, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          planName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.black : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transaction $txnId',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildDetailCol('Payment Date', paymentDate),
               _buildDetailCol('Amount Paid', amount, valueColor: const Color(0xFF2E7D32), isBold: true),
            ],
          ),
          const SizedBox(height: 12),
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildDetailCol('Start Date', startDate),
               _buildDetailCol('End Date', endDate),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Plan Duration', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(duration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(isActive ? const Color(0xFF00C853) : Colors.grey),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCol(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
         const SizedBox(height: 4),
         Text(value, style: TextStyle(
           color: valueColor ?? Colors.black87, 
           fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
           fontSize: 14,
          )),
      ],
    );
  }
}
