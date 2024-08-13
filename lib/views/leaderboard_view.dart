import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/leaderboard_controller.dart';

class LeaderboardView extends StatelessWidget {
  final LeaderboardController _leaderboardController =
      Get.put(LeaderboardController());

  LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
      ),
      body: Obx(() {
        return ListView.builder(
          itemCount: _leaderboardController.leaderboard.length,
          itemBuilder: (context, index) {
            var player = _leaderboardController.leaderboard[index];
            return ListTile(
              title: Text(player['displayName']),
              subtitle:
                  Text("Wins: ${player['wins']} | Losses: ${player['losses']}"),
            );
          },
        );
      }),
    );
  }
}
