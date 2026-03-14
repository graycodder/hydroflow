import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final DateTime date;
  
  // Summary
  final double totalRevenue;
  final int totalDeliveries;
  
  // Stock Reconciliation
  final int openingStock;
  final int stockLoaded;
  final int totalAvailable;
  final int deliveredStock;
  final int damagedStock;
  final int salesmanDamagedStock; // Separated to preserve warehouse reconciliation math
  final int closingStock;
  final int stockMismatch; // Expected - Actual (if physical count input exists, else 0 or calculated)
  
  // Bottle Reconciliation
  final int bottlesDelivered;
  final int bottlesReturned;
  final int netBottlesOut;
  final int totalBottlesWithCustomers; // All-time outstanding
  final int manualBottlesCollected; 
  
  // Financial Summary
  final double salesRevenue; // Total Bill Value
  final double totalCollected; // Actual Cash/UPI Received
  final double totalCreditPending; // Bill - Received
  
  final double cashSales; // Actual Cash Received
  final double onlineSales; // Actual Online Received
  
  final double securityDepositsCollected;
  final double securityDepositsCollectedCash;
  final double securityDepositsCollectedOnline;
  
  final double securityDepositsRefunded;
  final double securityDepositsRefundedCash;
  final double securityDepositsRefundedOnline;
  
  final double netDeposits;
  final double totalDepositsHeld;
  
  final double cashInHand; // Cash Sales + Deposits - Refunds
  final double upiCollections;
  
  // Performance
  final double avgPricePerCan;
  final double stockTurnover; // Percentage
  
  final int workingDays;
  final double avgDailyRevenue;
  final double avgDailyDeliveries;
  
  // Customer Stats (Monthly)
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomers;
  final int inactiveCustomers;

  // Salesman Info (for breakdown)
  final String? salesmanId;
  final String? salesmanName;
  final List<ReportEntity> subReports;
  
  // Settlement Info
  final bool isSettled;
  final double settlementAmountToday;
  final double salesmanPreviousBalance;
  /// Live accumulated cash balance from the Salesman node.
  final double pendingCashBalance;

  const ReportEntity({
    required this.date,
    required this.totalRevenue,
    required this.totalDeliveries,
    required this.openingStock,
    required this.stockLoaded,
    required this.totalAvailable,
    required this.deliveredStock,
    required this.damagedStock,
    this.salesmanDamagedStock = 0,
    required this.closingStock,
    this.stockMismatch = 0,
    required this.bottlesDelivered,
    required this.bottlesReturned,
    required this.netBottlesOut,
    required this.totalBottlesWithCustomers,
    this.manualBottlesCollected = 0,
    required this.salesRevenue,
    required this.totalCollected,
    required this.totalCreditPending,
    required this.cashSales,
    required this.onlineSales,
    required this.securityDepositsCollected,
    this.securityDepositsCollectedCash = 0.0,
    this.securityDepositsCollectedOnline = 0.0,
    required this.securityDepositsRefunded,
    this.securityDepositsRefundedCash = 0.0,
    this.securityDepositsRefundedOnline = 0.0,
    required this.netDeposits,
    required this.totalDepositsHeld,
    required this.cashInHand,
    required this.upiCollections,
    required this.avgPricePerCan,
    required this.stockTurnover,
    this.workingDays = 0,
    this.avgDailyRevenue = 0.0,
    this.avgDailyDeliveries = 0.0,
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.newCustomers = 0,
    this.inactiveCustomers = 0,
    this.salesmanId,
    this.salesmanName,
    this.subReports = const [],
    this.isSettled = false,
    this.settlementAmountToday = 0.0,
    this.salesmanPreviousBalance = 0.0,
    this.pendingCashBalance = 0.0,
  });

  ReportEntity copyWith({
    DateTime? date,
    double? totalRevenue,
    int? totalDeliveries,
    int? openingStock,
    int? stockLoaded,
    int? totalAvailable,
    int? deliveredStock,
    int? damagedStock,
    int? salesmanDamagedStock,
    int? closingStock,
    int? stockMismatch,
    int? bottlesDelivered,
    int? bottlesReturned,
    int? netBottlesOut,
    int? totalBottlesWithCustomers,
    int? manualBottlesCollected,
    double? salesRevenue,
    double? totalCollected,
    double? totalCreditPending,
    double? cashSales,
    double? onlineSales,
    double? securityDepositsCollected,
    double? securityDepositsCollectedCash,
    double? securityDepositsCollectedOnline,
    double? securityDepositsRefunded,
    double? securityDepositsRefundedCash,
    double? securityDepositsRefundedOnline,
    double? netDeposits,
    double? totalDepositsHeld,
    double? cashInHand,
    double? upiCollections,
    double? avgPricePerCan,
    double? stockTurnover,
    int? workingDays,
    double? avgDailyRevenue,
    double? avgDailyDeliveries,
    int? totalCustomers,
    int? activeCustomers,
    int? newCustomers,
    int? inactiveCustomers,
    String? salesmanId,
    String? salesmanName,
    List<ReportEntity>? subReports,
    bool? isSettled,
    double? settlementAmountToday,
    double? salesmanPreviousBalance,
    double? pendingCashBalance,
  }) {
    return ReportEntity(
      date: date ?? this.date,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      openingStock: openingStock ?? this.openingStock,
      stockLoaded: stockLoaded ?? this.stockLoaded,
      totalAvailable: totalAvailable ?? this.totalAvailable,
      deliveredStock: deliveredStock ?? this.deliveredStock,
      damagedStock: damagedStock ?? this.damagedStock,
      salesmanDamagedStock: salesmanDamagedStock ?? this.salesmanDamagedStock,
      closingStock: closingStock ?? this.closingStock,
      stockMismatch: stockMismatch ?? this.stockMismatch,
      bottlesDelivered: bottlesDelivered ?? this.bottlesDelivered,
      bottlesReturned: bottlesReturned ?? this.bottlesReturned,
      netBottlesOut: netBottlesOut ?? this.netBottlesOut,
      totalBottlesWithCustomers: totalBottlesWithCustomers ?? this.totalBottlesWithCustomers,
      manualBottlesCollected: manualBottlesCollected ?? this.manualBottlesCollected,
      salesRevenue: salesRevenue ?? this.salesRevenue,
      totalCollected: totalCollected ?? this.totalCollected,
      totalCreditPending: totalCreditPending ?? this.totalCreditPending,
      cashSales: cashSales ?? this.cashSales,
      onlineSales: onlineSales ?? this.onlineSales,
      securityDepositsCollected: securityDepositsCollected ?? this.securityDepositsCollected,
      securityDepositsCollectedCash: securityDepositsCollectedCash ?? this.securityDepositsCollectedCash,
      securityDepositsCollectedOnline: securityDepositsCollectedOnline ?? this.securityDepositsCollectedOnline,
      securityDepositsRefunded: securityDepositsRefunded ?? this.securityDepositsRefunded,
      securityDepositsRefundedCash: securityDepositsRefundedCash ?? this.securityDepositsRefundedCash,
      securityDepositsRefundedOnline: securityDepositsRefundedOnline ?? this.securityDepositsRefundedOnline,
      netDeposits: netDeposits ?? this.netDeposits,
      totalDepositsHeld: totalDepositsHeld ?? this.totalDepositsHeld,
      cashInHand: cashInHand ?? this.cashInHand,
      upiCollections: upiCollections ?? this.upiCollections,
      avgPricePerCan: avgPricePerCan ?? this.avgPricePerCan,
      stockTurnover: stockTurnover ?? this.stockTurnover,
      workingDays: workingDays ?? this.workingDays,
      avgDailyRevenue: avgDailyRevenue ?? this.avgDailyRevenue,
      avgDailyDeliveries: avgDailyDeliveries ?? this.avgDailyDeliveries,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      newCustomers: newCustomers ?? this.newCustomers,
      inactiveCustomers: inactiveCustomers ?? this.inactiveCustomers,
      salesmanId: salesmanId ?? this.salesmanId,
      salesmanName: salesmanName ?? this.salesmanName,
      subReports: subReports ?? this.subReports,
      isSettled: isSettled ?? this.isSettled,
      settlementAmountToday: settlementAmountToday ?? this.settlementAmountToday,
      salesmanPreviousBalance: salesmanPreviousBalance ?? this.salesmanPreviousBalance,
      pendingCashBalance: pendingCashBalance ?? this.pendingCashBalance,
    );
  }

  @override
  List<Object?> get props => [
        date,
        totalRevenue,
        totalDeliveries,
        openingStock,
        stockLoaded,
        totalAvailable,
        deliveredStock,
        damagedStock,
        salesmanDamagedStock,
        closingStock,
        stockMismatch,
        bottlesDelivered,
        bottlesReturned,
        netBottlesOut,
        totalBottlesWithCustomers,
        manualBottlesCollected,
        salesRevenue,
        totalCollected,
        totalCreditPending,
        cashSales,
        onlineSales,
        securityDepositsCollected,
        securityDepositsCollectedCash,
        securityDepositsCollectedOnline,
        securityDepositsRefunded,
        securityDepositsRefundedCash,
        securityDepositsRefundedOnline,
        netDeposits,
        totalDepositsHeld,
        cashInHand,
        upiCollections,
        avgPricePerCan,
        stockTurnover,
        workingDays,
        avgDailyRevenue,
        avgDailyDeliveries,
        totalCustomers,
        activeCustomers,
        newCustomers,
        inactiveCustomers,
        salesmanId,
        salesmanName,
        subReports,
        isSettled,
        settlementAmountToday,
        salesmanPreviousBalance,
        pendingCashBalance,
      ];
}
