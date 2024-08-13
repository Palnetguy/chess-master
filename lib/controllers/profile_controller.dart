import 'package:get/get.dart';

import '../models/user.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final AuthController _authController = Get.find();

  var user = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_authController.user.stream);
  }

  void signOut() {
    _authController.signOut();
  }
}
