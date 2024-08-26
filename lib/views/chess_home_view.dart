import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/game_controller.dart';
import 'painter.dart';

class ChessHomeScreen extends StatelessWidget {
  const ChessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController gameController = Get.find<GameController>();

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // Top section with user profile and level information
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.brown[400],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.brown),
                  ),
                  Column(
                    children: [
                      Obx(() => Text(
                            gameController.gameResult.value,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      // Obx(() => Text(
                      //       gameController.gameStatus.value,
                      //       style: const TextStyle(
                      //         fontSize: 16,
                      //         color: Colors.white,
                      //       ),
                      //     )),
                      Obx(() => Text(
                            gameController.gameTime.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          )),
                    ],
                  ),
                  const Icon(
                    Icons.settings,
                    color: Colors.red,
                    size: 30,
                  ),
                ],
              ),
            ),

            const Expanded(child: Painter()),

            // Display the result message if the game is over
            Obx(() {
              if (gameController.gameResult.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.black87,
                  child: Center(
                    child: Text(
                      gameController.gameResult.value,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink(); // Return empty space if no result
            }),
          ],
        ),
      ),
    );
  }

  Widget buildBottomButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.orange,
          size: 40,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
