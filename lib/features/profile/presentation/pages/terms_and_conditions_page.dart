import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: March 2026',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Scope of Service',
              'HydroFlow is a Software-as-a-Service (SaaS) management platform designed to facilitate business operations for water distribution agencies. The Service provides digital tools for record-keeping, billing, inventory monitoring, and customer management.\n\nHydroFlow is strictly a technology provider and does not function as a water utility, supplier, or distributor. All physical commodities, including water products, containers, and dispensing equipment, are provided and managed solely by independent water distribution agencies ("Distributors") who utilize this platform.',
            ),
            _buildSection(
              '2. Limitation of Liability',
              'Product & Service Quality: The Distributor bears exclusive responsibility for the quality, safety, purity, and regulatory compliance of all water products delivered. Any disputes regarding health concerns, contamination, or delivery discrepancies must be addressed directly with the Distributor.\n\nLegal Protection: By utilizing the Service, Users and Consumers acknowledge and agree that HydroFlow, its developers, and affiliates shall be held harmless from any claims, damages, or legal disputes arising from the physical services or products provided by the independent Distributor.',
            ),
            _buildSection(
              '3. Subscription & Usage Policy',
              'Tiered Access: Usage is limited based on your selected subscription plan (Basic: 250 customers, Pro: 500 customers, Pro Max: 1500 customers). These limits are strictly enforced.\n\nDevice Authorization: Access is limited to a predefined number of authorized devices per subscription. Unauthorized attempts to bypass these limits or share credentials may lead to account suspension.\n\nData Responsibility: While the app ensures data persistence and cloud sync, the accuracy and integrity of the data entered is the sole responsibility of the User/Distributor.',
            ),
            _buildSection(
              '4. Privacy & Data Security',
              'Infrastructure: We utilize secure cloud infrastructure (Firebase by Google Cloud) for data storage.\n\nTechnical Responsibility: HydroFlow is not responsible for data loss due to user negligence, such as clearing local app cache or uninstalling the application before a successful cloud synchronization has occurred in offline mode.',
            ),
            _buildSection(
              '5. Fees, Refund & Cancellation',
              'Billing: Subscription fees are non-refundable. Users can cancel their subscription at any time; however, access will remain active only until the conclusion of the current prepaid billing cycle.',
            ),
            _buildSection(
              '6. Termination',
              'We reserve the right to terminate or suspend access to the Service immediately and without prior notice for any breach of these Terms, including but not limited to fraudulent activity or unauthorized usage.',
            ),
            _buildSection(
              '7. Contact Information',
              'For any questions or concerns regarding these Terms and Conditions, please contact us for support and assistance.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 HydroFlow. All rights reserved.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
