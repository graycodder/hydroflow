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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String uid = '';
    
    // Safety check for auth state
    final salesman = (authState is AuthAuthenticated) ? authState.salesman : null;
    if (salesman != null) {
      uid = salesman.id;
    }

    final prefs = sl<SharedPreferences>();
    final isAgencyViewPref = (prefs.getBool('dashboard_is_agency_view') ?? false) && (salesman?.role == 'owner');

    return BlocProvider(
      create: (context) {
        final bloc = sl<ProfileBloc>();
        if (isAgencyViewPref && salesman != null) {
          bloc.add(LoadAgencyProfile(uid, salesman.agencyId));
        } else {
          bloc.add(LoadProfile(uid));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            // Layout Logic: Check preference mismatch and reload
             if (salesman != null && salesman.role == 'owner') {
               // We need to check if the current BLoC state matches the preference
               // But BLoC state might not have initialized isAgencyView yet if it's loading initially.
               // However, `state.isAgencyView` defaults to false.
               // If pref is true, and state is false (and not loading specifically for agency), we might need to switch.
               // But we already handled initial load in `create`. 
               // This logic handles *subsequent* switches while on the page (if any external change happens? unlikely for SharedPreferences)
               // OR if the user navigates back and forth or hot reloads.
               // Actually, `dashboard_is_agency_view` key is updated by Dashboard. ProfilePage typically re-inits when navigated to.
               // But let's add the safety check similar to other pages if ProfilePage stays mounted.
               // Using addPostFrameCallback to avoid build issues.
               
               if (state.isAgencyView != isAgencyViewPref) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isAgencyViewPref) {
                      context.read<ProfileBloc>().add(LoadAgencyProfile(uid, salesman.agencyId));
                    } else {
                      context.read<ProfileBloc>().add(LoadProfile(uid));
                    }
                  });
                   return Center(child: HydroFlowLoader(message: 'Switching View...', isOverlay: false));
               }
            }

            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is ProfileLoaded) {
              final profile = state.profile;
              final isAgency = state.isAgencyView;
              final agency = state.agency;

              // Display Logic
              // Display Logic: Fallback to profile info if agency info is missing or empty
              final displayName = isAgency ? (agency?.name ?? 'Agency Name') : profile.name;
              final displayRole = isAgency ? 'Agency Profile' : '${profile.role} • ${profile.zone}';
              
              final agencyPhone = agency?.contactPhone ?? '';
              final displayPhone = (isAgency && agencyPhone.isNotEmpty) ? agencyPhone : profile.phone;
              
              final agencyAddress = agency?.address ?? '';
              final displayAddress = (isAgency && agencyAddress.isNotEmpty) ? agencyAddress : profile.address;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isAgency ? Colors.orange : const Color(0xFF2962FF), // Orange for Agency, Blue for Personal
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
                                    child: Center(
                                      child: Icon(
                                        isAgency ? Icons.business : Icons.person_outline, 
                                        size: 32, 
                                        color: Colors.white
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayRole,
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
                            phone: displayPhone,
                            address: displayAddress,
                          ),
                          
                          // Agency View: Show Subscription History & Manage Staff
                          if (isAgency) ...[
                            const SizedBox(height: 16),
                            CurrentSubscriptionCard(history: state.subscriptionHistory),
                            const SizedBox(height: 24),
                            SubscriptionHistoryList(history: state.subscriptionHistory),

                            if (profile.role == 'owner') ...[
                               const SizedBox(height: 24),
                               SizedBox(
                                 width: double.infinity,
                                 child: OutlinedButton.icon(
                                   onPressed: () => context.push('/agency_employees'),
                                   icon: const Icon(Icons.people_outline),
                                   label: const Text('Manage Staff & Devices'),
                                   style: OutlinedButton.styleFrom(
                                     padding: const EdgeInsets.symmetric(vertical: 16),
                                     side: const BorderSide(color: Colors.blue),
                                     foregroundColor: Colors.blue,
                                   ),
                                 ),
                               ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Footer Info - Show only for Agency View? Or both?
                    // User said: "if view is personal only need to show contact information and Terms and conditions and Privacy polict"
                    // User said: "view is agency need to show all others"
                    // So Personal View gets Contact + Terms + Privacy.
                    // Agency View gets Contact + Agency Details + Subscriptions + Stats + Terms + Privacy?
                    // Or simply "all others" means including Terms/Privacy.
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                      child: Column(
                        children: [  
                          if (isAgency) ...[
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
                             const SizedBox(height: 16),
                          ],
                           
                           // Terms and Privacy - Show for BOTH (explicitly requested for Personal)
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               TextButton.icon(
                                 onPressed: () => context.push('/terms'),
                                 icon: const Icon(Icons.description_outlined, size: 18, color: Colors.blue),
                                 label: const Text('Terms', style: TextStyle(color: Colors.blue)),
                               ),
                               const SizedBox(width: 16),
                               TextButton.icon(
                                 onPressed: () => context.push('/privacy'),
                                 icon: const Icon(Icons.privacy_tip_outlined, size: 18, color: Colors.blue),
                                 label: const Text('Privacy', style: TextStyle(color: Colors.blue)),
                               ),
                             ],
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

  Widget _buildAgencyStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.orange.shade800)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
