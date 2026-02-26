import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_event.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_state.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_state.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_event.dart';
import 'package:hydroflow/features/customers/presentation/widgets/customer_details_dialog.dart';
import 'package:hydroflow/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/features/customers/presentation/widgets/pending_balance_adjustment_dialog.dart';
import 'package:hydroflow/features/customers/presentation/widgets/bottle_balance_adjustment_dialog.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';


class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final salesman = authState.salesman;
      final prefs = sl<SharedPreferences>();
      final isAgencyView = prefs.getBool('dashboard_is_agency_view') ?? false;

      if (salesman.role == 'owner' && isAgencyView) {
        context.read<CustomerBloc>().add(LoadAgencyCustomers(salesman.agencyId));
      } else {
        context.read<CustomerBloc>().add(LoadCustomers(salesman.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {

      return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final salesman = authState.salesman;
          
          final prefs = sl<SharedPreferences>();
          final isAgencyViewPref = prefs.getBool('dashboard_is_agency_view') ?? false;
          final isOwner = salesman.role == 'owner';

          // Access CustomerBloc state
          final customerState = context.watch<CustomerBloc>().state;

          // Check for view mismatch
          if (isOwner) {
            if (isAgencyViewPref != customerState.isAgencyView) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isAgencyViewPref) {
                     context.read<CustomerBloc>().add(LoadAgencyCustomers(salesman.agencyId));
                  } else {
                     context.read<CustomerBloc>().add(LoadCustomers(salesman.id));
                  }
               });
               return const Scaffold(body: Center(child: HydroFlowLoader(message: 'Switching View...', isOverlay: false)));
            }
          }
          
          return Scaffold(
              backgroundColor: Colors.grey[50], 
              appBar: const HydroFlowAppBar(),
              body: BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state.status == CustomerStatus.loading) {
                      return const HydroFlowLoader(message: 'Loading Customers...', isOverlay: false);
                    }
                    
                    final isAgency = state.isAgencyView;
                    
                    Widget body = Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Header with Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            isAgency ? 'Agency Customers' : 'My Customers',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.grey[50],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('${state.totalCustomers}', 'Total', Colors.blue),
                              _buildStatItem('${state.activeCustomers}', 'Active', Colors.green),
                              _buildStatItem('${state.inactiveCustomers}', 'Inactive', Colors.orange),
                            ],
                          ),
                        ),

                                                // Salesman Filter (Only in Agency View)
                        if (isAgency)
                          BlocBuilder<AgencyBloc, AgencyState>(
                            builder: (context, agencyState) {
                              if (agencyState is AgencySalesmenLoaded) {
                                final salesmen = agencyState.salesmen;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: DropdownSearch<Salesman>(
                                    items: (filter, loadProps) {
                                      var filteredSalesmen = salesmen;
                                      if (state.selectedZone != null) {
                                        final activeInZone = state.customers
                                            .where((c) => c.zone == state.selectedZone)
                                            .map((c) => c.salesmanId)
                                            .toSet();
                                        filteredSalesmen = salesmen.where((s) => activeInZone.contains(s.id)).toList();
                                      }
                                      return [
                                        const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: ''),
                                        ...filteredSalesmen,
                                      ];
                                    },
                                    itemAsString: (Salesman s) => s.id == 'all' ? s.name : '${s.name} (${s.phoneNumber})',
                                    decoratorProps: DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        labelText: 'Filter by Salesman',
                                        hintText: 'Select Salesman',
                                        prefixIcon: const Icon(Icons.person_outline, color: Colors.blueGrey),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: "Search Salesman...",
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    selectedItem: state.selectedSalesmanId == null 
                                        ? const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: '')
                                        : salesmen.firstWhere((s) => s.id == state.selectedSalesmanId, orElse: () => const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: '')),
                                    onChanged: (Salesman? value) {
                                      context.read<CustomerBloc>().add(FilterBySalesman(value?.id == 'all' ? null : value?.id));
                                    },
                                    compareFn: (s1, s2) => s1.id == s2.id,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        
                        // Zone Filters Dropdown
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: DropdownSearch<String>(
                            items: (filter, loadProps) {
                              final relevantCustomers = state.selectedSalesmanId == null
                                  ? state.customers
                                  : state.customers.where((c) => c.salesmanId == state.selectedSalesmanId);
                                  
                              final zones = relevantCustomers
                                  .map((c) => c.zone)
                                  .where((z) => z.isNotEmpty)
                                  .toSet()
                                  .toList()
                                ..sort();
                              return ['All', ...zones];
                            },
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Filter by Zone',
                                hintText: 'Select or Search Zone',
                                prefixIcon: const Icon(Icons.grid_view_rounded, color: Colors.blueGrey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: Duration.zero,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search Zone...",
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                              itemBuilder: (context, item, isSelected, isHovered) {
                                return ListTile(
                                  title: Text(item, style: const TextStyle(fontSize: 14)),
                                  selected: isSelected,
                                  dense: true,
                                );
                              },
                            ),
                            selectedItem: state.selectedZone ?? 'All',
                            onChanged: (String? value) {
                              context.read<CustomerBloc>().add(FilterByZone(value == 'All' ? null : value));
                            },
                          ),
                        ),
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            onChanged: (value) {
                              context.read<CustomerBloc>().add(SearchCustomers(value));
                            },
                            decoration: InputDecoration(
                              hintText: 'Search with Name or Phone...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[200], // Simple faint grey
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Customer List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state.filteredCustomers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final customer = state.filteredCustomers[index];
                              return _buildCustomerCard(customer, salesman, isAgency);
                            },
                          ),
                        ),
                        
                      
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: SizedBox(
                           width: double.infinity,
                           child: ElevatedButton.icon(
                              onPressed: () {
                                // 1. Strict Quota Enforcement
                                if (salesman.maxCustomers > 0 && salesman.customerCount >= salesman.maxCustomers) {
                                  _showLimitExceededDialog(context, 'You have reached your assigned quota of ${salesman.maxCustomers} customers. Please contact your administrator.');
                                } else {
                                  _showAddCustomerDialog(context, salesman, isAgency);
                                }
                              },
                             icon: const Icon(Icons.add),
                             label: const Text('Add New Customer'),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF0D1117), // Dark background
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             ),
                           ),
                         ),
                       ),
                      ],
                    );

                    if (isAgency) {
                      return BlocProvider(
                        create: (context) => sl<AgencyBloc>()..add(LoadAgencySalesmen(salesman.agencyId)),
                        child: body,
                      );
                    }
                    return body;
                  },
                ),
                bottomNavigationBar: const AppBottomBar(currentIndex: 3),
              );
        }
        return const Scaffold(body: HydroFlowLoader(message: 'Authenticating...', isOverlay: false));
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  
  Widget _buildCustomerCard(dynamic customer, Salesman salesman, bool isAgency) {
    // customer is Customer
    final bool isActive = customer.status == 'Active';
    
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => CustomerDetailsDialog(
            customer: customer,
            currentUser: salesman,
            customerBloc: context.read<CustomerBloc>(),
            isAgencyView: isAgency,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               Text(
               customer.name.isNotEmpty
                   ? customer.name[0].toUpperCase() + customer.name.substring(1)
                   : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : Colors.grey[300], // Active tag black, else grey
                    borderRadius: BorderRadius.circular(12),
                  ),
                   child: Text(
                    customer.status.toLowerCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (customer.zone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    customer.zone,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  customer.phone,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.address,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pending Balance Section
            GestureDetector(
              onTap: (){
                showDialog(
                  context: context,
                  builder: (_) => PendingBalanceAdjustmentDialog(
                    customer: customer,
                    customerBloc: context.read<CustomerBloc>(),
                  ),
                );
              },
              child:
            Row(
              children: [
                Text(
                  'Pending: ₹${customer.pendingBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFE65100), // Orange
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )),
            const SizedBox(height: 4),
            
          // Bottle Balance Section
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => BottleBalanceAdjustmentDialog(
                    customer: customer,
                    customerBloc: context.read<CustomerBloc>(),
                  ),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF2962FF)),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.bottleBalance} bottles held',
                    style: const TextStyle(
                      color: Color(0xFF2962FF), // Blue
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitExceededDialog(BuildContext context, [String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Exceeded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: 12),
            ],
            const Text(
              'Please contact customer support to upgrade your plan and add more customers.',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1117),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext pageContext, Salesman salesman, bool isAgency) {
    showDialog(
      context: pageContext,
      builder: (context) => AddCustomerDialog(
        currentUser: salesman, 
        bloc: pageContext.read<CustomerBloc>(),
        isAgencyView: isAgency,
      ),
    );
  }
}
