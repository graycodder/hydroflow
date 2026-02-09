import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/core/service_locator.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:hydroflow/core/widgets/app_bottom_bar.dart';
import 'package:hydroflow/core/widgets/hydro_flow_app_bar.dart';
import '../widgets/daily_report_view.dart';
import '../widgets/monthly_report_view.dart';

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
    String salesmanId = '';
    if (authState is AuthAuthenticated) {
      salesmanId = authState.salesman.id;
    }

    return BlocProvider(
      create: (context) => sl<ReportsBloc>()..add(LoadDailyReport(salesmanId, selectedDate)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const HydroFlowAppBar(),
            body: Column(
              children: [
                _buildTopTabs(context, salesmanId),
                Expanded(
                  child: BlocBuilder<ReportsBloc, ReportsState>(
                    builder: (context, state) {
                      if (state is ReportsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ReportsFailure) {
                        return Center(child: Text('Error: ${state.message}'));
                      } else if (state is ReportsLoaded) {
                        final now = DateTime.now();
                        final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
                        
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: isMonthly 
                            ? MonthlyReportView(
                                report: state.report,
                                salesmanId: salesmanId,
                                selectedMonth: selectedMonth,
                                isCurrentMonth: isCurrentMonth,
                                onLeftChevronPressed: () {
                                  setState(() {
                                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                                  });
                                  context.read<ReportsBloc>().add(LoadMonthlyReport(salesmanId, selectedMonth));
                                },
                                onRightChevronPressed: () {
                                  setState(() {
                                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                                  });
                                  context.read<ReportsBloc>().add(LoadMonthlyReport(salesmanId, selectedMonth));
                                },
                                onExportPressed: () {},
                                onSharePressed: () {},
                              )
                            : DailyReportView(
                                report: state.report,
                                salesmanId: salesmanId,
                                selectedDate: selectedDate,
                                isCurrentDate: selectedDate.year == now.year && 
                                               selectedDate.month == now.month && 
                                               selectedDate.day == now.day,
                                onSharedPressed: () {},
                                onSelectDatePressed: () => _showPicker(context, salesmanId),
                                onLeftChevronPressed: () {
                                  setState(() {
                                    selectedDate = selectedDate.subtract(const Duration(days: 1));
                                  });
                                  context.read<ReportsBloc>().add(LoadDailyReport(salesmanId, selectedDate));
                                },
                                onRightChevronPressed: () {
                                  setState(() {
                                    selectedDate = selectedDate.add(const Duration(days: 1));
                                  });
                                  context.read<ReportsBloc>().add(LoadDailyReport(salesmanId, selectedDate));
                                },
                              ),
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

  Widget _buildTopTabs(BuildContext context, String salesmanId) {
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
                context.read<ReportsBloc>().add(LoadDailyReport(salesmanId, selectedDate));
              },
            ),
          ),
          Expanded(
            child: _buildTab(
              title: "Monthly Report",
              isSelected: isMonthly,
              onTap: () {
                setState(() => isMonthly = true);
                context.read<ReportsBloc>().add(LoadMonthlyReport(salesmanId, selectedMonth));
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

  Future<void> _showPicker(BuildContext context, String salesmanId) async {
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
        context.read<ReportsBloc>().add(LoadMonthlyReport(salesmanId, selectedMonth));
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
        context.read<ReportsBloc>().add(LoadDailyReport(salesmanId, selectedDate));
      }
    }
  }
}
