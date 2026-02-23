import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_event.dart';
import 'package:hydroflow/features/auth/presentation/bloc/agency_state.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/auth/presentation/widgets/add_salesman_dialog.dart';
import 'package:hydroflow/features/auth/presentation/widgets/edit_salesman_dialog.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_state.dart';
import 'package:intl/intl.dart';

// ─── Colour palette ────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1565C0);
const _kGreen = Color(0xFF2E7D32);
const _kOrange = Color(0xFFE65100);
const _kRed = Color(0xFFB71C1C);
const _kBg = Color(0xFFF2F4F8);

class AgencyEmployeesPage extends StatelessWidget {
  const AgencyEmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String agencyId = '';
    String agencyName = '';

    if (authState is AuthAuthenticated) {
      agencyId = authState.salesman.agencyId;
      agencyName = authState.salesman.agencyName ?? '';
    }

    if (agencyId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Agency ID not found')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) =>
                sl<AgencyBloc>()..add(LoadAgencySalesmen(agencyId))),
        BlocProvider(
            create: (_) =>
                sl<StockBloc>()..add(LoadAgencyStock(agencyId))),
        BlocProvider(
            create: (_) => sl<ReportsBloc>()
              ..add(LoadAgencyDailyReport(agencyId, DateTime.now()))),
      ],
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: const HydroFlowAppBar(
          showProfile: false,
          showNotifications: false,
        ),
        floatingActionButton: _AddSalesmanFab(
            agencyId: agencyId, agencyName: agencyName, authState: authState),
        body: BlocConsumer<AgencyBloc, AgencyState>(
          listener: (context, state) {
            if (state is AgencyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)));
            } else if (state is AgencySalesmenLoaded &&
                state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message!)));
            }
          },
          builder: (context, state) {
            if (state is AgencyLoading) {
              return const HydroFlowLoader(
                  message: 'Loading Staff...', isOverlay: false);
            }

            if (state is AgencySalesmenLoaded) {
              final salesmen = state.salesmen;
              final agency = state.agency;

              return BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, reportsState) {
                  final report = reportsState is ReportsLoaded
                      ? reportsState.report
                      : null;

                  return CustomScrollView(
                    slivers: [
                      // ── Header summary bar ──
                      SliverToBoxAdapter(
                        child: _SummaryHeader(
                          salesmen: salesmen,
                          agency: agency,
                          report: report,
                        ),
                      ),

                      // ── List title ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            children: [
                              const Text(
                                'TEAM MEMBERS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${salesmen.length} member${salesmen.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Salesman cards ──
                      if (salesmen.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No staff members yet.',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final salesman = salesmen[index];
                                final effectiveReport =
                                    (report?.subReports ?? [])
                                        .cast<ReportEntity?>()
                                        .firstWhere(
                                          (sr) =>
                                              sr?.salesmanId == salesman.id,
                                          orElse: () => null,
                                        );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _SalesmanCard(
                                    salesman: salesman,
                                    report: effectiveReport,
                                    isReportsLoading:
                                        reportsState is ReportsLoading,
                                    agencyId: agencyId,
                                    allSalesmen: salesmen,
                                    agency: agency,
                                    onEdit: (updated) => context
                                        .read<AgencyBloc>()
                                        .add(UpdateSalesman(updated)),
                                    onStockTap: () =>
                                        _showStockDialog(context, salesman),
                                    onResetDevice: () =>
                                        _showResetConfirmation(
                                            context, salesman),
                                  ),
                                );
                              },
                              childCount: salesmen.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            }

            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }

  // ─── Stock management dialog ─────────────────────────────────────────────
  void _showStockDialog(BuildContext context, Salesman salesman) {
    final refillCtrl = TextEditingController();
    final collectCtrl = TextEditingController();
    final agencyBloc = context.read<AgencyBloc>();
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (dialogCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: agencyBloc),
          BlocProvider.value(value: stockBloc),
        ],
        child: DefaultTabController(
          length: 2,
          child: BlocConsumer<StockBloc, StockState>(
            listener: (ctx, state) {
              if (state is StockActionLoading) {
                HydroFlowLoader.show(ctx, message: 'Processing...');
              } else if (state is StockActionSuccess) {
                HydroFlowLoader.hide(ctx);
                ctx
                    .read<AgencyBloc>()
                    .add(LoadAgencySalesmen(salesman.agencyId));
                if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)));
              } else if (state is StockFailure) {
                HydroFlowLoader.hide(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red));
              }
            },
            builder: (ctx, state) {
              final warehouseStock =
                  state.agencyStock?['fullBottles'] ?? 0;
              return AlertDialog(
                titlePadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2,
                                color: _kBlue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Stock — ${salesman.name}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      labelColor: _kBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: _kBlue,
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
                      _StockTabContent(
                        icon: Icons.warehouse,
                        iconColor: _kBlue,
                        bgColor: _kBlue.withOpacity(0.08),
                        infoText:
                            'Warehouse: $warehouseStock full bottles',
                        label: 'Quantity to transfer to Vehicle:',
                        fieldLabel: 'Full Bottles',
                        fieldIcon: Icons.add_shopping_cart,
                        fieldColor: _kBlue,
                        controller: refillCtrl,
                      ),
                      _StockTabContent(
                        icon: Icons.local_shipping,
                        iconColor: _kOrange,
                        bgColor: _kOrange.withOpacity(0.08),
                        infoText:
                            'On Vehicle: ${salesman.emptyBottles} empties',
                        label: 'Quantity to return to Warehouse:',
                        fieldLabel: 'Empty Bottles',
                        fieldIcon: Icons.assignment_return,
                        fieldColor: _kOrange,
                        controller: collectCtrl,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancel'),
                  ),
                  Builder(
                    builder: (btnCtx) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: state is StockActionLoading
                          ? null
                          : () async {
                              final tabIdx =
                                  DefaultTabController.of(btnCtx).index;
                              if (tabIdx == 0) {
                                final qty =
                                    int.tryParse(refillCtrl.text) ?? 0;
                                if (qty <= 0) return;
                                if (qty > warehouseStock) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Insufficient Warehouse Stock')),
                                  );
                                  return;
                                }
                                final ok = await _confirm(
                                    context,
                                    'Confirm Refill',
                                    'Transfer $qty full bottles to ${salesman.name}?');
                                if (ok == true && context.mounted) {
                                  context.read<StockBloc>().add(
                                      StockLoadRequested(
                                        salesmanId: salesman.id,
                                        quantity: qty,
                                        agencyId: salesman.agencyId,
                                      ));
                                }
                              } else {
                                final qty =
                                    int.tryParse(collectCtrl.text) ?? 0;
                                if (qty <= 0) return;
                                final ok = await _confirm(
                                    context,
                                    'Confirm Collection',
                                    'Collect $qty empty bottles from ${salesman.name}?');
                                if (ok == true && context.mounted) {
                                  context.read<StockBloc>().add(
                                      EmptyBottlesCollected(
                                        salesmanId: salesman.id,
                                        agencyId: salesman.agencyId,
                                        quantity: qty,
                                      ));
                                }
                              }
                            },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirm(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue, foregroundColor: Colors.white),
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
      builder: (dialogCtx) => BlocProvider.value(
        value: agencyBloc,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Device Binding?'),
          content: Text(
              'This will allow ${salesman.name} to log in from a new device. Are you sure?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                agencyBloc.add(ResetDevice(
                    salesmanId: salesman.id,
                    agencyId: salesman.agencyId));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange, foregroundColor: Colors.white),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB
// ─────────────────────────────────────────────────────────────────────────────
class _AddSalesmanFab extends StatelessWidget {
  final String agencyId;
  final String agencyName;
  final AuthState authState;

  const _AddSalesmanFab(
      {required this.agencyId,
      required this.agencyName,
      required this.authState});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: _kBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add_rounded),
      label: const Text('Add Salesman',
          style: TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () async {
        final agencyState = context.read<AgencyBloc>().state;
        int maxCustomers = 0;
        List<Salesman> currentSalesmen = [];
        String resolvedName = agencyName;

        if (agencyState is AgencySalesmenLoaded) {
          maxCustomers = agencyState.agency?.maxCustomers ?? 0;
          currentSalesmen = agencyState.salesmen;
          resolvedName = agencyState.agency?.name ?? agencyName;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Please wait for agency details to load...')));
          return;
        }

        final Salesman? newSalesman = await showDialog<Salesman>(
          context: context,
          builder: (_) => AddSalesmanDialog(
            agencyId: agencyId,
            agencyName: resolvedName,
            maxAgencyCustomers: maxCustomers,
            existingSalesmen: currentSalesmen,
          ),
        );

        if (newSalesman != null && context.mounted) {
          context.read<AgencyBloc>().add(AddSalesman(newSalesman));
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Header
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final List<Salesman> salesmen;
  final Agency? agency;
  final dynamic report;

  const _SummaryHeader({
    required this.salesmen,
    required this.agency,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final linked = salesmen.where((s) =>
        s.deviceId != null && s.deviceId!.isNotEmpty).length;
    final totalStock =
        salesmen.fold<int>(0, (sum, s) => sum + s.currentStock);
    final totalEmpty =
        salesmen.fold<int>(0, (sum, s) => sum + s.emptyBottles);

    // compute total outstanding from sub-reports
    double totalOutstanding = 0;
    if (report != null) {
      for (final sr in (report.subReports ?? [])) {
        totalOutstanding += (sr.cashInHand as num? ?? 0) +
            (sr.salesmanPreviousBalance as num? ?? 0) -
            (sr.settlementAmountToday as num? ?? 0);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                agency?.name ?? 'Staff Overview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today ${DateFormat('dd MMM').format(DateTime.now())}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeaderStat(
                  label: 'Total Staff',
                  value: '${salesmen.length}',
                  icon: Icons.badge_outlined),
              _HeaderDivider(),
              _HeaderStat(
                  label: 'Linked',
                  value: '$linked',
                  icon: Icons.phonelink_lock_outlined),
              _HeaderDivider(),
              _HeaderStat(
                  label: 'Full Stock',
                  value: '$totalStock',
                  icon: Icons.local_drink_outlined),
              _HeaderDivider(),
              _HeaderStat(
                  label: 'Empties',
                  value: '$totalEmpty',
                  icon: Icons.battery_0_bar_outlined),
            ],
          ),
          if (totalOutstanding > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  const Text('Total Outstanding Today',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '₹${totalOutstanding.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 40,
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Salesman Card
// ─────────────────────────────────────────────────────────────────────────────
class _SalesmanCard extends StatelessWidget {
  final Salesman salesman;
  final ReportEntity? report;
  final bool isReportsLoading;
  final String agencyId;
  final List<Salesman> allSalesmen;
  final Agency? agency;
  final void Function(Salesman) onEdit;
  final VoidCallback onStockTap;
  final VoidCallback onResetDevice;

  const _SalesmanCard({
    required this.salesman,
    required this.report,
    required this.isReportsLoading,
    required this.agencyId,
    required this.allSalesmen,
    required this.agency,
    required this.onEdit,
    required this.onStockTap,
    required this.onResetDevice,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked =
        salesman.deviceId != null && salesman.deviceId!.isNotEmpty;
    final isSettled = report?.isSettled ?? false;

    final double cashInHand = report?.cashInHand ?? 0;
    final double prevBalance = report?.salesmanPreviousBalance ?? 0;
    final double settledToday = report?.settlementAmountToday ?? 0;
    final double outstanding =
        (cashInHand + prevBalance - settledToday).clamp(0.0, double.infinity);

    final initials = salesman.name.isNotEmpty
        ? salesman.name
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join()
        : '?';

    // Avatar gradient colours cycle through palette
    final avatarColors = [
      [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      [const Color(0xFF00695C), const Color(0xFF4CAF50)],
      [const Color(0xFFE65100), const Color(0xFFFFB74D)],
      [const Color(0xFF6A1B9A), const Color(0xFFBA68C8)],
      [const Color(0xFF37474F), const Color(0xFF78909C)],
    ];
    final colorPair = avatarColors[
        salesman.name.codeUnitAt(0) % avatarColors.length];

    return GestureDetector(
      onTap: () async {
        final updated = await showDialog<Salesman>(
          context: context,
          builder: (_) => EditSalesmanDialog(
            salesman: salesman,
            maxAgencyCustomers: agency?.maxCustomers ?? 0,
            existingSalesmen: allSalesmen,
          ),
        );
        if (updated != null) onEdit(updated);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top strip ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: colorPair,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name / phone / status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                salesman.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSettled)
                              const _Badge(
                                  label: 'Settled',
                                  color: _kGreen),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          salesman.phoneNumber.isNotEmpty
                              ? salesman.phoneNumber
                              : 'No phone',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Device status
                            _SmallChip(
                              icon: isLinked
                                  ? Icons.phonelink_lock
                                  : Icons.phonelink_off,
                              label: isLinked ? 'Linked' : 'Unlinked',
                              color: isLinked ? _kGreen : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            // Customers
                            if (salesman.customerCount > 0)
                              _SmallChip(
                                icon: Icons.people_outline,
                                label: '${salesman.customerCount} cust.',
                                color: _kBlue,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Action buttons column
                  Column(
                    children: [
                      _CircleAction(
                        icon: Icons.inventory_2_outlined,
                        color: _kBlue,
                        tooltip: 'Stock',
                        onTap: onStockTap,
                      ),
                      if (isLinked) ...[
                        const SizedBox(height: 6),
                        _CircleAction(
                          icon: Icons.lock_reset,
                          color: _kOrange,
                          tooltip: 'Reset Device',
                          onTap: onResetDevice,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Stock strip ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _StockStat(
                    label: 'Full Stock',
                    value: '${salesman.currentStock}',
                    icon: Icons.local_drink_outlined,
                    color: _kBlue,
                  ),
                  _VertDivider(),
                  _StockStat(
                    label: 'Empties',
                    value: '${salesman.emptyBottles}',
                    icon: Icons.battery_0_bar_outlined,
                    color: Colors.grey,
                  ),
                  _VertDivider(),
                  _StockStat(
                    label: 'Customers',
                    value: '${salesman.customerCount}',
                    icon: Icons.people_outline,
                    color: _kGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Report data ────────────────────────────────────────────────
            if (isReportsLoading && report == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (report != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, thickness: 0.8),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _ReportStat(
                        label: 'Cash Today',
                        value:
                            '₹${cashInHand.toStringAsFixed(0)}',
                        color: _kGreen),
                    _ReportStat(
                        label: 'Collected',
                        value:
                            '−₹${settledToday.toStringAsFixed(0)}',
                        color: Colors.blueGrey),
                    _ReportStat(
                        label: 'Outstanding',
                        value: '₹${outstanding.toStringAsFixed(0)}',
                        color: outstanding > 0 ? _kRed : Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Settle button
              if (outstanding > 0 || prevBalance > 0 || report!.upiCollections > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: isSettled
                          ? null
                          : () => _showSettlementDialog(
                              context, report!, agencyId),
                      icon: Icon(
                        isSettled
                            ? Icons.check_circle_outline
                            : Icons.payments_outlined,
                        size: 18,
                      ),
                      label: Text(
                        isSettled ? 'Settled' : 'Receive Payment',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSettled
                            ? Colors.grey.shade200
                            : _kBlue,
                        foregroundColor: isSettled
                            ? Colors.grey.shade500
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ] else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSettlementDialog(
      BuildContext context, ReportEntity subReport, String agencyId) {
    if (subReport.salesmanId == null) return;

    final double totalOutstanding = subReport.cashInHand +
        subReport.salesmanPreviousBalance -
        subReport.settlementAmountToday;

    final amtCtrl = TextEditingController(
        text: totalOutstanding > 0
            ? totalOutstanding.toStringAsFixed(0)
            : '');
    bool isFinal = true;
    final reportsBloc = context.read<ReportsBloc>();

    showDialog(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: reportsBloc,
        child: StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.payments_outlined, color: _kBlue),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Collect — ${subReport.salesmanName}',
                        style: const TextStyle(fontSize: 15))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SettlementRow('Cash Today',
                      '₹${subReport.cashInHand.toStringAsFixed(0)}'),
                  if (subReport.settlementAmountToday > 0)
                    _SettlementRow(
                        'Already Paid',
                        '−₹${subReport.settlementAmountToday.toStringAsFixed(0)}',
                        valueColor: _kGreen),
                  _SettlementRow(
                    'Old Balance',
                    '₹${subReport.salesmanPreviousBalance.toStringAsFixed(0)}',
                    valueColor: subReport.salesmanPreviousBalance > 0
                        ? _kRed
                        : _kGreen,
                  ),
                  const Divider(height: 24),
                  _SettlementRow(
                      'Total Outstanding',
                      '₹${totalOutstanding.toStringAsFixed(0)}',
                      bold: true),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount Received Now (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      errorText: ((double.tryParse(amtCtrl.text) ?? 0) >
                              totalOutstanding)
                          ? 'Cannot exceed outstanding'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if ((double.tryParse(amtCtrl.text) ?? 0) >=
                      totalOutstanding)
                    CheckboxListTile(
                      title: const Text('Mark as Final Settlement',
                          style: TextStyle(fontSize: 13)),
                      value: isFinal,
                      onChanged: (v) =>
                          setState(() => isFinal = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _kBlue,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ((double.tryParse(amtCtrl.text) ?? 0) >=
                              totalOutstanding) &&
                          isFinal
                      ? _kBlue
                      : _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed:
                    ((double.tryParse(amtCtrl.text) ?? 0) > totalOutstanding)
                        ? null
                        : () {
                            final amt =
                                double.tryParse(amtCtrl.text);
                            if (amt != null && amt >= 0) {
                              final finalSettlement =
                                  (amt >= totalOutstanding)
                                      ? isFinal
                                      : false;
                              context.read<ReportsBloc>().add(
                                    SettleSalesmanDailyCash(
                                      salesmanId: subReport.salesmanId!,
                                      date: DateTime.now(),
                                      amount: amt,
                                      recordedBy: agencyId,
                                      isFinal: finalSettlement,
                                    ),
                                  );
                              Navigator.pop(dialogCtx);
                            }
                          },
                child: Text(
                  ((double.tryParse(amtCtrl.text) ?? 0) >=
                              totalOutstanding) &&
                          isFinal
                      ? 'Confirm Final Settlement'
                      : 'Record Partial Payment',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SmallChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleAction(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StockStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: Colors.grey.shade200);
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReportStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _SettlementRow(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.black87,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock tab helper widget
// ─────────────────────────────────────────────────────────────────────────────
class _StockTabContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String infoText;
  final String label;
  final String fieldLabel;
  final IconData fieldIcon;
  final Color fieldColor;
  final TextEditingController controller;

  const _StockTabContent({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.infoText,
    required this.label,
    required this.fieldLabel,
    required this.fieldIcon,
    required this.fieldColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(infoText,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: iconColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: fieldLabel,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            prefixIcon: Icon(fieldIcon, color: fieldColor),
          ),
        ),
      ],
    );
  }
}
