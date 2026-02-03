import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_event.dart'; 
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showSubscriptionReminder = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Trigger loads for global blocs
      // Note: Stock is loaded by Auth/Salesman mostly? Or StockBloc? 
      // User snippet said StockBloc is provided. Assuming it might need loading too.
      // But let's focus on Delivery.
      context.read<DeliveryBloc>().add(LoadDeliveryPage(authState.salesman.id));
      
      // We should also trigger CustomerBloc and BottleBloc if they assume manual load.
      // But I don't see their imports here easily (user didn't provide).
      // Assuming for now focusing on Delivery as requested.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        } else if (state is AuthAuthenticated) {
             // If we just logged in or re-auth, maybe reload?
             _loadData();
        }
      },
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final salesman = authState.salesman;
          
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
                  // Stats Grid
                  BlocBuilder<DeliveryBloc, DeliveryState>(
                    builder: (context, deliveryState) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final cardWidth = (width - 16) / 2; // 16 is space between
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildStatCard(
                                width: cardWidth,
                                title: 'Current Stock',
                                value: '${salesman.currentStock}',
                                subtitle: 'Cans',
                                valueColor: const Color(0xFF2962FF),
                                onTap: () => context.push('/stock'),
                              ),
                              _buildStatCard(
                                width: cardWidth,
                                title: 'Active Customers',
                                value: '${deliveryState.customers.length}',
                                subtitle: 'Total Active',
                                valueColor: const Color(0xFF00C853),
                                onTap: () => context.push('/customers'),
                              ),
                              _buildStatCard(
                                width: cardWidth,
                                title: "Today's Sales",
                                value: '₹${deliveryState.totalSales.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                subtitle: 'Cash + Online',
                                valueColor: const Color(0xFF6200EA),
                                onTap: () => context.push('/delivery'), // Or reports?
                              ),
                              _buildStatCard(
                                width: cardWidth,
                                title: 'Deliveries',
                                value: deliveryState.status == DeliveryStatus.loading ? '...' : '${deliveryState.totalDelivered}',
                                subtitle: 'Completed',
                                valueColor: const Color(0xFFFF6D00),
                                onTap: () => context.push('/delivery'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const AppBottomBar(currentIndex: 0),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
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
