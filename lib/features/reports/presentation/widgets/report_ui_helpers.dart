import 'package:flutter/material.dart';

Widget buildCard({
  required String title,
  required IconData icon,
  required String subtitle,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

Widget buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            maxLines: 1,
          overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

Widget buildSubRow(String label, String value, {Color? color}) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("• $label", style: const TextStyle(color: Colors.black, fontSize: 14)),
        Text(
          value,
          style: TextStyle(color: color ?? Colors.black87, fontSize: 14),
        ),
      ],
    ),
  );
}

Widget buildStatBox(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == "Delivered" ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(label, 
            style: const TextStyle(color: Colors.grey,fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,maxLines: 1,
              overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}



Widget buildLargeSummaryCard({
  required String title,
  required String value,
  required String subtitle,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, 
        maxLines: 1,
          overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
         value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    ),
  );
}

Widget buildChevronButton({required IconData icon, required VoidCallback? onTap}) {
  final isDisabled = onTap == null;
  return Container(
    decoration: BoxDecoration(
      color: isDisabled ? Colors.grey[100] : Colors.white,
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: isDisabled ? Colors.grey : Colors.black87),
      visualDensity: VisualDensity.compact,
    ),
  );
}
