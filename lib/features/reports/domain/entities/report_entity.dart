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
  final int closingStock;
  final int stockMismatch; // Expected - Actual (if physical count input exists, else 0 or calculated)
  
  // Bottle Reconciliation
  final int bottlesDelivered;
  final int bottlesReturned;
  final int netBottlesOut;
  final int totalBottlesWithCustomers; // All-time outstanding
  
  // Financial Summary
  final double salesRevenue;
  final double cashSales;
  final double onlineSales;
  
  final double securityDepositsCollected;
  final double securityDepositsRefunded;
  final double netDeposits;
  
  final double cashInHand; // Cash Sales + Deposits - Refunds
  final double upiCollections;
  
  // Performance
  final double avgPricePerCan;
  final double stockTurnover; // Percentage

  const ReportEntity({
    required this.date,
    required this.totalRevenue,
    required this.totalDeliveries,
    required this.openingStock,
    required this.stockLoaded,
    required this.totalAvailable,
    required this.deliveredStock,
    required this.damagedStock,
    required this.closingStock,
    this.stockMismatch = 0,
    required this.bottlesDelivered,
    required this.bottlesReturned,
    required this.netBottlesOut,
    required this.totalBottlesWithCustomers,
    required this.salesRevenue,
    required this.cashSales,
    required this.onlineSales,
    required this.securityDepositsCollected,
    required this.securityDepositsRefunded,
    required this.netDeposits,
    required this.cashInHand,
    required this.upiCollections,
    required this.avgPricePerCan,
    required this.stockTurnover,
  });

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
        closingStock,
        stockMismatch,
        bottlesDelivered,
        bottlesReturned,
        netBottlesOut,
        totalBottlesWithCustomers,
        salesRevenue,
        cashSales,
        onlineSales,
        securityDepositsCollected,
        securityDepositsRefunded,
        netDeposits,
        cashInHand,
        upiCollections,
        avgPricePerCan,
        stockTurnover,
      ];
}
