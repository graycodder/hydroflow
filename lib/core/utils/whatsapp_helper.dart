import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  static Future<void> sendReceipt({
    required String phone,
    required String customerName,
    required int delivered,
    required int returned,
    required int bottleBalance,
    required double amount,
    required double amountReceived,
    required bool isPaid,
  }) async {
    // Sanitize phone number (remove +, spaces, dashes)
    String sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Default to India (91) if country code missing/short
    if (sanitizedPhone.length == 10) {
      sanitizedPhone = '91$sanitizedPhone';
    }

    final String status = isPaid ? "PAID" : "PARTIAL/CREDIT";
    
    final String paymentDetails = amountReceived >= amount
        ? "💰 *Total: ₹${amount.toStringAsFixed(0)}*"
        : "💰 *Total: ₹${amount.toStringAsFixed(0)}*\n💵 *Paid: ₹${amountReceived.toStringAsFixed(0)}*\n⚠️ *Due: ₹${(amount - amountReceived).toStringAsFixed(0)}*";

    final String message = '''
🧾 *HydroFlow Pro Receipt*
To: $customerName

🔹 Delivered: $delivered cans
🔹 Returned: $returned cans
🔹 Bottle Balance: $bottleBalance

$paymentDetails
✅ Status: $status

Thank you for your business!
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
