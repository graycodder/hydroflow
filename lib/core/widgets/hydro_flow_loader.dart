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

  static bool _isShowing = false;
  static Route? _currentRoute;
  
  /// Static helper to show the loader as a dialog
  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return;
    _isShowing = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Handled by BackdropFilter
      routeSettings: const RouteSettings(name: 'hydro_flow_loader'),
      builder: (dialogContext) {
        // Capture the route to allow reliable removal
        _currentRoute = ModalRoute.of(dialogContext);
        return HydroFlowLoader(message: message);
      },
    ).then((_) {
      _isShowing = false;
      _currentRoute = null;
    });
  }

  /// Static helper to hide the loader
  static void hide(BuildContext context) {
    try {
      if (!context.mounted) return;
      
      // Attempt immediate removal if we have the route
      if (_currentRoute != null && _currentRoute!.isActive) {
        Navigator.of(context, rootNavigator: true).removeRoute(_currentRoute!);
        _currentRoute = null;
        _isShowing = false;
      } else {
        // Fallback for race conditions: try to pop by name in the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          
          if (_currentRoute != null && _currentRoute!.isActive) {
            Navigator.of(context, rootNavigator: true).removeRoute(_currentRoute!);
            _currentRoute = null;
            _isShowing = false;
          } else {
            // Last resort: pop top if it's the loader
            Navigator.of(context, rootNavigator: true).popUntil((route) {
              return route.settings.name != 'hydro_flow_loader';
            });
            _isShowing = false;
          }
        });
      }
    } catch (e) {
      debugPrint('HydroFlowLoader.hide error: $e');
      _isShowing = false;
    }
  }
}
