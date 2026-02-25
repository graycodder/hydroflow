import 'package:hydroflow/features/auth/domain/entities/agency.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

class SubscriptionLockPage extends StatelessWidget {
  final Salesman salesman;
  final Agency? agency;

  const SubscriptionLockPage({
    super.key,
    required this.salesman,
    this.agency,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }



  Future<void> _sendEmail() async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: 'graycodder@gmail.com',
      query: 'subject=Subscription Renewal - ${salesman.displayName}',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isUserDeactivated = !salesman.isActive;
    
    final userExpiryDate = salesman.subscriptionExpiry;
    final bool isUserExpired = userExpiryDate != null && 
        DateTime.now().isAfter(userExpiryDate);

    final bool isAgencyDeactivated = agency?.status != 'active';
    final agencyExpiryDate = agency?.subscriptionExpiry;
    final bool isAgencyExpired = agencyExpiryDate != null &&
        DateTime.now().isAfter(agencyExpiryDate);

    final bool isDeactivated = isAgencyDeactivated || isUserDeactivated;
    final bool isExpired = isAgencyExpired || isUserExpired;

    final expiryDate = isAgencyExpired ? agencyExpiryDate : userExpiryDate;

    final formattedDate = expiryDate != null 
        ? DateFormat('d MMMM yyyy').format(expiryDate) 
        : 'Unknown';
    
    final daysAgo = expiryDate != null 
        ? DateTime.now().difference(expiryDate).inDays 
        : 0;

    final String titleText = isAgencyDeactivated 
        ? 'Agency Deactivated' 
        : (isUserDeactivated ? 'Account Deactivated' : (isAgencyExpired ? 'Agency Subscription Expired' : 'Subscription Expired'));

    final String subtitleText = isAgencyDeactivated
        ? 'Your agency\'s access has been disabled by the administrator'
        : (isUserDeactivated 
            ? 'Your access has been disabled by the administrator'
            : (isAgencyExpired 
                ? 'Your agency\'s HydroFlow access has been suspended'
                : 'Your HydroFlow access has been suspended'));

    final String holderName = (isAgencyDeactivated || isAgencyExpired) && agency != null
        ? agency!.name
        : salesman.name;

    final String holderLabel = (isAgencyDeactivated || isAgencyExpired)
        ? 'Agency Name'
        : 'Account Holder';

    final String accountType = (isAgencyDeactivated || isAgencyExpired) ? 'agency' : 'salesman';
    final String accountOrSubscription = isDeactivated ? 'account' : 'subscription';

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
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E0000),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitleText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                                    holderLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    holderName,
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
                            
                            // Expiry/Status Info
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
                                  Icon(
                                    isDeactivated ? Icons.person_off_outlined : Icons.calendar_today_outlined, 
                                    color: const Color(0xFFD32F2F)
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isDeactivated ? 'Account Status' : 'Expired On',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[900],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isDeactivated ? 'INACTIVE' : formattedDate,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB71C1C),
                                          ),
                                        ),
                                        if (!isDeactivated && daysAgo > 0)
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
                                          isDeactivated 
                                              ? 'Please contact your administrator to reactivate the $accountType account and regain access.'
                                              : 'Please contact your administrator to renew the $accountType $accountOrSubscription and regain access to the application.',
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
                              isDeactivated ? 'Contact Administrator to Reactivate' : 'Contact Administrator to Renew',
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
                                onPressed: () => _makePhoneCall('8075050701'), 
                                icon: const Icon(Icons.phone),
                                label: Text(isDeactivated ? 'Request Activation' : 'Call Admin'),
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
                        'HydroFlow • Subscription-based SaaS',
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
