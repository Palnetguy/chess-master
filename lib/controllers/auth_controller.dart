import 'package:get/get.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class AuthController extends GetxController {
  // Observable for the user, which can be null if not logged in
  var user = Rx<UserModel?>(null);
  bool isLoggedIn = false;

  @override
  void onInit() {
    // Binding the user stream to listen for changes in authentication state
    user.bindStream(FirebaseService().userStream());
    super.onInit();
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    try {
      user.value =
          await FirebaseService().signInWithEmailAndPassword(email, password);
      isLoggedIn = true;
      return true;
    } catch (e) {
      Get.snackbar('Sign In Failed', e.toString());
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(
      {required String email, required String password}) async {
    try {
      user.value =
          await FirebaseService().registerWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      Get.snackbar('Registration Failed', e.toString());
      return false;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      user.value = await FirebaseService().signInWithGoogle();
      isLoggedIn = true;
    } catch (e) {
      Get.snackbar('Google Sign In Failed', e.toString());
    }
  }

  // Sign out
  void signOut() {
    FirebaseService().signOut();
    user.value = null;
    isLoggedIn = false;
  }
}
