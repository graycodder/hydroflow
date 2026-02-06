import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  static Future<void> sendReceipt({
    required String phone,
    required String customerName,
    required int delivered,
    required int returned,
    required int bottleBalance, // Kept for context, even if not in PDF
    required double amount,
    required double amountReceived,
    required bool isPaid,
    required double oldBalance,
    required double newBalance,
    required String paymentMode,
    required DateTime date,
  }) async {
    // Sanitize phone number (remove +, spaces, dashes)
    String sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Default to India (91) if country code missing/short
    if (sanitizedPhone.length == 10) {
      sanitizedPhone = '91$sanitizedPhone';
    }

    final String status = isPaid ? "PAID" : "PARTIAL/CREDIT";
    // Format date similar to PDF
    final String dateStr = "${date.day}/${date.month}/${date.year}"; 
    
    final String paymentDetails = amountReceived >= amount
         ? "💰 *Total Bill:* ₹${amount.toInt()}\n✅ *Amount Paid:* ₹${amountReceived.toInt()}"
         : "💰 *Total Bill:* ₹${amount.toInt()}\n💵 *Amount Paid:* ₹${amountReceived.toInt()}\n⚠️ *Current Due:* ₹${(amount - amountReceived).toInt()}";

    final String message = '''
🧾 *HydroFlow Pro - Digital Receipt*
📅 Date: $dateStr

👤 *Customer:* $customerName

--- 📦 *Bottle Exchange* ---
🔹 Delivered: $delivered cans
🔹 Returned: $returned cans
🔹 Bottle Balance: $bottleBalance

--- 💳 *Payment Details* ---
$paymentDetails
Payment Mode: $paymentMode

--- 📒 *Account Summary* ---
Prev Balance: ₹${oldBalance.toInt()}
*Total Pending:* ₹${newBalance.toInt()}

✅ Status: $status

Thank you for choosing HydroFlow Pro!
''';

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$sanitizedPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some devices where universal link might not be "launchable" but the app is there
        final Uri directUrl = Uri.parse(
          'whatsapp://send?phone=$sanitizedPhone&text=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(directUrl)) {
          await launchUrl(directUrl);
        } else {
          // If still fails, try to just launch the https one anyway as a last resort
          await launchUrl(whatsappUrl, mode: LaunchMode.externalNonBrowserApplication);
        }
      }
    } catch (e) {
      // Log error internally if needed
      throw 'Could not launch WhatsApp. Please check if it is installed.';
    }
  }
}
