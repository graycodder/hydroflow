import 'package:intl/intl.dart';
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

    // Format date: Feb 26, 2026
    final String dateStr = DateFormat('MMM dd, yyyy').format(date);

    final String message = '''
💧 *Water Delivery* ☑️
💧 *Bill Details* 📦

*To:* $customerName
*Date:* $dateStr
*Order:*
  $delivered x 20L Water Can
  $returned x 20L Empty Can (Returned)

*Charges:*
Water Cost: ₹${amount.toInt()}
Subtotal: ₹${amount.toInt()}
*Amount Paid:* $paymentMode
Scan & Pay: UPI ₹${amount.toInt()}

*Notes:*
* Enjoy your clean water!
Thank you for your order!

*Total Due:* ₹${newBalance.toInt()} ${newBalance <= 0 ? '✅' : ''}
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
