import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        final salesman = context.read<AuthBloc>().state is AuthAuthenticated 
            ? (context.read<AuthBloc>().state as AuthAuthenticated).salesman 
            : null;
        final bloc = sl<StockBloc>();
        if (salesman != null) {
          bloc.add(LoadStockPage(salesman.id));
        }
        return bloc;
      },
      child: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockLoading) {
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
              return Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: const HydroFlowAppBar(),
                body: SingleChildScrollView(
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
                                          '${salesman.currentStock}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'Cans Available',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Opeinning Stock Section
                      BlocBuilder<StockBloc, StockState>(
                        builder: (context, state) {
                          if (state is StockInitial) {
                            return const Center(child: HydroFlowLoader(message: 'Fetching Stock...', isOverlay: false));
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Opening Stock Section
                              if (!state.hasAnyLogs)

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
                                          const Text(
                                            'Opening Stock Add',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
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
                                                content: Text('Are you sure you want to set opening stock to $qty cans?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogContext),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      FocusManager.instance.primaryFocus?.unfocus();
                                                      Navigator.pop(dialogContext);
                                                      context.read<StockBloc>().add(StockOpeningStockSet(salesmanId: salesman.id, quantity: qty));
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

                              if (state.hasAnyLogs) ...[

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
                                      label: const Text('Refill Stock'),
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
                                         'Refill Stock',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add extra cans to your inventory',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Number of Cans',
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
                                                          content: Text('Are you sure you want to add $qty cans to your stock?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(dialogContext),
                                                              child: const Text('Cancel'),
                                                            ),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                                  Navigator.pop(dialogContext);
                                                                  context.read<StockBloc>().add(StockLoadRequested(salesmanId: salesman.id, quantity: qty));
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
                                                    child: const Text('Refill Cans'),
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
                                            'Damaged / Return',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Log damaged cans or returns',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Number of Cans',
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
                                                if (qty > salesman.currentStock) {
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
                                                          Text('You are trying to remove $qty cans, but you only have ${salesman.currentStock} cans in stock.'),
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
                                                    content: Text('Are you sure you want to remove $qty cans from your stock (Damaged/Return)?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(dialogContext),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          FocusManager.instance.primaryFocus?.unfocus();
                                                          Navigator.pop(dialogContext);
                                                          context.read<StockBloc>().add(StockDamagedReported(salesmanId: salesman.id, quantity: qty));
                                                        },
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
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
                          );
                        },
                      ),

                    ],
                  ),
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
