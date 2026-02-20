import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added import
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  bool _isLoadStockExpanded = false;
  final _loadStockController = TextEditingController();
  final _damagedStockController = TextEditingController();
  final _openingStockController = TextEditingController();

  @override
  void dispose() {
    _loadStockController.dispose();
    _damagedStockController.dispose();
    _openingStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final salesman = authState is AuthAuthenticated ? authState.salesman : null;
        final bloc = sl<StockBloc>();
        
        if (salesman != null) {
          final prefs = sl<SharedPreferences>();
          final isAgencyView = prefs.getBool('dashboard_is_agency_view') ?? false;
          
          // Only owners can have agency view, and only if preference is set
          if (salesman.role == 'owner' && isAgencyView) {
             bloc.add(LoadAgencyStock(salesman.agencyId));
          } else {
             bloc.add(LoadStockPage(salesman.id));
          }
        }
        return bloc;
      },
      child: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockActionLoading) {
            FocusManager.instance.primaryFocus?.unfocus();
            HydroFlowLoader.show(context, message: 'Updating Stock...');
          } else if (state is StockActionSuccess) {
            HydroFlowLoader.hide(context);
            FocusManager.instance.primaryFocus?.unfocus();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            _loadStockController.clear();
            _damagedStockController.clear();
            setState(() {
              _isLoadStockExpanded = false;
            });
          } else if (state is StockFailure) {
            HydroFlowLoader.hide(context);
            FocusManager.instance.primaryFocus?.unfocus();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              final salesman = authState.salesman;
              
              // Recalculate isAgency based on prefs (needs to match BlocProvider logic)
              final prefs = sl<SharedPreferences>();
              final isAgencyViewPref = prefs.getBool('dashboard_is_agency_view') ?? false;
              
              // Check if we need to switch views
              // We do this check here to ensure the Bloc is loaded with the correct data
              // corresponding to the current global preference.
              // Note: We use a post-frame callback or similar if we want to trigger a reload,
              // but since we are in build, we should be careful. 
              // Better approach: Check if state.isAgencyView matches pref. If not, trigger load.
              
              final isOwner = salesman.role == 'owner';
              
              // Use the state's view mode for UI rendering to ensure consistency with data
              final stockState = context.watch<StockBloc>().state;
              final isAgency = stockState.isAgencyView;

              // Synchronization Logic
              if (isOwner) {
                 if (isAgencyViewPref != stockState.isAgencyView) {
                    // Mismatch detected. Trigger reload.
                    // We must do this asynchronously to avoid build conflicts.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       if (isAgencyViewPref) {
                          context.read<StockBloc>().add(LoadAgencyStock(salesman.agencyId));
                       } else {
                          context.read<StockBloc>().add(LoadStockPage(salesman.id));
                       }
                    });
                    
                    // Show loader while switching
                    return const Scaffold(
                      body: Center(child: HydroFlowLoader(message: 'Switching View...', isOverlay: false)),
                    );
                 }
              }

              return Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: const HydroFlowAppBar(),
                body: BlocBuilder<StockBloc, StockState>(
                  builder: (context, state) {
                    if (state is StockInitial || state is StockLoading) {
                       return const Center(child: HydroFlowLoader(message: 'Fetching Stock...', isOverlay: false));
                    }

                    // Determine current stock to display
                    final currentStock = isAgency 
                        ? (state.agencyStock?['fullBottles'] ?? 0)
                        : salesman.currentStock;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Current Stock Card
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2962FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Stock',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '$currentStock',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            isAgency ? 'Agency Warehouse Stock (Full)' : 'Bottles Available',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isAgency && state.agencyStock != null) ...[
                                  const SizedBox(height: 20),
                                  const Divider(color: Colors.white24, height: 1),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildQuickStat(
                                        'Full',
                                        '${state.agencyStock?['fullBottles'] ?? 0}',
                                        Icons.check_circle_outline,
                                      ),
                                      _buildQuickStat(
                                        'Empty',
                                        '${state.agencyStock?['emptyBottles'] ?? 0}',
                                        Icons.hourglass_empty,
                                      ),
                                      _buildQuickStat(
                                        'Damaged',
                                        '${state.agencyStock?['damagedBottles'] ?? 0}',
                                        Icons.report_problem_outlined,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Opening Stock Section (Unset)
                          // For Agency: If they have logs OR have current stock > 0, we consider setup done.
                          // For Salesman: Only if they have logs (or carry forward logic handled by repo/bloc)
                          if (isAgency && !state.hasAnyLogs && currentStock == 0)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAgency ? 'Agency Opening Stock Setup' : 'Opening Stock Add',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'One-time setup to initialize your stock. This will be your starting balance.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Enter Opening Stock',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    autofocus: false,
                                    controller: _openingStockController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                      hintText: 'Enter Opening Stock',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final qtyText = _openingStockController.text;
                                        final qty = int.tryParse(qtyText) ?? 0;
                                        if (qty <= 0) return;

                                        FocusManager.instance.primaryFocus?.unfocus();

                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text('Confirm Opening Stock'),
                                            content: Text('Are you sure you want to set opening stock to $qty bottles?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  Navigator.pop(dialogContext);
                                                  if (isAgency) {
                                                     context.read<StockBloc>().add(AgencyStockOpeningStockSet(
                                                      agencyId: salesman.agencyId,
                                                      quantity: qty,
                                                     ));
                                                  } else {
                                                     context.read<StockBloc>().add(StockOpeningStockSet(
                                                      salesmanId: salesman.id, 
                                                      quantity: qty,
                                                      agencyId: salesman.agencyId,
                                                     ));
                                                  }
                                                  
                                                  _openingStockController.clear();
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Set Opening Stock'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (isAgency && state.hasAnyLogs) ...[

                            // Refill Stock Section
                            AnimatedCrossFade(
                              firstChild: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLoadStockExpanded = true;
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agency Purchase/Refill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D1117),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              secondChild: Container(
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
                                    const Text(
                                     'Agency Refill Stock',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add stock purchases to Agency Warehouse.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Number of Bottles',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _loadStockController,
                                      autofocus: false,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        hintText: 'Enter quantity',
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Builder(
                                            builder: (context) {
                                              return ElevatedButton(
                                                onPressed: () {
                                                  final qtyText = _loadStockController.text;
                                                  final qty = int.tryParse(qtyText) ?? 0;
                                                  if (qty <= 0) return;

                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) => AlertDialog(
                                                      title: const Text('Confirm Refill'),
                                                      content: Text('Are you sure you want to add $qty bottles to Agency Warehouse?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(dialogContext),
                                                          child: const Text('Cancel'),
                                                        ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              FocusManager.instance.primaryFocus?.unfocus();
                                                              Navigator.pop(dialogContext);
                                                              context.read<StockBloc>().add(AgencyStockRefillRequested(
                                                                agencyId: salesman.agencyId,
                                                                quantity: qty,
                                                              ));
                                                            },
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                                                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0D1117),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text('Refill Bottles'),
                                              );
                                            }
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isLoadStockExpanded = false;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _isLoadStockExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),

                            const SizedBox(height: 24),
                            
                            // Damaged / Return Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Agency Damaged / Return',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Log damaged bottles or returns to Agency Warehouse.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Number of Bottles',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    autofocus: false,
                                    controller: _damagedStockController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      hintText: 'Enter quantity',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Builder(
                                      builder: (context) {
                                        return ElevatedButton.icon(
                                          onPressed: () {
                                            final qtyText = _damagedStockController.text;
                                            final qty = int.tryParse(qtyText) ?? 0;
                                            if (qty <= 0) return;

                                            FocusManager.instance.primaryFocus?.unfocus();

                                            // Check if stock is sufficient
                                            if (qty > currentStock) {
                                              showDialog(
                                                context: context,
                                                builder: (dialogContext) => AlertDialog(
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
                                                        Text('You are trying to remove $qty bottles, but Agency Warehouse only has $currentStock bottles.'),
                                                        const SizedBox(height: 12),
                                                        const Text(
                                                          'This action is blocked to prevent negative stock.',
                                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                                        ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(dialogContext),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }

                                            showDialog(
                                              context: context,
                                              builder: (dialogContext) => AlertDialog(
                                                title: const Text('Confirm Removal'),
                                                content: Text('Are you sure you want to remove $qty bottles from Agency Stock (Damaged/Return)?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogContext),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      FocusManager.instance.primaryFocus?.unfocus();
                                                      Navigator.pop(dialogContext);
                                                      context.read<StockBloc>().add(AgencyStockDamagedReported(
                                                        agencyId: salesman.agencyId,
                                                        quantity: qty
                                                      ));
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.remove),
                                          label: const Text('Remove from Agency Stock'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEF5350).withOpacity(0.8),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          ],
                      ),
                    );
                  },
                ),
                bottomNavigationBar: const AppBottomBar(currentIndex: 1),
              );
            }
            return const Scaffold(
              body: Center(child: HydroFlowLoader(message: '', isOverlay: false)),
            );
          },
        ),
      ),
    );
  }


  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label, 
    String value, 
    IconData icon, 
    Color color,
    {VoidCallback? onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Colors.grey[400]),
              ],
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
