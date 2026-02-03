import 'package:flutter/material.dart';

class CurrentSubscriptionCard extends StatelessWidget {
  const CurrentSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light Green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              const Text(
                'Current Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // Close Icon if needed? The design shows just the card.
              // Oh, wait, the image 0 shows a close 'X' on top right of the Modal/Page.
              // This card itself doesn't have an X.
            ],
          ),
          const SizedBox(height: 24),
          
          _buildRow('Status', 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black, // Active pill black in image
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFA5D6A7)), // Light green divider
          const SizedBox(height: 16),
          
          _buildRow('Expires On', value: '5 February 2026', valueBold: true),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFA5D6A7)),
           const SizedBox(height: 16),

          _buildRow('Days Remaining', value: '2 days', valueColor: const Color(0xFFE65100), valueBold: true), // Orange text
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone, size: 18, color: Colors.white),
              label: const Text('Contact Admin to Renew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Dark button
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
