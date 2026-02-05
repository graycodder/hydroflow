import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptPdfGenerator {
  static Future<void> generateAndShare({
    required String customerName,
    required String phone,
    required String address,
    required int delivered,
    required int emptyCollected,
    required double paymentAmount,
    required double amountReceived,
    required String paymentMode,
    required double oldBalance,
    required double newBalance,
    required DateTime date,
  }) async {
    final doc = pw.Document();
    
    // Load fonts for Unicode support (Rupee symbol etc)
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Theme(
            data: pw.ThemeData.withFont(
              base: font,
              bold: fontBold,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
              pw.Center(
                child: pw.Text("HydroFlow Pro", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.Center(child: pw.Text("Water Delivery Service")),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Text("Date: ${dateFormat.format(date)}", style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              
              pw.Text("Customer Details:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(customerName, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              _buildRow("Delivered Cans", "$delivered", isBold: true),
              _buildRow("Empty Collected", "$emptyCollected"),
              
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              _buildRow("Total Bill", "Rs. ${paymentAmount.toInt()}", isBold: false),
              _buildRow("Amount Paid", "Rs. ${amountReceived.toInt()}", isBold: true),
              if (paymentAmount > amountReceived)
                 _buildRow("Current Due", "Rs. ${(paymentAmount - amountReceived).toInt()}"),

              _buildRow("Payment Mode", paymentMode),
              
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              
              _buildRow("Prev Balance", "Rs. ${oldBalance.toInt()}"),
              _buildRow("Total Pending", "Rs. ${newBalance.toInt()}", isBold: true),
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Thank You!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text("Powered by GrayCodder", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))),
            ],
          )); // Close Column and Theme
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
      ],
    );
  }
}
