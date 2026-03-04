import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_event.dart';
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
import 'package:hydroflow/router/route_observer.dart'; // Import routeObserver
import 'package:hydroflow/features/dashboard/presentation/widgets/agency_status_cards.dart';
import 'package:hydroflow/features/dashboard/presentation/widgets/salesman_status_cards.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  bool _showSubscriptionReminder = true;
  bool _isAgencyView = false; // Default to personal view
  bool _isViewSwitching = false;
  Future<List<Salesman>>? _salesmenListFuture;
  String? _lastAgencyIdForSalesmen;
  
  @override
  void initState() {
    super.initState();
    _loadPersistedView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and the current route shows up.
    _loadPersistedView();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
         _loadDashboardData(authState.salesman, authState.originalOwner);
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
          final agency = authState.agency;
          final originalOwner = authState.originalOwner;
          final isOwner = salesman.role == 'owner' || originalOwner?.role == 'owner';
          final currentAgencyId = originalOwner?.agencyId ?? salesman.agencyId;
          
          if (isOwner && currentAgencyId.isNotEmpty) {
             if (_lastAgencyIdForSalesmen != currentAgencyId) {
                _lastAgencyIdForSalesmen = currentAgencyId;
                _salesmenListFuture = sl<AgencyRepository>().getSalesmenByAgency(currentAgencyId);
             }
          }

          // Trigger initial load if not already loaded or if view changed - simplified for now to just load on build for this example, 
          // but ideally we should check if bloc has data or use a separate init method.
          // For this specific flow, let's trigger it once via a post-frame callback if needed, or rely on the user interacting.
          // However, to ensure data is loaded:
          if (context.read<DashboardBloc>().state is DashboardInitial) {
             _loadDashboardData(salesman, originalOwner);
          }
  
          // Subscription Logic
          final expiry = agency?.subscriptionExpiry;
          final now = DateTime.now();
          final daysRemaining = expiry != null ? expiry.difference(now).inDays : 0;
          final expiryDateStr = expiry != null ? DateFormat('d MMM y').format(expiry) : 'Unknown';
          final progress = expiry != null ? (daysRemaining / 30).clamp(0.0, 1.0) : 0.0;
          final isExpired = daysRemaining < 0;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: const HydroFlowAppBar(),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isOwner && currentAgencyId.isNotEmpty) 
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: FutureBuilder<List<Salesman>>(
                            future: _salesmenListFuture,
                            builder: (context, snapshot) {
                              final salesmenList = snapshot.data ?? <Salesman>[];
                              
                              List<DropdownMenuItem<String>> items = [];
                              items.add(
                                DropdownMenuItem(
                                  value: 'agency',
                                  child: Row(
                                    children: [
                                      Icon(Icons.business, size: 20.sp, color: Colors.purple),
                                      SizedBox(width: 8.w),
                                      Text("Agency (Warehouse)", style: TextStyle(fontSize: 14.sp)),
                                    ],
                                  ),
                                ),
                              );
                              items.add(
                                DropdownMenuItem(
                                  value: 'personal',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 20.sp, color: Colors.blue),
                                      SizedBox(width: 8.w),
                                      Text("${originalOwner?.name ?? salesman.name} (Owner)", style: TextStyle(fontSize: 14.sp)),
                                    ],
                                  ),
                                ),
                              );
                              
                              for (var s in salesmenList) {
                                if (s.id == (originalOwner?.id ?? salesman.id)) continue;
                                items.add(
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, size: 20.sp, color: Colors.blue),
                                        SizedBox(width: 8.w),
                                        Text(s.name + " (" +s.role[0].toUpperCase()+s.role.substring(1)+")", style: TextStyle(fontSize: 14.sp)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              String currentValue;
                              if (originalOwner != null) {
                                currentValue = salesman.id; 
                                if (!items.any((item) => item.value == currentValue)) {
                                  items.add(
                                    DropdownMenuItem(
                                      value: currentValue,
                                      child: Row(
                                        children: [
                                          Icon(Icons.switch_account_outlined, size: 20.sp, color: Colors.green),
                                          SizedBox(width: 8.w),
                                          Text(salesman.name, style: TextStyle(fontSize: 14.sp)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                currentValue = _isAgencyView ? 'agency' : 'personal';
                              }

                              return DropdownButton<String>(
                                value: currentValue,
                                isExpanded: true,
                                items: items,
                                onChanged: (value) async {
                                  if (value == null || value == currentValue) return;

                                  if (value == 'agency' || value == 'personal') {
                                    if (originalOwner != null) {
                                        context.read<AuthBloc>().add(AuthStopImpersonationRequested());
                                    }
                                    
                                    final isAgency = value == 'agency';
                                    setState(() {
                                        _isAgencyView = isAgency;
                                        _isViewSwitching = true;
                                    });
                                    
                                    final prefs = sl<SharedPreferences>();
                                    await prefs.setBool('dashboard_is_agency_view', isAgency);
                                    
                                    if (originalOwner == null) {
                                      _loadDashboardData(salesman, null);
                                    }
                                  } else {
                                    Salesman? targetSalesman;
                                    try {
                                      targetSalesman = salesmenList.firstWhere((s) => s.id == value);
                                    } catch (_) {}
                                    
                                    if (targetSalesman != null) {
                                      context.read<AuthBloc>().add(AuthImpersonateRequested(targetSalesman));
                                      setState(() {
                                        _isViewSwitching = true;
                                      });
                                    }
                                  }
                                },
                              );
                            }
                          ),
                        ),
                      ),
                    ),

                  if(_showSubscriptionReminder && expiry != null && daysRemaining <= 7) ...[
                    // Subscription Reminder Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFFFF9C4), // Red if expired, Yellow-100 if warning
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: isExpired ? Colors.red.shade200 : const Color(0xFFFFF176)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: isExpired ? Colors.red : const Color(0xFFF9A825), 
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.access_time_filled, color: Colors.white, size: 20.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isExpired ? 'Subscription Expired' : 'Subscription Reminder',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                        color: isExpired ? Colors.red.shade900 : const Color(0xFF3E2723),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      isExpired 
                                          ? 'Your subscription expired on $expiryDateStr' 
                                          : 'Your subscription expires in $daysRemaining days',
                                      style: TextStyle(
                                        color: Colors.brown[900],
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.brown, size: 24.sp),
                                onPressed: () {
                                  setState(() {
                                    _showSubscriptionReminder = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Expiry Date: $expiryDateStr',
                            style: TextStyle(
                              color: isExpired ? Colors.red.shade900 : const Color(0xFF5D4037),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isExpired 
                              ? 'Please contact admin immediately to restore access.'
                              : 'Contact your administrator to renew your subscription and avoid service interruption.',
                            style: TextStyle(
                              color: isExpired ? Colors.red.shade700 : const Color(0xFF5D4037),
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          LinearProgressIndicator(
                            value: isExpired ? 0 : progress,
                            backgroundColor: Colors.white54,
                            valueColor: AlwaysStoppedAnimation<Color>(isExpired ? Colors.red : const Color(0xFFF9A825)),
                            minHeight: 6.h,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                   // Blue Welcome Card
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                         colors: [Color(0xFF2962FF), Color(0xFF1565C0)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Ready to start your deliveries today?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
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
                        if (_isAgencyView) {
                          return AgencyStatusCards(summary: summary);
                        } else {
                          return SalesmanStatusCards(summary: summary);
                        }
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

  void _loadDashboardData(Salesman salesman, Salesman? originalOwner) {
    context.read<DashboardBloc>().add(LoadDashboard(
      salesmanId: salesman.id,
      agencyId: (originalOwner == null && _isAgencyView) ? salesman.agencyId : null,
    ));
  }
}
