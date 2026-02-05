import 'package:flutter/material.dart';
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

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  bool _isLoadStockExpanded = false;
  final _loadStockController = TextEditingController();
  final _damagedStockController = TextEditingController();

  @override
  void dispose() {
    _loadStockController.dispose();
    _damagedStockController.dispose();
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
          if (state is StockActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            _loadStockController.clear();
            _damagedStockController.clear();
            setState(() {
              _isLoadStockExpanded = false;
            });
          } else if (state is StockFailure) {
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${salesman.currentStock}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // // Today's Summary Card
                      // BlocBuilder<StockBloc, StockState>(
                      //   builder: (context, state) {
                      //     final log = state.todayLog;
                      //     return Container(
                      //       padding: const EdgeInsets.all(20),
                      //       decoration: BoxDecoration(
                      //         color: Colors.white,
                      //         borderRadius: BorderRadius.circular(16),
                      //         boxShadow: [
                      //           BoxShadow(
                      //             color: Colors.grey.withOpacity(0.1),
                      //             blurRadius: 10,
                      //             offset: const Offset(0, 4),
                      //           ),
                      //         ],
                      //       ),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           const Text(
                      //             "Today's Summary",
                      //             style: TextStyle(
                      //               fontSize: 18,
                      //               fontWeight: FontWeight.bold,
                      //             ),
                      //           ),
                      //           const SizedBox(height: 20),
                      //           GridView.count(
                      //             crossAxisCount: 3,
                      //             shrinkWrap: true,
                      //             physics: const NeverScrollableScrollPhysics(),
                      //             mainAxisSpacing: 20,
                      //             crossAxisSpacing: 10,
                      //             childAspectRatio: 0.85,
                      //             children: [
                      //               _buildSummaryItem(
                      //                 'Opening',
                      //                 '${log?.openingStock ?? 0}',
                      //                 Icons.start,
                      //                 Colors.purple,
                      //                 onTap: () => _showOpeningStockDialog(context, salesman.id, log?.openingStock ?? 0),
                      //               ),
                      //               _buildSummaryItem(
                      //                 'Loaded',
                      //                 '${log?.loaded ?? 0}',
                      //                 Icons.add_circle_outline,
                      //                 Colors.blueGrey,
                      //               ),
                      //               _buildSummaryItem(
                      //                 'Delivered',
                      //                 '${log?.totalDelivered ?? 0}',
                      //                 Icons.local_shipping_outlined,
                      //                 Colors.green,
                      //               ),
                      //               _buildSummaryItem(
                      //                 'Damaged',
                      //                 '${log?.damaged ?? 0}',
                      //                 Icons.error_outline,
                      //                 Colors.orange,
                      //               ),
                      //               _buildSummaryItem(
                      //                 'Empties',
                      //                 '${log?.totalEmptyCollected ?? 0}',
                      //                 Icons.recycling,
                      //                 Colors.teal,
                      //               ),
                      //               _buildSummaryItem(
                      //                 'Expected',
                      //                 '${(log?.openingStock ?? 0) + (log?.loaded ?? 0) - (log?.totalDelivered ?? 0) - (log?.damaged ?? 0)}',
                      //                 Icons.inventory,
                      //                 Colors.blue,
                      //               ),
                      //             ],
                      //           ),
                      //           if (log != null && !log.isReconciled) ...[
                      //             const SizedBox(height: 24),
                      //             SizedBox(
                      //               width: double.infinity,
                      //               child: OutlinedButton.icon(
                      //                 onPressed: () => _showReconciliationDialog(context, salesman.id, (log.openingStock + log.loaded - log.totalDelivered - log.damaged)),
                      //                 icon: const Icon(Icons.fact_check),
                      //                 label: const Text('Evening Reconciliation'),
                      //                 style: OutlinedButton.styleFrom(
                      //                   padding: const EdgeInsets.symmetric(vertical: 16),
                      //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //                 ),
                      //               ),
                      //             ),
                      //           ] else if (log != null && log.isReconciled) ...[
                      //             const SizedBox(height: 16),
                      //             Container(
                      //               padding: const EdgeInsets.all(12),
                      //               decoration: BoxDecoration(
                      //                 color: log.mismatchCount == 0 ? Colors.green[50] : Colors.orange[50],
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               child: Row(
                      //                 children: [
                      //                   Icon(
                      //                     log.mismatchCount == 0 ? Icons.check_circle : Icons.warning, 
                      //                     color: log.mismatchCount == 0 ? Colors.green : Colors.orange,
                      //                   ),
                      //                   const SizedBox(width: 12),
                      //                   Expanded(
                      //                     child: Text(
                      //                       log.mismatchCount == 0 
                      //                         ? 'Stock Reconciled: Perfect Match' 
                      //                         : 'Reconciled with mismatch: ${log.mismatchCount}',
                      //                       style: TextStyle(
                      //                         fontWeight: FontWeight.bold,
                      //                         color: log.mismatchCount == 0 ? Colors.green[800] : Colors.orange[800],
                      //                       ),
                      //                     ),
                      //                   ),
                      //                   TextButton(
                      //                     onPressed: () => _showReconciliationDialog(context, salesman.id, (log.openingStock + log.loaded - log.totalDelivered - log.damaged)),
                      //                     child: const Text('Recount'),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ],
                      //         ],
                      //       ),
                      //     );
                      //   },
                      // ),
                      // const SizedBox(height: 24),

                      // Load Stock Section
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
                            label: const Text('Morning Stock Load'),
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
                                'Load Stock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add cans to your inventory',
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
                                keyboardType: TextInputType.number,
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
                                            final qty = int.tryParse(_loadStockController.text) ?? 0;
                                            context.read<StockBloc>().add(StockLoadRequested(salesmanId: salesman.id, quantity: qty));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D1117),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Add to Stock'),
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
                              controller: _damagedStockController,
                              keyboardType: TextInputType.number,
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
                                      final qty = int.tryParse(_damagedStockController.text) ?? 0;
                                      context.read<StockBloc>().add(StockDamagedReported(salesmanId: salesman.id, quantity: qty));
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
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: const AppBottomBar(currentIndex: 1),
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  void _showOpeningStockDialog(BuildContext context, String salesmanId, int currentOpening) {
    final controller = TextEditingController(text: currentOpening.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fix Opening Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the correct starting stock for today:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Opening Stock',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This will also automatically adjust your current live inventory.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              context.read<StockBloc>().add(StockOpeningStockSet(salesmanId: salesmanId, quantity: qty));
              Navigator.pop(dialogContext);
            },
            child: const Text('Updated'),
          ),
        ],
      ),
    );
  }

  void _showReconciliationDialog(BuildContext context, String salesmanId, int expected) {
    final controller = TextEditingController(text: expected.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Evening Reconciliation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expected Full Cans in Van: $expected'),
            const SizedBox(height: 16),
            const Text('Count the actual full cans remaining in the vehicle:'),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Count',
                border: OutlineInputBorder(),
                suffixText: 'cans',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: This will close the day\'s stock count and record any mismatch.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              context.read<StockBloc>().add(StockReconciled(salesmanId: salesmanId, physicalCount: qty));
              Navigator.pop(dialogContext);
            },
            child: const Text('Finalize Reconciliation'),
          ),
        ],
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
