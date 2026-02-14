import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappHelper {
  static Future<void> sendReceipt({
    required String phone,
    required String customerName,
    required String address,
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

    // Format date: 26 Feb 2026, 12:30 PM
    final String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    final String message = '''
*HydroFlow*
Water Delivery Service
-------------------------------------------
*Date:* $dateStr

*Customer Details:*
$customerName
$phone
$address

-------------------------------------------
*Delivered Cans:* $delivered
*Empty Collected:* $returned

-------------------------------------------
*Total Bill:* ₹${amount.toInt()}
*Amount Paid:* ₹${amountReceived.toInt()}
${amount > amountReceived ? '*Current Due:* ₹${(amount - amountReceived).toInt()}\n' : ''}*Payment Mode:* $paymentMode

-------------------------------------------
*Prev Balance:* ₹${oldBalance.toInt()}
*Total Pending:* ₹${newBalance.toInt()}

*Thank You for Choosing HydroFlow!*
_Powered by GrayCodder_
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
