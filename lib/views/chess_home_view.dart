import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../helper/imagetext_painter.dart';
import 'painter.dart';
import '../helper/painter_helper.dart';

class ChessHomeScreen extends StatelessWidget {
  final PainterHelper painterHelper = PainterHelper.instance;

  ChessHomeScreen({super.key});
  String assetPath = "assets/images/";

  @override
  Widget build(BuildContext context) {
    final GameController gameController = Get.find<GameController>();

    return SafeArea(
      child: Scaffold(
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Obx(() {
                        return Text(
                          gameController.gameResult.value,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
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
            SizedBox(
              height: 15,
            ),
            Obx(() {
              if (gameController.imageText.value != null) {
                return CustomPaint(
                  size:
                      const Size(100, 30), // Set a suitable size for the image
                  painter: ImageTextPainter(gameController.imageText.value),
                );
              } else {
                return Text(
                  gameController.gameResult.value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            }),

            SizedBox(
              height: 50,
            ),

            // Flexible widget to allow the chessboard to resize based on available space
            const Expanded(
              child: Painter(),
            ),

            Text("Checking Here"),

            // Bottom buttons (Restart, Pieces, Undo, Hint)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.brown[700],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // buildBottomButton(Icons.refresh, 'RESTART'),
                  // buildBottomButton(Icons.house_siding, 'PIECES'),
                  // buildBottomButton(Icons.undo, 'UNDO'),
                  // buildBottomButton(Icons.lightbulb_outline, 'HINT'),
                  gameBottomButton("${assetPath}newgame.png", 0),
                  gameBottomButton("${assetPath}takeback.png", 1),
                  gameBottomButton("${assetPath}owl.png", 2),
                  gameBottomButton("${assetPath}fruit.png", 3),
                  gameBottomButton("${assetPath}lousy.png", 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gameBottomButton(String imgPath, int index) {
    return GestureDetector(
      onTap: () {
        // bottomButtonAction();
        painterHelper.bottomButtonAction(index);
      },
      child: CircleAvatar(
        foregroundImage: AssetImage(imgPath),
        minRadius: 27,
        // maxRadius: 35,
      ),
    );
  }
}
