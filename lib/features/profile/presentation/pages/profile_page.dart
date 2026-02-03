import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/profile/presentation/widgets/contact_info_card.dart';
import 'package:hydroflow/features/profile/presentation/widgets/current_subscription_card.dart';
import 'package:hydroflow/features/profile/presentation/widgets/subscription_history_list.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app we'd pull from Bloc. For UI task matching image, we'll use "John Doe" etc via the widgets or here.
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey bg
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2962FF), // Blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0), // Image looks like a straight block actually? 
                  // Wait, looking at Image 1, it's a blue header card, but it has rounded corners at the top?
                  // Actually the whole page looks like a modal or a page.
                  // The header blue block has 'X' on top right.
                  // It looks like a Dialog or a full screen page.
                  // Let's assume full screen page.
                  // Visual: Blue rect at top.
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           Container(
                             width: 64,
                             height: 64,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               shape: BoxShape.circle,
                             ),
                             child: const Center(
                               child: Icon(Icons.person_outline, size: 32, color: Colors.white),
                             ),
                           ),
                           const SizedBox(width: 16),
                           const Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 'John Doe',
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 24,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               SizedBox(height: 4),
                               Text(
                                 'Salesman Account',
                                 style: TextStyle(
                                   color: Colors.white70,
                                   fontSize: 14,
                                 ),
                               ),
                             ],
                           )
                         ],
                       ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const [
                  ContactInfoCard(),
                  SizedBox(height: 16),
                  CurrentSubscriptionCard(),
                  SizedBox(height: 24),
                  SubscriptionHistoryList(),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Footer Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Total Subscriptions',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '3',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Total Amount Paid',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '₹2997',
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 24),
                   Text(
                     'Member since November 2025',
                     style: TextStyle(color: Colors.grey),
                   ),
                   const SizedBox(height: 24),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
