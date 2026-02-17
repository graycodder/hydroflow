import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_event.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/transactions/presentation/widgets/transaction_receipt_dialog.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryView();
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
    // Trigger load if needed.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<DeliveryBloc>().add(LoadDeliveryPage(authState.salesman.id));
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
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.selectedZone != current.selectedZone,
      listener: (context, state) {
        // 1. Handle submission loader dismissal (if active)
        if (state.status != DeliveryStatus.submitting &&
            ModalRoute.of(context)?.isCurrent == false) {
          // We only pop if we are sure the current route is NOT the DeliveryPage
          // Note: This assumes the loader is the only thing that could be on top.
          // However, if the receipt dialog is already up, we don't want to pop it.
          // A safer way is using a Navigator observer or checking route names,
          // but AlertDialog usually doesn't have a unique name easily accessible here.
          // Let's use rootNavigator: true to be specific to the loader dialog.
        }

        // 2. Handle specific actions based on status transitions
        if (state.status == DeliveryStatus.submitting) {
          HydroFlowLoader.show(context, message: 'Submitting Transaction...');
        } else if (state.status == DeliveryStatus.submissionSuccess) {
          HydroFlowLoader.hide(context);
          _amountReceivedController.clear();

          FocusScope.of(context).unfocus();
          if (state.todayTransactions.isNotEmpty) {
            final tx = state.todayTransactions.first;
            final customer = state.customers.cast<Customer>().firstWhere(
              (c) => c.id == tx.customerId,
              orElse: () => const Customer(
                id: '',
                salesmanId: '',
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
                salesmanName:
                    (context.read<AuthBloc>().state as AuthAuthenticated)
                        .salesman
                        .displayName,
              ),
            );
          }
          _resetForm();
        } else if (state.status == DeliveryStatus.failure) {
          HydroFlowLoader.hide(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        }
      },
      builder: (context, state) {
        final authState = context
            .watch<AuthBloc>()
            .state; // Use watch for updates
        final salesman = (authState is AuthAuthenticated)
            ? authState.salesman
            : null;
        final salesmanId = salesman?.id ?? '';

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: const HydroFlowAppBar(),
          body: state.status == DeliveryStatus.loading
              ? const HydroFlowLoader(
                  message: 'Syncing Delivery Data...',
                  isOverlay: false,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zone Filters Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8.0,
                        ),
                        child: DropdownSearch<String>(
                          items: (filter, loadProps) {
                            final zones =
                                state.customers
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
                              prefixIcon: const Icon(
                                Icons.grid_view_rounded,
                                color: Colors.blueGrey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                            itemBuilder:
                                (context, item, isSelected, isHovered) {
                                  return ListTile(
                                    title: Text(
                                      item,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    selected: isSelected,
                                    dense: true,
                                  );
                                },
                          ),
                          selectedItem: state.selectedZone ?? 'All',
                          onChanged: (String? value) {
                            context.read<DeliveryBloc>().add(
                              FilterDeliveryByZone(
                                value == 'All' ? null : value,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Form Card
                      _buildDeliveryForm(context, state, salesmanId),

                      const SizedBox(height: 24),

                      // Transactions List
                      _buildTransactionsList(state),
                    ],
                  ),
                ),
          bottomNavigationBar: AppBottomBar(
            currentIndex: 4,
          ), // Index 4 for Delivery
        );
      },
    );
  }

  Widget _buildStatsHeader(DeliveryState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Total Sales',
                '₹${state.totalSales.toStringAsFixed(0)}',
                Colors.blue[50]!,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoCard(
                'Cash',
                '₹${state.totalCash.toStringAsFixed(0)}',
                Colors.green[50]!,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoCard(
                'UPI',
                '₹${state.totalUpi.toStringAsFixed(0)}',
                Colors.purple[50]!,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Delivered',
                '↓ ${state.totalDelivered}',
                Colors.orange[50]!,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoCard(
                'Returned',
                '↑ ${state.totalReturned}',
                Colors.teal[50]!,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
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
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  "Record Delivery & Return",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Dropdown
            // Customer Dropdown with Search
            DropdownSearch<Customer>(
              items: (filter, loadProps) {
                final activeCustomers = state.filteredCustomers
                    .where((c) => c.status == 'Active')
                    .toList();
                if (filter.isEmpty) return activeCustomers;

                final query = filter.toLowerCase();
                final filtered = activeCustomers.where((c) {
                  return c.name.toLowerCase().contains(query) ||
                      c.phone.contains(query);
                }).toList();

                // Sort: prioritize those starting with the query
                filtered.sort((a, b) {
                  final aNameMatch = a.name.toLowerCase().startsWith(query);
                  final bNameMatch = b.name.toLowerCase().startsWith(query);
                  if (aNameMatch && !bNameMatch) return -1;
                  if (!aNameMatch && bNameMatch) return 1;
                  return a.name.compareTo(b.name);
                });

                return filtered;
              },
              itemAsString: (Customer c) => c.name,
              compareFn: (i, s) => i.id == s.id,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Select Customer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchDelay: Duration.zero,
                searchFieldProps: const TextFieldProps(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "Search with Name or Phone...",
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, item, isSelected, isHovered) {
                  return ListTile(
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        if (item.zone.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.zone,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            item.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  );
                },
              ),
              selectedItem:
                  state.filteredCustomers.any(
                    (c) => c == state.selectedCustomer,
                  )
                  ? state.selectedCustomer
                  : null,
              onChanged: (Customer? value) {
                if (value != null) {
                  context.read<DeliveryBloc>().add(SelectCustomer(value));
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a customer';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Quantities
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fullCansController,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Full Cans',
                      prefixIcon: Icon(
                        Icons.arrow_downward,
                        color: Colors.orange,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculateTotal(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final n = int.tryParse(value);
                      if (n == null) return 'Invalid';
                      if (n < 0) return 'Cannot be negative';
                      // Strict "Must be > 0"? User's manual edit suggested cans==0 is blocked.
                      // User asked: "show same validation error message like Amount Received Texfiled ? for Full Cans TextFormField"
                      // Amount Received validator checks for > 0.
                      // I will enforce > 0 to match user intent.
                      if (n <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emptyCansController,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Empty Cans',
                      prefixIcon: Icon(Icons.arrow_upward, color: Colors.teal),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price Per Bottle
            TextFormField(
              controller: _pricePerBottleController,
              autofocus: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Price Per Bottle (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                hintText: 'Enter rate per bottle',
              ),
              onChanged: (_) => _calculateTotal(),
            ),

            const SizedBox(height: 16),

            // Total Amount
            TextFormField(
              controller: _priceController,
              autofocus: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total Amount (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                helperText: "Auto-calculated: Full Cans × Rate",
              ),
            ),

            const SizedBox(height: 16),

            // Amount Received (Partial Payment)
            TextFormField(
              controller: _amountReceivedController,
              autofocus: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                helperText: "Mandatory: Enter actual amount received",
              ),
              validator: (value) {
                if (_paymentMode == 'Credit')
                  return null; // Credit implies 0 received, no validation needed
                if (value == null || value.isEmpty) {
                  return 'Amount received is required';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid amount';
                }
                if ((_paymentMode == 'Cash' || _paymentMode == 'UPI') &&
                    amount <= 0) {
                  return 'Amount must be greater than 0 for $_paymentMode';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Payment Mode
            const Text(
              "Payment Mode",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentRadio('Cash', Icons.money),
                const SizedBox(width: 12),
                _buildPaymentRadio('UPI', Icons.qr_code),
                const SizedBox(width: 12),
                _buildPaymentRadio(
                  'Credit',
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: state.status == DeliveryStatus.loading
                    ? null
                    : () => _submitTransaction(context, salesmanId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete Transaction',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String mode, IconData icon) {
    final bool isSelected = _paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF2962FF) : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF2962FF) : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                mode,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2962FF)
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
                                  color: Colors.black,
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

      // Check Stock Availability (Strict)
      final currentStock = context.read<DeliveryBloc>().state.currentStock;
      if (cans > currentStock) {
        _showStockErrorDialog(context, currentStock, cans);
        return;
      }

      // Check for excess empty cans and warn
      if (emptyCans > selectedCustomer.bottleBalance) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Excess Empty Cans Warning',
              style: TextStyle(color: Colors.orange),
            ),
            content: Text(
              'The customer is returning $emptyCans empty cans, but their current balance is only ${selectedCustomer.bottleBalance}.\n\n'
              'This will result in a negative bottle balance data discrepancy.\n\n'
              'Are you sure you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close warning
                  _showConfirmationDialog(
                    context,
                    salesmanId,
                    selectedCustomer,
                    total,
                    received,
                    cans,
                    emptyCans,
                  ); // Proceed
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'Connect Anyway',
                  style: TextStyle(color: Colors.white),
                ),
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
            Text('Empty Cans Returned: $emptyCans'),
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
    _amountReceivedController.text = '0';
    setState(() {
      _paymentMode = ''; // Clear selection
      // Selected customer is reset by BLoC state change
    });
  }
}
