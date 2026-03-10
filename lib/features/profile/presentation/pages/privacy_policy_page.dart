import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy',
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
              '1. Information Collection',
              'We collect information necessary to provide and improve our management services. This includes customer details (name, contact, address), distribution logs, and inventory data provided by the business operator.',
            ),
            _buildSection(
              '2. Data Usage',
              'The collected data is used exclusively for functional purposes: generating bills, tracking inventory, managing customer records, and facilitating distribution workflow within the WaterMemo app.',
            ),
            _buildSection(
              '3. Third-Party Services (Security)',
              'We utilize Firebase (Google Cloud Platform) for secure data storage and real-time synchronization. We do not sell or share your data with advertisers or unauthorized third parties.',
            ),
            _buildSection(
              '4. Offline Data & Synchronization',
              'Data entered in offline mode is stored locally on your device and synchronized with our secure servers once an internet connection is established. It is the user\'s responsibility to ensure successful synchronization before clearing app data.',
            ),
            _buildSection(
              '5. Your Rights',
              'Users retain ownership of the data they enter. You may update or delete customer records at any time through the application interface.',
            ),
            _buildSection(
              '6. Policy Updates',
              'We may update this Privacy Policy periodically. Continued use of the Service after changes constitutes acceptance of the revised policy.',
            ),
            _buildSection(
              '7. Contact Us',
              'If you have any questions, concerns, or requests regarding this Privacy Policy or your data, please contact our support team through the application or via our official support channels.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 WaterMemo. All rights reserved.',
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
