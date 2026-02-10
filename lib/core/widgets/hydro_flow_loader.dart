import 'dart:ui';
import 'package:flutter/material.dart';

class HydroFlowLoader extends StatelessWidget {
  final String? message;
  final bool isOverlay;

  const HydroFlowLoader({
    super.key,
    this.message,
    this.isOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final loader = Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

    if (!isOverlay) return loader;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: loader,
      ),
    );
  }

  /// Static helper to show the loader as a dialog
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Handled by BackdropFilter
      builder: (context) => HydroFlowLoader(message: message),
    );
  }

  /// Static helper to hide the loader
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
