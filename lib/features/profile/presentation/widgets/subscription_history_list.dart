import 'package:flutter/material.dart';

class SubscriptionHistoryList extends StatelessWidget {
  const SubscriptionHistoryList({super.key});

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
          
          _buildUsageItem(
            isActive: true,
            planName: '30 Days Plan',
            txnId: '#TXN20260128001',
            paymentDate: '28 Jan 2026',
            amount: '₹999',
            startDate: '29 Jan',
            endDate: '28 Feb',
            duration: '30 days',
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            isActive: false,
            planName: '30 Days Plan',
            txnId: '#TXN20251229001',
            paymentDate: '29 Dec 2025',
            amount: '₹999',
            startDate: '30 Dec',
            endDate: '28 Jan',
            duration: '30 days',
          ),
          const SizedBox(height: 16),
           _buildUsageItem(
            isActive: false,
            planName: '30 Days Plan',
            txnId: '#TXN20251129001',
            paymentDate: '29 Nov 2025',
            amount: '₹999',
            startDate: '30 Nov',
            endDate: '29 Dec',
            duration: '30 days',
          ),
        ],
      ),
    );
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
  }) {
    final bgColor = isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5); // Light green or light grey
    final iconColor = isActive ? const Color(0xFF2E7D32) : Colors.grey;
    final iconBg = isActive ? Colors.white : Colors.grey[400];
    final activePillColor = isActive ? Colors.black : Colors.grey[300];
    final activePillText = isActive ? Colors.white : Colors.black54;
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
          const Divider(height: 1, color: Colors.grey), // Actually it seems to be just space or a thin line? Image 3 shows a progress bar at bottom?
          // "Plan Duration" text and a bar.
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
              value: isActive ? 0.8 : 1.0, // 80% if active, 100% if expired? Or maybe just grey bar.
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
