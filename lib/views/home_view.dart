import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'auth_view.dart';
import 'leaderboard_view.dart';
import 'profile_view.dart';
import 'time_selection_view.dart';

class HomeView extends StatelessWidget {
  final AuthController _authController = Get.put(AuthController());

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChessMaster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authController.signOut();
              Get.offAll(() => AuthView());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Get.to(() => TimeSelectionView());
              },
              child: const Text('Play a Game'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => LeaderboardView());
              },
              child: const Text('View Leaderboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => ProfileView());
              },
              child: const Text('View Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
