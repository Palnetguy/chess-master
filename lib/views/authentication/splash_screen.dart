import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants.dart';
import '../../controllers/auth_controller.dart';
import '../../services/assets_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<SplashScreen> {
  // check authenticationState - if isSignedIn or not
  final authController = Get.find<AuthController>();
  void checkAuthenticationState() async {
    if (await authController.checkIsSignedIn()) {
      // 1. get user data from firestore
      await authController.getUserDataFromFireStore();

      // 2. save user data to shared preferences
      await authController.saveUserDataToSharedPref();

      // 3. navigate to home screen
      navigate(isSignedIn: true);
    } else {
      // navigate to the sign screen
      navigate(isSignedIn: false);
    }
  }

  @override
  void initState() {
    checkAuthenticationState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(AssetsManager.chessIcon),
        ),
      ),
    );
  }

  void navigate({required bool isSignedIn}) {
    if (isSignedIn) {
      Get.offNamed(Constants.gameScreen);
    } else {
      Get.offNamed(Constants.loginScreen);
    }
  }
}
