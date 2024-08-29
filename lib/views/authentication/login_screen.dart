import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chess_master/controllers/auth_controller.dart';
import 'package:chess_master/constants.dart';
import 'package:chess_master/helper/helper_methods.dart';
import 'package:chess_master/services/assets_manager.dart';
import 'package:chess_master/widgets/main_auth_button.dart';
import 'package:chess_master/widgets/social_button.dart';
import 'package:chess_master/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String email;
  late String password;
  bool obscureText = true;

  final AuthController authController = Get.find<AuthController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void signInUser() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      authController
          .signInUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .then((userCredential) async {
        if (userCredential != null) {
          bool userExist = await authController.checkUserExist();

          if (userExist) {
            await authController.getUserDataFromFireStore();
            await authController.saveUserDataToSharedPref();
            await authController.setSignedIn();
            formKey.currentState!.reset();
            authController.setIsLoading(false);
            Get.offAllNamed(Constants.gameScreen);
          } else {
            // TODO: Navigate to user information screen
            Get.offAllNamed(Constants.aboutScreen);
            // Get.snackbar('Error', 'You');
          }
        }
      });
    } else {
      Get.snackbar('Error', 'Please fill all fields');
    }
  }

  void signInWithGoogle() async {
    final user = await authController.signInWithGoogle();
    if (user != null) {
      Get.offAllNamed(Constants.gameScreen);
    } else {
      Get.snackbar('Error', 'Google sign-in failed');
    }
  }

  void signInWithFacebook() async {
    final user = await authController.signInWithFacebook();
    if (user != null) {
      Get.offAllNamed(Constants.gameScreen);
    } else {
      Get.snackbar('Error', 'Facebook sign-in failed');
    }
  }

  void signInWithTwitter() async {
    final user = await authController.signInWithTwitter();
    if (user != null) {
      Get.offAllNamed(Constants.gameScreen);
    } else {
      Get.snackbar('Error', 'Twitter sign-in failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(AssetsManager.chessIcon),
                  ),
                  const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  TextFormField(
                    decoration: textFormDecoration.copyWith(
                        labelText: 'Enter your email',
                        hintText: 'Enter your email'),
                    validator: validateEmailField,
                    onChanged: (value) {
                      email = value.trim();
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    decoration: textFormDecoration.copyWith(
                      labelText: 'Enter your password',
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    obscureText: obscureText,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a password';
                      } else if (value.length < 8) {
                        return 'Password must be atleast 8 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      password = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password functionality
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() => authController.isLoading
                      ? const CircularProgressIndicator()
                      : MainAuthButton(
                          lable: 'LOGIN',
                          onPressed: signInUser,
                          fontSize: 24.0,
                        )),
                  const SizedBox(height: 20),
                  const Text(
                    '- OR - \n Sign in With',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // SocialButton(
                      //   label: 'Guest',
                      //   assetImage: AssetsManager.userIcon,
                      //   height: 55.0,
                      //   width: 55.0,
                      //   onTap: () {
                      //     // TODO: Implement guest login
                      //   },
                      // ),
                      SocialButton(
                        label: 'Google',
                        assetImage: AssetsManager.googleIcon,
                        height: 55.0,
                        width: 55.0,
                        onTap: signInWithGoogle,
                      ),
                      SocialButton(
                        label: 'Facebook',
                        assetImage: AssetsManager.facebookLogo,
                        height: 55.0,
                        width: 55.0,
                        onTap: signInWithFacebook,
                      ),
                      SocialButton(
                          label: 'Twitter',
                          assetImage: AssetsManager.twitterLogo,
                          height: 55.0,
                          width: 55.0,
                          onTap: signInWithTwitter),
                    ],
                  ),
                  const SizedBox(height: 40),
                  HaveAccountWidget(
                    label: 'Don\'t have an account?',
                    labelAction: 'Sign Up',
                    onPressed: () {
                      Get.toNamed(Constants.signUpScreen);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
