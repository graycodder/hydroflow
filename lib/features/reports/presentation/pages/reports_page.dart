import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/daily_report_view.dart';
import '../widgets/monthly_report_view.dart';
import '../widgets/agency_daily_report_view.dart';
import '../widgets/agency_monthly_report_view.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool isMonthly = false;
  DateTime selectedDate = DateTime.now();
  DateTime selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String id = '';
    bool isAgencyView = false;
    
    if (authState is AuthAuthenticated) {
      final prefs = sl<SharedPreferences>();
      isAgencyView = (prefs.getBool('dashboard_is_agency_view') ?? false) && authState.salesman.role == 'owner';
      id = isAgencyView ? authState.salesman.agencyId : authState.salesman.id;
    }

    return BlocProvider(
      create: (context) {
        final bloc = sl<ReportsBloc>();
        if (isAgencyView) {
          bloc.add(LoadAgencyDailyReport(id, selectedDate));
        } else {
          bloc.add(LoadDailyReport(id, selectedDate));
        }
        return bloc;
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const HydroFlowAppBar(),
            body: Column(
              children: [
                if (isAgencyView)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text(
                        "Agency View - Consolidated Reports",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                _buildTopTabs(context, id, isAgencyView),
                Expanded(
                  child: BlocBuilder<ReportsBloc, ReportsState>(
                    builder: (context, state) {
                      if (state is ReportsLoading) {
                        return const HydroFlowLoader(isOverlay: false);
                      } else if (state is ReportsFailure) {
                        return Center(child: Text('Error: ${state.message}'));
                      } else if (state is ReportsLoaded) {
                        final now = DateTime.now();
                        final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
                        
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: isMonthly 
                            ? (isAgencyView 
                                ? AgencyMonthlyReportView(
                                    report: state.report,
                                    agencyId: id,
                                    selectedMonth: selectedMonth,
                                    isCurrentMonth: isCurrentMonth,
                                    onLeftChevronPressed: () {
                                      setState(() {
                                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                                      });
                                      context.read<ReportsBloc>().add(LoadAgencyMonthlyReport(id, selectedMonth));
                                    },
                                    onRightChevronPressed: () {
                                      setState(() {
                                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                                      });
                                      context.read<ReportsBloc>().add(LoadAgencyMonthlyReport(id, selectedMonth));
                                    },
                                    onExportPressed: () {},
                                    onSharePressed: () {},
                                  )
                                : MonthlyReportView(
                                    report: state.report,
                                    salesmanId: id,
                                    selectedMonth: selectedMonth,
                                    isCurrentMonth: isCurrentMonth,
                                    onLeftChevronPressed: () {
                                      setState(() {
                                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                                      });
                                      context.read<ReportsBloc>().add(LoadMonthlyReport(id, selectedMonth));
                                    },
                                    onRightChevronPressed: () {
                                      setState(() {
                                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                                      });
                                      context.read<ReportsBloc>().add(LoadMonthlyReport(id, selectedMonth));
                                    },
                                    onExportPressed: () {},
                                    onSharePressed: () {},
                                  ))
                            : (isAgencyView
                                ? AgencyDailyReportView(
                                    report: state.report,
                                    agencyId: id,
                                    selectedDate: selectedDate,
                                    isCurrentDate: selectedDate.year == now.year && 
                                                   selectedDate.month == now.month && 
                                                   selectedDate.day == now.day,
                                    onSharedPressed: () {},
                                    onSelectDatePressed: () => _showPicker(context, id, isAgencyView),
                                    onLeftChevronPressed: () {
                                      setState(() {
                                        selectedDate = selectedDate.subtract(const Duration(days: 1));
                                      });
                                      context.read<ReportsBloc>().add(LoadAgencyDailyReport(id, selectedDate));
                                    },
                                    onRightChevronPressed: () {
                                      setState(() {
                                        selectedDate = selectedDate.add(const Duration(days: 1));
                                      });
                                      context.read<ReportsBloc>().add(LoadAgencyDailyReport(id, selectedDate));
                                    },
                                  )
                                : DailyReportView(
                                    report: state.report,
                                    salesmanId: id,
                                    selectedDate: selectedDate,
                                    isCurrentDate: selectedDate.year == now.year && 
                                                   selectedDate.month == now.month && 
                                                   selectedDate.day == now.day,
                                    onSharedPressed: () {},
                                    onSelectDatePressed: () => _showPicker(context, id, isAgencyView),
                                    onLeftChevronPressed: () {
                                      setState(() {
                                        selectedDate = selectedDate.subtract(const Duration(days: 1));
                                      });
                                      context.read<ReportsBloc>().add(LoadDailyReport(id, selectedDate));
                                    },
                                    onRightChevronPressed: () {
                                      setState(() {
                                        selectedDate = selectedDate.add(const Duration(days: 1));
                                      });
                                      context.read<ReportsBloc>().add(LoadDailyReport(id, selectedDate));
                                    },
                                  )),
                        );
                      }
                      return const Center(child: Text("Initializing..."));
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const AppBottomBar(currentIndex: 5),
          );
        }
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context, String id, bool isAgencyView) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              title: "Daily Report",
              isSelected: !isMonthly,
              onTap: () {
                setState(() => isMonthly = false);
                final event = isAgencyView 
                    ? LoadAgencyDailyReport(id, selectedDate)
                    : LoadDailyReport(id, selectedDate);
                context.read<ReportsBloc>().add(event);
              },
            ),
          ),
          Expanded(
            child: _buildTab(
              title: "Monthly Report",
              isSelected: isMonthly,
              onTap: () {
                setState(() => isMonthly = true);
                final event = isAgencyView 
                    ? LoadAgencyMonthlyReport(id, selectedMonth)
                    : LoadMonthlyReport(id, selectedMonth);
                context.read<ReportsBloc>().add(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected 
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context, String id, bool isAgencyView) async {
    final now = DateTime.now();
    if (isMonthly) {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedMonth.isAfter(now) ? now : selectedMonth,
        firstDate: DateTime(2023),
        lastDate: now,
        initialDatePickerMode: DatePickerMode.year,
      );
      if (picked != null) {
        setState(() {
          selectedMonth = DateTime(picked.year, picked.month);
        });
        final event = isAgencyView 
            ? LoadAgencyMonthlyReport(id, selectedMonth)
            : LoadMonthlyReport(id, selectedMonth);
        context.read<ReportsBloc>().add(event);
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.isAfter(now) ? now : selectedDate,
        firstDate: DateTime(2023),
        lastDate: now,
      );
      if (picked != null) {
        setState(() {
          selectedDate = picked;
        });
        final event = isAgencyView 
            ? LoadAgencyDailyReport(id, selectedDate)
            : LoadDailyReport(id, selectedDate);
        context.read<ReportsBloc>().add(event);
      }
    }
  }
}
