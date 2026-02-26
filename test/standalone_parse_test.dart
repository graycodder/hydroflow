void main() {
  final Map<String, dynamic> data = {
    "subscription": {
      "lastNotification": "2026-02-26T14:54:25.305230",
      "subEndDate": "2026-03-28T14:54:24.972047",
      "subId": "-OmOFsJB78pA5prQwdXB",
      "subStartDate": "2026-02-26T14:54:24.972047"
    },
    // Adding legacy format too for complete test coverage
    "subscriptionExpiry": "2024-03-28T14:54:24.972047", 
  };

  Map<String, dynamic>? activeSub;
  final subData = data['subscription'];
  
  if (subData is Map) {
    if (subData.containsKey('maxCustomers')) {
      activeSub = Map<String, dynamic>.from(subData);
    } else if (subData.containsKey('0') && subData['0'] is Map) {
      activeSub = Map<String, dynamic>.from(subData['0'] as Map);
    } else if (subData.isNotEmpty) {
      final firstValue = subData.values.first;
      if (firstValue is Map) {
          activeSub = Map<String, dynamic>.from(firstValue);
      }
    }
  } else if (subData is List && subData.isNotEmpty && subData.first is Map) {
      activeSub = Map<String, dynamic>.from(subData.first as Map);
  }

  // --- FAILING LOGIC HERE ----
  print('Parsed activeSub: $activeSub');
  
  // Here is the fix:
  if (activeSub == null && subData is Map) {
     activeSub = Map<String, dynamic>.from(subData);
  }
  
  final subExpiryStr = activeSub?['subEndDate']?.toString() ?? activeSub?['expiryDate']?.toString();
  
  final subExpiry = subExpiryStr != null
        ? DateTime.tryParse(subExpiryStr)
        : (data['subscriptionExpiry'] != null
            ? DateTime.tryParse(data['subscriptionExpiry'].toString())
            : null);
            
  print('Resulting subExpiry: $subExpiry');
}
