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
  bool _isPurchaseExpanded = false;
  bool _isRefillExpanded = false;
  final _purchaseStockController = TextEditingController();
  final _refillStockController = TextEditingController();
  final _damagedStockController = TextEditingController();
  final _openingStockController = TextEditingController();
  String _selectedDamageType = 'Full';

  @override
  void dispose() {
    _purchaseStockController.dispose();
    _refillStockController.dispose();
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
            _purchaseStockController.clear();
            _refillStockController.clear();
            _damagedStockController.clear();
            setState(() {
              _isPurchaseExpanded = false;
              _isRefillExpanded = false;
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
                                if (!isAgency) ...[
                                  const SizedBox(height: 20),
                                  const Divider(color: Colors.white24, height: 1),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildQuickStat(
                                        'Full (In Hand)',
                                        '${salesman.currentStock}',
                                        Icons.check_circle_outline,
                                      ),
                                      _buildQuickStat(
                                        'Empty (In Hand)',
                                        '${salesman.emptyBottles}',
                                        Icons.hourglass_empty,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

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

                            // Purchase Section
                            AnimatedCrossFade(
                              firstChild: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isPurchaseExpanded = true;
                                      _isRefillExpanded = false;
                                    });
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined),
                                  label: const Text('Purchase'),
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
                                     'Stock Purchase',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add new stock bottles purchased for Agency.',
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
                                      controller: _purchaseStockController,
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
                                                  final qtyText = _purchaseStockController.text;
                                                  final qty = int.tryParse(qtyText) ?? 0;
                                                  if (qty <= 0) return;

                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) => AlertDialog(
                                                      title: const Text('Confirm Purchase'),
                                                      content: Text('Are you sure you want to add $qty new bottles to Agency Warehouse?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(dialogContext),
                                                          child: const Text('Cancel'),
                                                        ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              FocusManager.instance.primaryFocus?.unfocus();
                                                              Navigator.pop(dialogContext);
                                                              context.read<StockBloc>().add(StockAgencyPurchase(
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
                                                child: const Text('Confirm Purchase'),
                                              );
                                            }
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isPurchaseExpanded = false;
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
                              crossFadeState: _isPurchaseExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),

                            const SizedBox(height: 16),

                            // Refill Section
                            AnimatedCrossFade(
                              firstChild: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isRefillExpanded = true;
                                      _isPurchaseExpanded = false;
                                    });
                                  },
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Refill (Exchange)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
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
                                     'Stock Refill',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Exchange empty bottles for full ones at the plant.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Number of Bottles to Refill',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _refillStockController,
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
                                                  final qtyText = _refillStockController.text;
                                                  final qty = int.tryParse(qtyText) ?? 0;
                                                  if (qty <= 0) return;

                                                  final availableEmpties = state.agencyStock?['emptyBottles'] ?? 0;
                                                  if (qty > availableEmpties) {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Not enough empties! Available: $availableEmpties'), 
                                                        backgroundColor: Colors.orange,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) => AlertDialog(
                                                      title: const Text('Confirm Refill'),
                                                      content: Text('Exchange $qty empties for $qty full bottles?'),
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
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2E7D32),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text('Confirm Refill'),
                                              );
                                            }
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isRefillExpanded = false;
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
                              crossFadeState: _isRefillExpanded
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
                                        'Damaged',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Log damaged bottles and remove from Agency Warehouse.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                   const SizedBox(height: 16),
                                   const Text(
                                     'Bottle Type',
                                     style: TextStyle(fontWeight: FontWeight.w600),
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                     children: [
                                       Expanded(
                                         child: GestureDetector(
                                           onTap: () => setState(() => _selectedDamageType = 'Full'),
                                           child: Container(
                                             padding: const EdgeInsets.symmetric(vertical: 12),
                                             decoration: BoxDecoration(
                                               color: _selectedDamageType == 'Full' ? Colors.blue : Colors.grey[100],
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(
                                                 color: _selectedDamageType == 'Full' ? Colors.blue : Colors.transparent,
                                               ),
                                             ),
                                             child: Center(
                                               child: Text(
                                                 'Full Stock',
                                                 style: TextStyle(
                                                   color: _selectedDamageType == 'Full' ? Colors.white : Colors.black87,
                                                   fontWeight: FontWeight.bold,
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ),
                                       ),
                                       const SizedBox(width: 12),
                                       Expanded(
                                         child: GestureDetector(
                                           onTap: () => setState(() => _selectedDamageType = 'Empty'),
                                           child: Container(
                                             padding: const EdgeInsets.symmetric(vertical: 12),
                                             decoration: BoxDecoration(
                                               color: _selectedDamageType == 'Empty' ? Colors.teal : Colors.grey[100],
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(
                                                 color: _selectedDamageType == 'Empty' ? Colors.teal : Colors.transparent,
                                               ),
                                             ),
                                             child: Center(
                                               child: Text(
                                                 'Empty Bottles',
                                                 style: TextStyle(
                                                   color: _selectedDamageType == 'Empty' ? Colors.white : Colors.black87,
                                                   fontWeight: FontWeight.bold,
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ),
                                       ),
                                     ],
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

                                             final isFromEmpty = _selectedDamageType == 'Empty';
                                             final fullBottles = state.agencyStock?['fullBottles'] ?? 0;
                                             final emptyBottles = state.agencyStock?['emptyBottles'] ?? 0;
                                             
                                             final available = isFromEmpty ? emptyBottles : fullBottles;

                                             if (qty > available) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(
                                                   content: Text('Insufficient ${isFromEmpty ? 'Empty' : 'Full'} Stock! Available: $available'), 
                                                   backgroundColor: Colors.orange
                                                 ),
                                               );
                                               return;
                                             }

                                             _confirmAndDamaged(context, salesman.agencyId, qty, isFromEmpty);
                                           },
                                           icon: const Icon(Icons.remove),
                                           label: const Text('Remove from Stock'),
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


  Widget _buildLogRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: label.startsWith(' ') ? Colors.grey[600] : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
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

  void _confirmAndDamaged(BuildContext context, String agencyId, int qty, bool fromEmpty) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Damage'),
        content: Text('Are you sure you want to remove $qty ${fromEmpty ? 'Empty' : 'Full'} bottles from Agency Stock as Damaged?'),
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
                agencyId: agencyId,
                quantity: qty,
                isFromEmpty: fromEmpty,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
