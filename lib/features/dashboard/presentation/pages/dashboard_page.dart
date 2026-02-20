import 'package:flutter/material.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:hydroflow/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hydroflow/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/core/service_locator.dart'; // Import sl for SharedPreferences

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showSubscriptionReminder = true;
  bool _isAgencyView = false; // Default to personal view
  bool _isViewSwitching = false;
  
  @override
  void initState() {
    super.initState();
    _loadPersistedView();
  }

  Future<void> _loadPersistedView() async {
    final prefs = sl<SharedPreferences>();
    final savedIsAgency = prefs.getBool('dashboard_is_agency_view') ?? false;
    
    if (mounted) {
      setState(() {
        _isAgencyView = savedIsAgency;
      });
      
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
         // Always force reload to ensure the view matches exactly what was persisted
         // since build() might have already fired with the default `false`
         _loadDashboardData(authState.salesman);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final salesman = authState.salesman;
          // Trigger initial load if not already loaded or if view changed - simplified for now to just load on build for this example, 
          // but ideally we should check if bloc has data or use a separate init method.
          // For this specific flow, let's trigger it once via a post-frame callback if needed, or rely on the user interacting.
          // However, to ensure data is loaded:
          if (context.read<DashboardBloc>().state is DashboardInitial) {
             _loadDashboardData(salesman);
          }
          
          // Subscription Logic
          final expiry = salesman.subscriptionExpiry;
          final now = DateTime.now();
          final daysRemaining = expiry != null ? expiry.difference(now).inDays : 0;
          final expiryDateStr = expiry != null ? DateFormat('d MMM y').format(expiry) : 'Unknown';
          final progress = expiry != null ? (daysRemaining / 30).clamp(0.0, 1.0) : 0.0;
          final isExpired = daysRemaining < 0;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: const HydroFlowAppBar(),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (salesman.role == 'owner' && salesman.agencyId.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _isAgencyView ? 'agency' : 'personal',
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'personal',
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text("My Personal Stats"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'agency',
                                child: Row(
                                  children: [
                                    Icon(Icons.business, size: 20, color: Colors.purple),
                                    SizedBox(width: 8),
                                    Text("Agency Stats (Warehouse)"),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                if (value == (_isAgencyView ? 'agency' : 'personal')) return;

                                final shouldSwitch = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Switch View'),
                                    content: Text(
                                      value == 'agency' 
                                        ? 'Are you sure you want to switch to Agency View?'
                                        : 'Are you sure you want to switch to Personal View?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldSwitch == true) {
                                  final isAgency = value == 'agency';
                                  setState(() {
                                    _isAgencyView = isAgency;
                                    _isViewSwitching = true;
                                  });
                                  
                                  // Save preference
                                  final prefs = sl<SharedPreferences>();
                                  await prefs.setBool('dashboard_is_agency_view', isAgency);

                                  _loadDashboardData(salesman);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                  if(_showSubscriptionReminder && expiry != null && daysRemaining <= 7) ...[
                    // Subscription Reminder Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFFFF9C4), // Red if expired, Yellow-100 if warning
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isExpired ? Colors.red.shade200 : const Color(0xFFFFF176)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isExpired ? Colors.red : const Color(0xFFF9A825), 
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.access_time_filled, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isExpired ? 'Subscription Expired' : 'Subscription Reminder',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isExpired ? Colors.red.shade900 : const Color(0xFF3E2723),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isExpired 
                                          ? 'Your subscription expired on $expiryDateStr' 
                                          : 'Your subscription expires in $daysRemaining days',
                                      style: TextStyle(
                                        color: Colors.brown[900],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.brown),
                                onPressed: () {
                                  setState(() {
                                    _showSubscriptionReminder = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Expiry Date: $expiryDateStr',
                            style: TextStyle(
                              color: isExpired ? Colors.red.shade900 : const Color(0xFF5D4037),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isExpired 
                              ? 'Please contact admin immediately to restore access.'
                              : 'Contact your administrator to renew your subscription and avoid service interruption.',
                            style: TextStyle(
                              color: isExpired ? Colors.red.shade700 : const Color(0xFF5D4037),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: isExpired ? 0 : progress,
                            backgroundColor: Colors.white54,
                            valueColor: AlwaysStoppedAnimation<Color>(isExpired ? Colors.red : const Color(0xFFF9A825)),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                   // Blue Welcome Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                         colors: [Color(0xFF2962FF), Color(0xFF1565C0)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ready to start your deliveries today?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Grid
                  BlocConsumer<DashboardBloc, DashboardState>(
                    listener: (context, state) {
                      if (state is DashboardLoaded || state is DashboardError) {
                        if (_isViewSwitching) {
                          setState(() {
                            _isViewSwitching = false;
                          });
                        }
                      }
                    },
                    builder: (context, dashboardState) {
                      if (_isViewSwitching || dashboardState is DashboardLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: HydroFlowLoader(isOverlay: false),
                        );
                      }
                      if (dashboardState is DashboardLoaded) {
                        final summary = dashboardState.summary;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0, // Increased height to prevent overflow
                          children: [
                            _buildStatCard(
                              title: 'Current Stock',
                              value: '${summary.currentStock}',
                              subtitle: 'Cans in Van',
                              valueColor: const Color(0xFF2962FF),
                              onTap: (){},
                             // onTap: () => context.push('/stock'),
                            ),
                            _buildStatCard(
                              title: 'Deliveries',
                              value: '${summary.todayDeliveries}',
                              subtitle: 'Cans Delivered',
                              valueColor: const Color(0xFFFF6D00),
                               onTap: (){},
                              //onTap: () => context.push('/delivery'),
                            ),
                            _buildStatCard(
                              title: "Today's Sales",
                              value: '₹${summary.todaySales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              subtitle: 'Total Bill Amount',
                              valueColor: const Color(0xFF6200EA),
                               onTap: (){},
                             // onTap: () => context.push('/delivery'),
                            ),
                            _buildStatCard(
                              title: "Today's Collection",
                              value: '₹${summary.todayCollection.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              subtitle: 'Cash + Online',
                              valueColor: const Color(0xFF00C853),
                               onTap: (){},
                             // onTap: () => context.push('/delivery'),
                            ),
                            _buildStatCard(
                              title: 'Active Customers',
                              value: '${summary.activeCustomers}',
                              subtitle: 'Total Active',
                              valueColor: const Color(0xFF00B8D4),
                               onTap: (){},
                              //onTap: () => context.push('/customers'),
                            ),
                            _buildStatCard(
                              title: 'Inactive Customers',
                              value: '${summary.inactiveCustomers}',
                              subtitle: 'Total Inactive',
                              valueColor: Colors.blueGrey,
                               onTap: (){},
                             // onTap: () => context.push('/customers'),
                            ),
                          ],
                        );
                      }
                      if (dashboardState is DashboardError) {
                        return Center(child: Text('Error: ${dashboardState.message}'));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const AppBottomBar(currentIndex: 0),
          );
        }
        return const HydroFlowLoader(isOverlay: false);
      },
    );
  }

  void _loadDashboardData(Salesman salesman) {
    context.read<DashboardBloc>().add(LoadDashboard(
      salesmanId: salesman.id,
      agencyId: _isAgencyView ? salesman.agencyId : null,
    ));
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                 value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
