import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/profile/presentation/widgets/contact_info_card.dart';
import 'package:hydroflow/features/profile/presentation/widgets/current_subscription_card.dart';
import 'package:hydroflow/features/profile/presentation/widgets/subscription_history_list.dart';
import 'package:hydroflow/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String uid = '';
    if (authState is AuthAuthenticated) {
      uid = authState.salesman.id;
    }

    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(LoadProfile(uid)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is ProfileLoaded) {
              final profile = state.profile;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2962FF), // Blue
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${profile.role} • ${profile.zone}',
                                        style: const TextStyle(
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
                        children: [
                          ContactInfoCard(
                            phone: profile.phone,
                            address: profile.address,
                          ),
                          const SizedBox(height: 16),
                          CurrentSubscriptionCard(history: state.subscriptionHistory),
                          const SizedBox(height: 24),
                          SubscriptionHistoryList(history: state.subscriptionHistory),
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
                            children: [
                              const Text(
                                'Active Customers',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${profile.activeCustomers}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Customers',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${profile.customerCount}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Subscriptions',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${profile.totalSubscriptions}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount Paid',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '₹${profile.totalAmountPaid.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF00C853),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                           const SizedBox(height: 24),
                           Text(
                             'Member since ${DateFormat('MMMM yyyy').format(profile.membershipDate)}',
                             style: const TextStyle(color: Colors.grey),
                           ),
                           const SizedBox(height: 24),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }
            return const Center(child: Text('Initializing...'));
          },
        ),
      ),
    );
  }
}
