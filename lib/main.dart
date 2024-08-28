import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as dev;

import 'controllers/audio_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';
import 'helper/painter_helper.dart';
import 'services/firebase_service.dart';
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

  Get.put(AudioController());
  Get.put(AuthController());
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
      home: ChessHomeScreen(),
    );
  }
}
