import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as dev;

import 'constants.dart';
import 'controllers/audio_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';
import 'helper/painter_helper.dart';
import 'services/firebase_service.dart';
import 'views/about_us_view.dart';
import 'views/authentication/login_screen.dart';
import 'views/authentication/sign_up_screen.dart';
import 'views/authentication/splash_screen.dart';
import 'views/chess_home_view.dart';

Future<void> main() async {
  await dotenv.load();

  // The `flutter_soloud` package logs everything
  // (from severe warnings to fine debug messages)
  // using the standard `package:logging`.
  // You can listen to the logs as shown below.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp(options: firebaseOptions);

  // Initialize Firebase App Check
  // await FirebaseAppCheck.instance.activate(
  //   webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY', // Only for web
  // You can use other providers like "AndroidProvider.playIntegrity" for Android
  // or "AppleProvider.appAttest" for iOS
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  Get.put(AuthController());
  Get.put(AudioController());
  Get.put(GameController());
  Get.put(PainterHelper());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      // darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      // home: Obx(() {
      //   return Get.find<AuthController>().user.value == null
      //       ? AuthView()
      //       : HomeView();
      // }),
      // home: const SplashScreen(),
      initialRoute: Constants.splashScreen,
      getPages: [
        GetPage(name: Constants.splashScreen, page: () => const SplashScreen()),
        // GetPage(name: Constants.gameScreen, page: () => const HomeScreen()),
        GetPage(name: Constants.gameScreen, page: () => ChessHomeScreen()),
        // GetPage(name: Constants.settingScreen, page: () => const SettingScreen()),
        GetPage(name: Constants.aboutScreen, page: () => const AboutUsScreen()),
        // GetPage(name: Constants.gameStartUpScreen, page: () => const GameStartUpScreen()),
        // GetPage(name: Constants.gameTimeScreen, page: () => const GameTimeScreen()),
        GetPage(name: Constants.loginScreen, page: () => const LoginScreen()),
        GetPage(name: Constants.signUpScreen, page: () => const SignUpScreen()),
      ],
    );
  }
}
