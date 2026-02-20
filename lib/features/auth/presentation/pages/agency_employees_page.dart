import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_event.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/auth/presentation/widgets/add_salesman_dialog.dart';
import 'package:hydroflow/features/auth/presentation/widgets/edit_salesman_dialog.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_state.dart';
import 'package:flutter/services.dart';

class AgencyEmployeesPage extends StatelessWidget {
  const AgencyEmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current agency ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    String agencyId = '';
    
    if (authState is AuthAuthenticated) {
      agencyId = authState.salesman.agencyId;
    }

    if (agencyId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Agency ID not found')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AgencyBloc>()..add(LoadAgencySalesmen(agencyId))),
        BlocProvider(create: (context) => sl<StockBloc>()..add(LoadAgencyStock(agencyId))),
      ],
      child: Scaffold(
        appBar: const HydroFlowAppBar(),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () async {
                String agencyName = '';
                if (authState is AuthAuthenticated) {
                   agencyName = authState.salesman.agencyName ?? '';
                }

                final agencyState = context.read<AgencyBloc>().state;
                int maxCustomers = 0;
                List<Salesman> currentSalesmen = [];
                
                if (agencyState is AgencySalesmenLoaded) {
                  maxCustomers = agencyState.agency?.maxCustomers ?? 0;
                  currentSalesmen = agencyState.salesmen;
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please wait for agency details to load...')),
                    );
                    return;
                }

                final Salesman? newSalesman = await showDialog<Salesman>(
                  context: context,
                  builder: (context) => AddSalesmanDialog(
                    agencyId: agencyId,
                    agencyName: agencyName,
                    maxAgencyCustomers: maxCustomers,
                    existingSalesmen: currentSalesmen,
                  ),
                );

                if (newSalesman != null && context.mounted) {
                  context.read<AgencyBloc>().add(AddSalesman(newSalesman));
                }
              },
              label: const Text('Add Salesman'),
              icon: const Icon(Icons.person_add),
            );
          }
        ),
        body: BlocConsumer<AgencyBloc, AgencyState>(
          listener: (context, state) {
            if (state is AgencyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is AgencySalesmenLoaded && state.message != null) {
                 ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          },
          builder: (context, state) {
             if (state is AgencyLoading) {
               return const HydroFlowLoader(message: 'Loading Staff...', isOverlay: false);
             } 
             
             if (state is AgencySalesmenLoaded) {
               final salesmen = state.salesmen;
               
               if (salesmen.isEmpty) {
                 return const Center(child: Text("No staff members found."));
               }

               return ListView.separated(
                 padding: const EdgeInsets.all(16),
                 itemCount: salesmen.length,
                 separatorBuilder: (_, __) => const SizedBox(height: 12),
                 itemBuilder: (context, index) {
                   final salesman = salesmen[index];
                   final isDeviceLinked = salesman.deviceId != null && salesman.deviceId!.isNotEmpty;

                   return Container(
                     decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                     ),
                     child: ListTile(
                       onTap: () async {
                         final updatedSalesman = await showDialog<Salesman>(
                           context: context,
                           builder: (context) => EditSalesmanDialog(
                             salesman: salesman,
                             maxAgencyCustomers: state.agency?.maxCustomers ?? 0,
                             existingSalesmen: salesmen,
                           ),
                         );

                         if (updatedSalesman != null && context.mounted) {
                           context.read<AgencyBloc>().add(UpdateSalesman(updatedSalesman));
                         }
                       },
                       contentPadding: const EdgeInsets.all(16),
                       leading: CircleAvatar(
                         backgroundColor: Colors.blue[100],
                         child: Text(
                           salesman.name.isNotEmpty ? salesman.name[0].toUpperCase() : '?',
                           style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                         ),
                       ),
                       title: Text(
                         salesman.name,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       subtitle: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const SizedBox(height: 4),
                           Text(salesman.phoneNumber.isNotEmpty ? salesman.phoneNumber : 'No phone'),
                           const SizedBox(height: 4),
                           Row(
                             children: [
                               Icon(
                                 isDeviceLinked ? Icons.phonelink_lock : Icons.phonelink_off,
                                 size: 16,
                                 color: isDeviceLinked ? Colors.green : Colors.grey,
                               ),
                               const SizedBox(width: 6),
                               Text(
                                 isDeviceLinked ? 'Device Linked' : 'No Device Linked',
                                 style: TextStyle(
                                   color: isDeviceLinked ? Colors.green[700] : Colors.grey[600],
                                   fontSize: 12,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 8),
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (salesman.emptyBottles ?? 0) > 0 ? Colors.orange[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (salesman.emptyBottles ?? 0) > 0 
                                      ? Colors.orange.withOpacity(0.3) 
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_shipping, 
                                    size: 11, 
                                    color: (salesman.emptyBottles ?? 0) > 0 ? Colors.orange[700] : Colors.grey[600]
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vehicle Empties: ${salesman.emptyBottles ?? 0}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (salesman.emptyBottles ?? 0) > 0 ? Colors.orange[800] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                         ],
                       ),
                        trailing: SizedBox(
                          width: isDeviceLinked ? 96 : 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.inventory_2, color: Colors.blue),
                                tooltip: 'Stock Management',
                                onPressed: () {
                                  _showStockManagementDialog(context, salesman);
                                },
                              ),
                              if (isDeviceLinked)
                                IconButton(
                                  icon: const Icon(Icons.lock_reset, color: Colors.orange),
                                  tooltip: 'Reset Device Binding',
                                  onPressed: () {
                                    _showResetConfirmation(context, salesman);
                                  },
                                ),
                            ],
                          ),
                        ),
                     ),
                   );
                 },
               );
             }

             return const Center(child: Text("Something went wrong."));
          },
        ),
      ),
    );
  }

  void _showStockManagementDialog(BuildContext context, Salesman salesman) {
    final TextEditingController refillController = TextEditingController();
    final TextEditingController collectController = TextEditingController();
    final agencyBloc = context.read<AgencyBloc>();
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: agencyBloc),
          BlocProvider.value(value: stockBloc),
        ],
        child: DefaultTabController(
          length: 2,
          child: BlocConsumer<StockBloc, StockState>(
            listener: (context, state) {
              if (state is StockActionLoading) {
                 HydroFlowLoader.show(context, message: "Processing...");
              } else if (state is StockActionSuccess) {
                HydroFlowLoader.hide(context);
                context.read<AgencyBloc>().add(LoadAgencySalesmen(salesman.agencyId));
                
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is StockFailure) {
                HydroFlowLoader.hide(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              final warehouseStock = state.agencyStock?['fullBottles'] ?? 0;

              return AlertDialog(
                titlePadding: EdgeInsets.zero,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Stock for ${salesman.name}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: 'Refill Full'),
                        Tab(text: 'Collect Empty'),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 220,
                  child: TabBarView(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warehouse, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Warehouse: $warehouseStock full bottles',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Quantity to transfer to Vehicle:'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: refillController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Full Bottles',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.add_shopping_cart, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'On Vehicle: ${salesman.emptyBottles} empties',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Quantity to return to Warehouse:'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: collectController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Empty Bottles',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.assignment_return, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  Builder(
                    builder: (btnContext) {
                      return ElevatedButton(
                        onPressed: state is StockActionLoading
                            ? null
                            : () async {
                                final tabIndex = DefaultTabController.of(btnContext).index;
                                if (tabIndex == 0) {
                                  final qty = int.tryParse(refillController.text) ?? 0;
                                  if (qty <= 0) return;
                                  if (qty > warehouseStock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Insufficient Warehouse Stock')),
                                    );
                                    return;
                                  }
                                  
                                  final confirmed = await _showConfirmDialog(
                                    context, 
                                    'Confirm Refill', 
                                    'Are you sure you want to transfer $qty full bottles to ${salesman.name}?'
                                  );

                                  if (confirmed == true && context.mounted) {
                                    context.read<StockBloc>().add(StockLoadRequested(
                                      salesmanId: salesman.id,
                                      quantity: qty,
                                      agencyId: salesman.agencyId,
                                    ));
                                  }
                                } else {
                                  final qty = int.tryParse(collectController.text) ?? 0;
                                  if (qty <= 0) return;

                                  final confirmed = await _showConfirmDialog(
                                    context, 
                                    'Confirm Collection', 
                                    'Are you sure you want to collect $qty empty bottles from ${salesman.name}?'
                                  );

                                  if (confirmed == true && context.mounted) {
                                    context.read<StockBloc>().add(EmptyBottlesCollected(
                                      salesmanId: salesman.id,
                                      agencyId: salesman.agencyId,
                                      quantity: qty,
                                    ));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: const Text('Confirm'),
                      );
                    }
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Proceed'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, Salesman salesman) {
    final agencyBloc = context.read<AgencyBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: agencyBloc,
        child: AlertDialog(
          title: const Text('Reset Device Binding?'),
          content: Text(
            'This will allow ${salesman.name} to log in from a new device. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                agencyBloc.add(
                  ResetDevice(salesmanId: salesman.id, agencyId: salesman.agencyId)
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
