import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'auth_view.dart';
import 'home_view.dart';

class SplashScreen extends StatelessWidget {
  final AuthController _authController = Get.put(AuthController());

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate some startup delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_authController.isLoggedIn) {
        Get.off(() => HomeView());
      } else {
        Get.off(() => AuthView());
      }
    });

    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games_outlined, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'ChessMaster',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
