import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:startapp_sdk/startapp.dart';
import '../controllers/google_ads_controller.dart';
import '../controllers/audio_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/startapp_ads_controller.dart';
import '../helper/imagetext_painter.dart';
import '../widgets/settings_drawer.dart';
import 'painter.dart';
import '../helper/painter_helper.dart';

class ChessHomeScreen extends StatelessWidget {
  ChessHomeScreen({super.key});
  String assetPath = "assets/images/";
  final PainterHelper painterHelper = Get.find<PainterHelper>();
  final AudioController audioController = Get.find<AudioController>();
  final AuthController authController = Get.find<AuthController>();
  // final GoogleAdsController admobAdsController =
  // Get.find<GoogleAdsController>();
  final StartAppAdsController startappAdsController =
      Get.find<StartAppAdsController>();
  // final user = authController.userModel;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final GameController gameController = Get.find<GameController>();
    final user = authController.userModel;

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: SettingsDrawer(),
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
                  GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          user?.image != null && user!.image!.isNotEmpty
                              ? NetworkImage(user.image!)
                              : null,
                      child: user?.image == null || user!.image!.isEmpty
                          ? const Icon(Icons.person,
                              size: 35, color: Colors.brown)
                          : null,
                    ),
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
                  // const Icon(
                  //   Icons.settings,
                  //   color: Colors.red,
                  //   size: 30,
                  // ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.red,
                      size: 30,
                    ),
                    onPressed: () {
                      // Open the drawer
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
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

            Obx(() => startappAdsController.bannerAd.value != null
                ? StartAppBanner(startappAdsController.bannerAd.value!)
                : const SizedBox(
                    height: 40,
                  )),

            const SizedBox(
              height: 10,
            ),

            // Flexible widget to allow the chessboard to resize based on available space
            const Expanded(
              child: Painter(),
            ),

            // Obx(() {
            //   if (admobAdsController.isAdLoaded.value) {
            //     return admobAdsController.getBannerAd();
            //   } else {
            //     return const SizedBox.shrink();
            //   }
            // }),

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
    return Obx(() {
      // Assuming isThinking is a reactive variable in the gameController
      bool isThinking = painterHelper.txtThinking.value;

      return Stack(
        children: [
          InkWell(
            onTap: () {
              if (kDebugMode) {
                print("Selected Index is $index");
              }
              if (kDebugMode) {
                print(
                    "Selected Engine is ${painterHelper.engineSelected.value}");
              }
              painterHelper.bottomButtonAction(index);
              if (kDebugMode) {
                print(
                    "Selected Engine is ${painterHelper.engineSelected.value}");
              }
            },
            child: CircleAvatar(
              foregroundImage: AssetImage(imgPath),
              minRadius: 27,
              // maxRadius: 35,
            ),
          ),
          if (isThinking && painterHelper.engineSelected.value == (index - 1))
            redLampOverlay(),
        ],
      );
    });
  }

  // Widget gameBottomButton(String imgPath, int index) {
  //   return InkWell(
  //     onTap: () {
  //       // bottomButtonAction();
  //       painterHelper.bottomButtonAction(index);
  //     },
  //     child: CircleAvatar(
  //       foregroundImage: AssetImage(imgPath),
  //       minRadius: 27,
  //       // maxRadius: 35,
  //     ),
  //   );
  // }

  Widget redLampOverlay() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}
