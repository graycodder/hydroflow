import 'package:flutter/material.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionLockPage extends StatelessWidget {
  final Salesman salesman;

  const SubscriptionLockPage({
    super.key,
    required this.salesman,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail() async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: 'support@hydroflowpro.com',
      query: 'subject=Subscription Renewal - ${salesman.name}',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiryDate = salesman.subscriptionExpiry;
    final formattedDate = expiryDate != null 
        ? DateFormat('d MMMM yyyy').format(expiryDate) 
        : 'Unknown';
    
    final daysAgo = expiryDate != null 
        ? DateTime.now().difference(expiryDate).inDays 
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDECEC), // Very light red background
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const SizedBox(height: 50),
                      // Lock Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // White Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Subscription Expired',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your HydroFlow Pro access has been suspended',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFD32F2F),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Account Holder Info
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Holder',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    salesman.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Expiry Info
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFEBEE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Color(0xFFD32F2F)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expired On',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[900],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB71C1C),
                                          ),
                                        ),
                                        if (daysAgo > 0)
                                          Text(
                                            '$daysAgo days ago',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red[300],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Warning Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9EE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFF3E0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'All features are currently locked',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Please contact your administrator to renew your subscription and regain access to the application.',
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            Text(
                              'Contact Administrator to Renew',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Call Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall('+919876500000'), // Replace with actual admin number
                                icon: const Icon(Icons.phone),
                                label: const Text('Call Admin: +91 98765 00000'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF030303),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Email Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _sendEmail,
                                icon: const Icon(Icons.email_outlined),
                                label: const Text('Email Support'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text(
                        'Your data is safe and will be restored upon renewal',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'HydroFlow Pro • Subscription-based SaaS',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
