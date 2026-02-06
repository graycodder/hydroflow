import 'package:flutter/material.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:intl/intl.dart';

class CurrentSubscriptionCard extends StatelessWidget {
  final List<SubscriptionRecord> history;

  const CurrentSubscriptionCard({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    SubscriptionRecord? activeSub;
    try {
      activeSub = history.firstWhere((sub) => sub.isActive);
    } catch (_) {
      activeSub = null;
    }

    final hasActive = activeSub != null;
    final expiryDate = hasActive ? activeSub.expiryDate : null;
    final daysRemaining = expiryDate != null ? expiryDate.difference(DateTime.now()).inDays : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0), // Green or Orange
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasActive ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: hasActive ? const Color(0xFF2E7D32) : Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Current Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildRow('Status', 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hasActive ? Colors.black : Colors.red, 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasActive ? 'Active' : 'Expired',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: hasActive ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)),
          const SizedBox(height: 16),
          
          _buildRow('Expires On', value: expiryDate != null ? DateFormat('d MMMM yyyy').format(expiryDate) : 'N/A', valueBold: true),
          
          const SizedBox(height: 16),
          Divider(height: 1, color: hasActive ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80)),
           const SizedBox(height: 16),

          _buildRow('Days Remaining', 
            value: hasActive ? '$daysRemaining days' : '0 days', 
            valueColor: daysRemaining < 5 ? const Color(0xFFE65100) : const Color(0xFF2E7D32), 
            valueBold: true
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone, size: 18, color: Colors.white),
              label: const Text('Contact Admin to Renew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, {String? value, Widget? child, Color? valueColor, bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        if (child != null) 
          child
        else
          Text(
            value ?? '',
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
      ],
    );
  }
}
