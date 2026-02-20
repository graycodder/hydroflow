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
                  // CRITICAL: Use the actual agency limit from Firebase. 
                  // If agency data isn't loaded yet, we should probably wait or warn, 
                  // but falling back to 500 can be dangerous if their limit is lower.
                  // However, for safety against null, we default to 0 to prevent over-assignment if data is missing.
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

                            //       IconButton(
                            //   icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            //   tooltip: 'Edit Details',
                            //   onPressed: () async {
                            //     final agencyState = context.read<AgencyBloc>().state;
                            //     int maxCustomers = 500;
                            //     List<Salesman> currentSalesmen = [];
                                
                            //     if (agencyState is AgencySalesmenLoaded) {
                            //       maxCustomers = agencyState.agency?.maxCustomers ?? 0;
                            //       currentSalesmen = agencyState.salesmen;
                            //     } else {
                            //        ScaffoldMessenger.of(context).showSnackBar(
                            //           const SnackBar(content: Text('Please wait for agency details to load...')),
                            //         );
                            //         return;
                            //     }

                            //     final updatedSalesman = await showDialog<Salesman>(
                            //       context: context,
                            //       builder: (context) => EditSalesmanDialog(
                            //         salesman: salesman,
                            //         maxAgencyCustomers: maxCustomers,
                            //         existingSalesmen: currentSalesmen,
                            //       ),
                            //     );

                            //     if (updatedSalesman != null && context.mounted) {
                            //       context.read<AgencyBloc>().add(UpdateSalesman(updatedSalesman));
                            //     }
                            //   },
                            // ),
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
                         ],
                       ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                   
                            IconButton(
                              icon: const Icon(Icons.inventory_2, color: Colors.blue),
                              tooltip: 'Assign Stock',
                              onPressed: () {
                                _showAssignStockDialog(context, salesman);
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

  void _showAssignStockDialog(BuildContext context, Salesman salesman) {
    final TextEditingController quantityController = TextEditingController();
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: stockBloc,
        child: BlocConsumer<StockBloc, StockState>(
          listener: (context, state) {
            if (state is StockActionLoading) {
               HydroFlowLoader.show(context, message: "Assigning Stock...");
            } else if (state is StockActionSuccess) {
              HydroFlowLoader.hide(context); // Hide Loader
              Navigator.pop(context); // Close Dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully assigned stock to ${salesman.name}')),
              );
            } else if (state is StockFailure) {
              HydroFlowLoader.hide(context); // Hide Loader
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final warehouseStock = state.agencyStock?['fullCans'] ?? 0;

            return AlertDialog(
              title: Text('Assign Stock to ${salesman.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warehouse Stock: $warehouseStock full cans',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 16),
                  const Text('Enter quantity to transfer from Warehouse to Vehicle:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: state is StockActionLoading
                      ? null
                      : () async {
                          final qty = int.tryParse(quantityController.text) ?? 0;
                          if (qty <= 0) return;
                          
                          if (qty > warehouseStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Insufficient Warehouse Stock')),
                            );
                            return;
                          }

                          // Confirmation Dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Assignment'),
                              content: Text('Are you sure you want to assign $qty full cans to ${salesman.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            context.read<StockBloc>().add(StockLoadRequested(
                                  salesmanId: salesman.id,
                                  quantity: qty,
                                  agencyId: salesman.agencyId,
                                ));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, dynamic salesman) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              Navigator.pop(dialogContext); // Close dialog
              // Use the context from where BlocProvider was created/accessible
              // Since we are in a method, we need the context that has the Bloc.
              // We passed 'context' from builder, which is correct.
              context.read<AgencyBloc>().add(
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
    );
  }
}
