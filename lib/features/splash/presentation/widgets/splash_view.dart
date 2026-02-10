import 'package:flutter/material.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the same asset as native splash for a seamless look
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: 200, // Adjust width to match native splash scale roughly
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2962FF)),
            ),
          ],
        ),
      ),
    );
  }
}
