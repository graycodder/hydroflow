import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:watermemo/core/widgets/app_bottom_bar.dart';
import 'package:watermemo/core/widgets/hydro_flow_app_bar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_state.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_event.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:watermemo/core/widgets/hydro_flow_loader.dart';
import 'package:watermemo/features/transactions/presentation/widgets/transaction_receipt_dialog.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_state.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_event.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';
import 'package:watermemo/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return BlocProvider(
        create: (context) => sl<AgencyBloc>()
          ..add(LoadAgencySalesmen(authState.salesman.agencyId)),
        child: const DeliveryView(),
      );
    }
    return const Scaffold(
      body: Center(
        child: WaterMemoLoader(message: 'Authenticating...', isOverlay: false),
      ),
    );
  }
}

class DeliveryView extends StatefulWidget {
  const DeliveryView({super.key});

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _fullCansController = TextEditingController(
    text: '0',
  );
  final TextEditingController _emptyCansController = TextEditingController(
    text: '0',
  );
  final TextEditingController _pricePerBottleController = TextEditingController(
    text: '60',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '0',
  );
  final TextEditingController _amountReceivedController = TextEditingController(
    text: '0',
  );

  String _paymentMode = ''; // No default auto-selection
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Trigger load based on view type
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final salesman = authState.salesman;
      final prefs = sl<SharedPreferences>();
      final isAgencyView = prefs.getBool('dashboard_is_agency_view') ?? false;

      if (salesman.role == 'owner' && isAgencyView) {
        context.read<DeliveryBloc>().add(LoadAgencyDeliveries(salesman.agencyId, resetFilters: false));
      } else {
        context.read<DeliveryBloc>().add(LoadDeliveryPage(salesman.id, salesman.agencyId, salesman.zone, resetFilters: false));
      }

      // Always load agency details to get pricing settings
      context.read<AgencyBloc>().add(LoadAgencySalesmen(salesman.agencyId));
    }
  }

  @override
  void dispose() {
    _fullCansController.dispose();
    _emptyCansController.dispose();
    _pricePerBottleController.dispose();
    _priceController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    // Calculate total based on count and price per bottle
    final int quantity = int.tryParse(_fullCansController.text) ?? 0;
    final double pricePerBottle =
        double.tryParse(_pricePerBottleController.text) ?? 0.0;

    final double total = quantity * pricePerBottle;
    _priceController.text = total.toStringAsFixed(0);

    // 2. Remove aggressive reset: let user keep their input
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AgencyBloc, AgencyState>(
      listener: (context, agencyState) {
        if (agencyState is AgencySalesmenLoaded && agencyState.agency != null) {
          final agency = agencyState.agency!;
          if (agency.enforceFixedPrice) {
            _pricePerBottleController.text = agency.defaultBottlePrice.toStringAsFixed(0);
            _calculateTotal();
          }
        }
      },
      child: BlocConsumer<DeliveryBloc, DeliveryState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.selectedZone != current.selectedZone,
        listener: (context, state) {
          if (state.status == DeliveryStatus.submitting) {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            WaterMemoLoader.show(context, message: 'Submitting Transaction...');
          } else if (state.status == DeliveryStatus.submissionSuccess) {
            WaterMemoLoader.hide(context);
            _amountReceivedController.clear();
            FocusScope.of(context).unfocus();
            
            // Wait for loader to disappear before showing receipt dialog
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!context.mounted) return;
              
              if (state.todayTransactions.isNotEmpty) {
                final tx = state.todayTransactions.first;
                final customer = state.customers.cast<Customer>().firstWhere(
                      (c) => c.id == tx.customerId,
                      orElse: () => const Customer(
                        id: '',
                        salesmanId: '',
                        agencyId: '',
                        name: 'Unknown',
                        phone: '',
                        address: '',
                        status: '',
                        securityDeposit: 0,
                        pendingBalance: 0,
                        bottleBalance: 0,
                      ),
                    );
                showDialog(
                  context: context,
                  builder: (_) => TransactionReceiptDialog(
                    transaction: tx,
                    customer: customer,
                    salesmanName: (context.read<AuthBloc>().state as AuthAuthenticated).salesman.displayName,
                    agencyName: (context.read<AuthBloc>().state as AuthAuthenticated).salesman.agencyName ?? 'WaterMemo Agency',
                  ),
                );
              }
              _resetForm();
              context.read<DeliveryBloc>().add(ResetDeliveryStatus());
            });
          } else if (state.status == DeliveryStatus.failure) {
            WaterMemoLoader.hide(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
            );
            context.read<DeliveryBloc>().add(ResetDeliveryStatus());
          }
        },
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final salesman = (authState is AuthAuthenticated) ? authState.salesman : null;
          final salesmanId = salesman?.id ?? '';
          final prefs = sl<SharedPreferences>();
          final isAgencyViewPref = prefs.getBool('dashboard_is_agency_view') ?? false;
          final isOwner = salesman?.role == 'owner';

          bool isSwitchingView = false;
          if (isOwner && state.status != DeliveryStatus.initial && isAgencyViewPref != state.isAgencyView) {
            isSwitchingView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isAgencyViewPref) {
                context.read<DeliveryBloc>().add(LoadAgencyDeliveries(salesman!.agencyId, resetFilters: true));
              } else {
                context.read<DeliveryBloc>().add(LoadDeliveryPage(salesman!.id, salesman!.agencyId, salesman!.zone, resetFilters: true));
              }
            });
          }

          final isAgency = state.isAgencyView;
          Widget content;

          if (isSwitchingView) {
            content = const Center(child: WaterMemoLoader(message: 'Switching View...', isOverlay: false));
          } else if (state.status == DeliveryStatus.loading) {
            content = const Center(child: WaterMemoLoader(message: 'Syncing Delivery Data...', isOverlay: false));
          } else {
            content = SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isAgency)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildStatsHeader(state),
                    ),
                  if (isAgency)
                    BlocBuilder<AgencyBloc, AgencyState>(
                      builder: (context, agencyState) {
                        if (agencyState is AgencySalesmenLoaded) {
                          final salesmen = agencyState.salesmen;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                            child: DropdownSearch<Salesman>(
                              items: (filter, loadProps) {
                                var filteredSalesmen = salesmen;
                                if (state.selectedZone != null) {
                                  final activeInZone = state.customers.where((c) => c.zone == state.selectedZone).map((c) => c.salesmanId).toSet();
                                  filteredSalesmen = salesmen.where((s) => activeInZone.contains(s.id)).toList();
                                }
                                return [
                                  const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: ''),
                                  ...filteredSalesmen,
                                ];
                              },
                              itemAsString: (Salesman s) => s.id == 'all' ? s.name[0].toUpperCase() + s.name.substring(1) : '${s.name[0].toUpperCase() + s.name.substring(1)} (${s.phoneNumber})',
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Filter by Salesman',
                                  hintText: 'Select Salesman',
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.blueGrey),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: const TextFieldProps(decoration: InputDecoration(hintText: "Search Salesman...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
                              ),
                              selectedItem: state.selectedSalesmanId == null
                                  ? const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: '')
                                  : salesmen.firstWhere((s) => s.id == state.selectedSalesmanId, orElse: () => const Salesman(id: 'all', name: 'All Salesmen', agencyId: '', username: '', password: '', phoneNumber: '')),
                              onChanged: (Salesman? value) {
                                context.read<DeliveryBloc>().add(FilterDeliveryBySalesman(value?.id == 'all' ? null : value?.id));
                              },
                              compareFn: (s1, s2) => s1.id == s2.id,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                    child: DropdownSearch<String>(
                      items: (filter, loadProps) {
                        final Set<String> zonesSet = {};
                        
                        // 1. Add zones from customers
                        final relevantCustomers = (!isAgency || state.selectedSalesmanId == null)
                            ? state.customers
                            : state.customers.where((c) => c.salesmanId == state.selectedSalesmanId);
                        
                        for (var c in relevantCustomers) {
                          if (c.zone.trim().isNotEmpty) zonesSet.add(c.zone.trim());
                        }

                        // 2. Add assigned routes from salesman
                        if (!isAgency && salesman != null) {
                          final assigned = salesman.zone.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                          zonesSet.addAll(assigned);
                        } else if (isAgency && state.selectedSalesmanId != null) {
                           // For Agency View, get the assigned zones of the selected salesman
                           final agencyState = context.read<AgencyBloc>().state;
                           if (agencyState is AgencySalesmenLoaded) {
                             final selected = agencyState.salesmen.firstWhere((s) => s.id == state.selectedSalesmanId, orElse: () => salesman!);
                             final assigned = selected.zone.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                             zonesSet.addAll(assigned);
                           }
                        }

                        final zones = zonesSet.map((z) {
                          final trimmed = z.trim();
                          if (trimmed.isEmpty) return '';
                          return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
                        }).where((z) => z.isNotEmpty && z.toLowerCase() != 'all').toSet().toList()..sort();

                        return ['All', ...zones];
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Filter by Zone',
                          hintText: 'Select or Search Zone',
                          prefixIcon: const Icon(Icons.grid_view_rounded, color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchDelay: Duration.zero,
                        searchFieldProps: const TextFieldProps(decoration: InputDecoration(hintText: "Search Zone...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12))),
                        itemBuilder: (context, item, isSelected, isHovered) {
                          return ListTile(title: Text(item[0].toUpperCase() + item.substring(1), style: const TextStyle(fontSize: 14)), selected: isSelected, dense: true);
                        },
                      ),
                      selectedItem: (state.selectedZone == null || state.selectedZone!.isEmpty)
                          ? 'All'
                          : state.selectedZone![0].toUpperCase() + state.selectedZone!.substring(1),
                      onChanged: (String? value) {
                        context.read<DeliveryBloc>().add(FilterDeliveryByZone(value == 'All' ? null : value));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isAgency) _buildDeliveryForm(context, state, salesmanId),
                  const SizedBox(height: 10),
                  _buildTransactionsList(state),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: const WaterMemoAppBar(),
            body: content,
            bottomNavigationBar: const AppBottomBar(currentIndex: 4),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(DeliveryState state) {
    return Container(
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
      child:
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Color(0xFF1A1A2E), size: 18),
            const SizedBox(width: 8),
            const Text(
              "Today's Summary",
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (state.totalDeliveriesCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.totalDeliveriesCount} ${state.totalDeliveriesCount == 1 ? 'Delivery' : 'Deliveries'}',
                  style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Top Row: Sales, Cash, UPI
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'Total Sales',
                value: '₹${state.totalSales.toStringAsFixed(0)}',
                bgColor: const Color(0xFFEBF3FF),
                textColor: const Color(0xFF0061FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                label: 'Cash',
                value: '₹${state.totalCash.toStringAsFixed(0)}',
                bgColor: const Color(0xFFF0FAF0),
                textColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                label: 'UPI',
                value: '₹${state.totalUpi.toStringAsFixed(0)}',
                bgColor: const Color(0xFFF5F0FF),
                textColor: const Color(0xFF8B00FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Bottom Row: Delivered, Returned
        Row(
          children: [
            Expanded(
              child: _buildSimpleChip(
                label: 'Delivered',
                value: '${state.totalDelivered}',
                icon: Icons.south_east,
                bgColor: const Color(0xFFF0FAF0),
                textColor: const Color(0xFFFF5E00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSimpleChip(
                label: 'Returned',
                value: '${state.totalReturned}',
                icon: Icons.north_east,
                bgColor: const Color(0xFFF5F0FF),
                textColor: const Color(0xFF00A6A6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSimpleChip(
                label: 'Stock',
                value: '${state.currentStock}',
                icon: Icons.inventory_2_outlined,
                bgColor: const Color(0xFFF0FAF0),
                textColor: const Color(0xFF00A6A6),
              ),
            ),
          ],
        ),
      ],
    ));
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
             maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
             maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChip({
    required String label,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         // Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
             maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm(
    BuildContext context,
    DeliveryState state,
    String salesmanId,
  ) {
    final agencyState = context.watch<AgencyBloc>().state;
    bool isPriceFixed = false;
    if (agencyState is AgencySalesmenLoaded && agencyState.agency != null) {
      isPriceFixed = agencyState.agency!.enforceFixedPrice;
    }

    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF2962FF)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    Text('Select customer and fill details', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Customer Dropdown ────────────────────────────────────────
            DropdownSearch<Customer>(
              items: (filter, loadProps) => context.read<DeliveryBloc>().searchCustomers(filter),
              itemAsString: (Customer c) => c.name[0].toUpperCase()+c.name.substring(1),
              compareFn: (i, s) => i.id == s.id,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Select Customer',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchDelay: Duration.zero,
                searchFieldProps: const TextFieldProps(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, item, isSelected, isHovered) {
                  return ListTile(
                    title: Text(item.name[0].toUpperCase()+item.name.substring(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Row(
                      children: [
                        if (item.zone.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                            child: Text(item.zone[0].toUpperCase() + item.zone.substring(1), style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(item.phone, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  );
                },
              ),
              selectedItem: state.filteredCustomers.any((c) => c == state.selectedCustomer)
                  ? state.selectedCustomer
                  : null,
              onChanged: (Customer? value) {
                if (value != null) {
                  context.read<DeliveryBloc>().add(SelectCustomer(value));
                }
              },
              validator: (value) {
                if (value == null) return 'Please select a customer';
                return null;
              },
            ),

            // ── Customer Info Card ───────────────────────────────────────
            if (state.selectedCustomer != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDE5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Zone row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person, size: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.selectedCustomer!.name[0].toUpperCase()+state.selectedCustomer!.name.substring(1),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (state.selectedCustomer!.zone.isNotEmpty)
                                const SizedBox(height: 2),
                              if (state.selectedCustomer!.zone.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    state.selectedCustomer!.zone[0].toUpperCase() + state.selectedCustomer!.zone.substring(1),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stat boxes row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomerStatBox(
                            icon: Icons.local_drink_outlined,
                            iconColor: Colors.blueGrey,
                            label: 'Bottles',
                            value: '${state.selectedCustomer!.bottleBalance}',
                            valueColor: state.selectedCustomer!.bottleBalance < 0 ? Colors.red : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCustomerStatBox(
                            icon: Icons.currency_rupee,
                            iconColor: Colors.green,
                            label: 'Pending',
                            value: '₹${state.selectedCustomer!.pendingBalance.toStringAsFixed(0)}',
                            valueColor: state.selectedCustomer!.pendingBalance > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCustomerStatBox(
                            icon: Icons.location_on_outlined,
                            iconColor: Colors.grey,
                            label: 'Location',
                            value: state.selectedCustomer!.address.isNotEmpty
                                ? state.selectedCustomer!.address.split(',').first.trim()
                                : '—',
                            valueColor: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),

            // ── Bottle Steppers ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Bottles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          const Text('Full Bottles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildStepper(
                        controller: _fullCansController,
                        color: Colors.orange,
                        borderColor: Colors.orange.shade300,
                        onChanged: () => _calculateTotal(),
                      ),
                      FormField<String>(
                        validator: (_) {
                          final n = int.tryParse(_fullCansController.text) ?? 0;
                          if (n <= 0) return 'Must be > 0';
                          return null;
                        },
                        builder: (f) => f.errorText != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(f.errorText!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Empty Bottles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF00897B)),
                          const SizedBox(width: 4),
                          const Text('Empty Return', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00897B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildStepper(
                        controller: _emptyCansController,
                        color: const Color(0xFF00897B),
                        borderColor: const Color(0xFF80CBC4),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // "Use balance" centered below both steppers
            if (state.selectedCustomer != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      final balance = state.selectedCustomer!.bottleBalance;
                      if (balance > 0) {
                        setState(() {
                          _emptyCansController.text = '$balance';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Use balance (${state.selectedCustomer!.bottleBalance})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF00897B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── Rate + Live Total Banner ─────────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rate field
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerBottleController,
                      enabled: !isPriceFixed,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Rate / Bottle',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        suffixIcon: isPriceFixed ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey) : null,
                      ),
                      onChanged: (value) {
                        if (value.length > 1 && value.startsWith('0')) {
                          String newText = value.replaceFirst(RegExp(r'^0+'), '');
                          if (newText.isEmpty) newText = '0';
                          _pricePerBottleController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newText.length),
                          );
                        }
                        _calculateTotal();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Live Total preview — same size as Rate field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2962FF), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text('Total', style: TextStyle(color: Colors.white60, fontSize: 10)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  '(${_fullCansController.text.isEmpty ? '0' : _fullCansController.text}×₹${_pricePerBottleController.text.isEmpty ? '0' : _pricePerBottleController.text})',
                                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            '₹${_priceController.text.isEmpty ? '0' : _priceController.text}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),


                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Amount Received ──────────────────────────────────────────
            TextFormField(
              controller: _amountReceivedController,
              autofocus: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Amount Received (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                helperText: 'Enter actual amount received from customer',
              ),
              onChanged: (value) {
                if (value.length > 1 && value.startsWith('0')) {
                  String newText = value.replaceFirst(RegExp(r'^0+'), '');
                  if (newText.isEmpty) newText = '0';
                  _amountReceivedController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }
                setState(() {});
              },
              validator: (value) {
                if (_paymentMode == 'Credit') return null;
                if (value == null || value.isEmpty) return 'Amount received is required';
                final amount = double.tryParse(value);
                if (amount == null) return 'Please enter a valid amount';
                if ((_paymentMode == 'Cash' || _paymentMode == 'UPI') && amount <= 0) {
                  return 'Amount must be greater than 0 for $_paymentMode';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Payment Mode (merged with quick-pay) ─────────────────────
            const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentOption(
                  mode: 'Cash',
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _paymentMode = 'Cash';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildPaymentOption(
                  mode: 'UPI',
                  icon: Icons.qr_code_scanner_outlined,
                  color: Colors.purple,
                  onTap: () {
                    setState(() {
                      _paymentMode = 'UPI';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildPaymentOption(
                  mode: 'Credit',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _paymentMode = 'Credit';
                      _amountReceivedController.text = '0';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Submit Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: state.status == DeliveryStatus.loading
                    ? null
                    : () => _submitTransaction(context, salesmanId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentMode.isEmpty ? Colors.grey.shade400 : const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: _paymentMode.isEmpty ? 0 : 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _paymentMode.isEmpty
                            ? 'Select Payment Mode First'
                            : 'Confirm ₹${_amountReceivedController.text.isEmpty ? '0' : _amountReceivedController.text} · $_paymentMode',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String mode,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _paymentMode == mode;

    // Each mode has a gradient when selected
    final Map<String, List<Color>> gradients = {
      'Cash':   [const Color(0xFF00B09B), const Color(0xFF96C93D)],
      'UPI':    [const Color(0xFFB621FE), const Color(0xFFFF78AC)],
      'Credit': [const Color(0xFFFF6B35), const Color(0xFFFFB347)],
    };
    final List<Color> gradient = gradients[mode] ?? [color, color];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            border: Border.all(
              color: isSelected ? gradient.first : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
              const SizedBox(height: 6),
              Text(
                mode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStepper({
    required TextEditingController controller,
    required Color color,
    Color? borderColor,
    required VoidCallback onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Minus
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
              onTap: () {
                final current = int.tryParse(controller.text) ?? 0;
                if (current > 0) {
                  controller.text = '${current - 1}';
                  onChanged();
                }
              },
              onLongPress: () {
                // Long-press reset to 0
                controller.text = '0';
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Icon(Icons.remove, size: 16, color: color),
              ),
            ),
          ),
          // Value
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) {
                if (value.length > 1 && value.startsWith('0')) {
                  String newText = value.replaceFirst(RegExp(r'^0+'), '');
                  if (newText.isEmpty) newText = '0';
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }
                onChanged();
              },
            ),
          ),
          // Plus
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
              onTap: () {
                final current = int.tryParse(controller.text) ?? 0;
                controller.text = '${current + 1}';
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Icon(Icons.add, size: 16, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(DeliveryState state) {
    final transactionsCount = state.todayTransactions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Transactions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "$transactionsCount transactions completed",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 20),

          if (state.todayTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No transactions yet today.",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: state.todayTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = state.todayTransactions[index];
                final customer = state.customers.cast<Customer>().firstWhere(
                  (c) => c.id == tx.customerId,
                  orElse: () => const Customer(
                    id: '',
                    salesmanId: '',
                    agencyId: '',
                    name: 'Unknown',
                    phone: '',
                    address: '',
                    status: '',
                    securityDeposit: 0,
                    pendingBalance: 0,
                    bottleBalance: 0,
                  ),
                );

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase() +
                                              customer.name.substring(1)
                                        : '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(tx.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tx.paymentMode == 'Cash'
                                      ? Colors.green.shade600
                                      : tx.paymentMode == 'UPI'
                                          ? Colors.purple.shade600
                                          : tx.paymentMode == 'Credit'
                                              ? Colors.orange.shade700
                                              : Colors.blueGrey.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tx.paymentMode.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (tx.amount != tx.amountReceived &&
                          tx.type != 'Deposit')
                        Text(
                          '₹${tx.amountReceived.toStringAsFixed(0)} / ₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2962FF),
                          ),
                        )
                      else
                        Text(
                          '₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2962FF),
                          ),
                        ),
                      const Divider(height: 24, color: Color(0xFFEEEEEE)),
                      if (tx.type == 'Deposit' || tx.type == 'Deposit Received')
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Deposit Received',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else if (tx.type == 'Refund')
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Deposit Refunded',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else if (tx.paymentMode == 'Deposit Adjustment')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            tx.notes ?? 'Deposit Adjustment',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            _buildTxStatItem(
                              '↓ ${tx.cansDelivered} delivered',
                              Colors.orange,
                            ),
                            _buildTxStatItem(
                              '↑ ${tx.emptyCollected} returned',
                              Colors.teal,
                            ),
                            _buildTxStatItem(
                              '💧 ${customer.bottleBalance} balance',
                              Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTxStatItem(String text, Color color) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    // Simple formatter
    return "${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _submitTransaction(BuildContext context, String salesmanId) {
    if (_formKey.currentState!.validate()) {
      if (_paymentMode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a payment mode (Cash, UPI, or Credit)',
            ),
          ),
        );
        return;
      }

      final selectedCustomer = context
          .read<DeliveryBloc>()
          .state
          .selectedCustomer;
      if (selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer from the dropdown'),
          ),
        );
        return;
      }

      final total = double.tryParse(_priceController.text) ?? 0;
      final received = _paymentMode == 'Credit'
          ? 0.0
          : (double.tryParse(_amountReceivedController.text) ?? 0);
      final cans = int.tryParse(_fullCansController.text) ?? 0;
      final emptyCans = int.tryParse(_emptyCansController.text) ?? 0;

      // Validation: Max 1000 cans per transaction
      if (cans > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 1000 cans allowed per single transaction'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();

      // Give the keyboard a moment to start dismissing
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;

        // Check Stock Availability (Strict)
        final currentStock = context.read<DeliveryBloc>().state.currentStock;
        if (cans > currentStock) {
          _showStockErrorDialog(context, currentStock, cans);
          return;
        }

        // Check for excess empty cans and block
        if (emptyCans > selectedCustomer.bottleBalance) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text('Excess Empty Bottles'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are trying to collect $emptyCans empty bottles, but the customer only has ${selectedCustomer.bottleBalance} bottles on their balance.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Strict Blocking Enabled.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You cannot collect more empty bottles than the customer currently holds.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        _showConfirmationDialog(
          context,
          salesmanId,
          selectedCustomer,
          total,
          received,
          cans,
          emptyCans,
        );
      });
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    String salesmanId,
    Customer selectedCustomer,
    double total,
    double received,
    int cans,
    int emptyCans,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${selectedCustomer.name}'),
            const SizedBox(height: 8),
            Text('Bottles Delivered: $cans'),
            Text('Empty Bottles Returned: $emptyCans'),
            Text('Total Amount: ₹${total.toStringAsFixed(0)}'),
            Text('Amount Received: ₹${received.toStringAsFixed(0)}'),
            Text('Payment Mode: $_paymentMode'),
            const Divider(height: 24),
            const Text(
              'Are you sure you want to complete this transaction?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              
              Navigator.pop(context);
              final transaction = TransactionEntity(
                id: const Uuid().v4(),
                salesmanId: salesmanId,
                customerId: selectedCustomer.id,
                timestamp: DateTime.now(),
                type: 'delivery',
                amount: total,
                amountReceived: received,
                paymentMode: _paymentMode,
                cansDelivered: cans,
                emptyCollected: emptyCans,
                notes: '',
              );
              context.read<DeliveryBloc>().add(SubmitTransaction(transaction));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showStockErrorDialog(
    BuildContext context,
    int currentStock,
    int requested,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Insufficient Stock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are trying to deliver $requested cans, but you only have $currentStock cans in stock.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Strict Blocking Enabled.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please "Refill Stock" if you have physically loaded more cans.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _fullCansController.text = '0';
    _emptyCansController.text = '0';
    // We KEEP _pricePerBottleController text as per user requirement (it doesn't change every day)
    _priceController.text = '0';
    _amountReceivedController.clear();
    setState(() {
      _paymentMode = ''; // Clear selection
      // Selected customer is reset by BLoC state change
    });
  }
}
