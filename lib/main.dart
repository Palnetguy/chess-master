import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';
import 'helper/painter_helper.dart';
import 'services/firebase_service.dart';
import 'views/auth_view.dart';
import 'views/chess_home_view.dart';
import 'views/home_view.dart';
import 'views/painter.dart';

Future<void> main() async {
  await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
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
