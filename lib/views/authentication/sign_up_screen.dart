import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:chess_master/controllers/auth_controller.dart';
import 'package:chess_master/models/user_model.dart';
import 'package:chess_master/widgets/main_auth_button.dart';
import 'package:chess_master/widgets/widgets.dart';
import 'package:chess_master/helper/helper_methods.dart';
import 'package:chess_master/constants.dart';

import '../../services/assets_manager.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  File? finalFileImage;
  late String name;
  late String email;
  late String password;
  bool obscureText = true;

  final AuthController authController = Get.find<AuthController>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void selectImage({required bool fromCamera}) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (e) {
        Get.snackbar("Error", e.toString());
      },
    );

    if (finalFileImage != null) {
      cropImage(finalFileImage!.path);
    } else {
      Get.back();
    }
  }

  void cropImage(String path) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      maxHeight: 800,
      maxWidth: 800,
    );

    Get.back();

    if (croppedFile != null) {
      setState(() {
        finalFileImage = File(croppedFile.path);
      });
    }
  }

  void showImagePickerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select an Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                selectImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Gallery"),
              onTap: () {
                selectImage(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void signUpUser() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      authController
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .then((userCredential) {
        if (userCredential != null) {
          UserModel userModel = UserModel(
            uid: userCredential.user!.uid,
            name: name,
            email: email,
            image: '',
            createdAt: '',
            playerRating: 1200,
          );

          authController.saveUserDataToFireStore(
            currentUser: userModel,
            fileImage: finalFileImage,
            onSuccess: () async {
              formKey.currentState!.reset();
              Get.snackbar("Success", 'Sign Up successful, Please Login');
              await authController.signOutUser();
              Get.offNamed(Constants.loginScreen);
            },
            onFail: (error) {
              Get.snackbar("Error", error.toString());
            },
          );
        }
      });
    } else {
      Get.snackbar("Error", 'Please fill all fields');
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
                  const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  finalFileImage != null
                      ? Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue,
                              backgroundImage:
                                  FileImage(File(finalFileImage!.path)),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    border: Border.all(
                                        width: 2, color: Colors.white),
                                    borderRadius: BorderRadius.circular(35)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      // pick image from camera or galery
                                      showImagePickerDialog();
                                    },
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      : Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue,
                              backgroundImage:
                                  AssetImage(AssetsManager.userIcon),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.lightBlue,
                                    border: Border.all(
                                        width: 2, color: Colors.white),
                                    borderRadius: BorderRadius.circular(35)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      // pick image from camera or galery
                                      showImagePickerDialog();
                                    },
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                  const SizedBox(
                    height: 40,
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 25,
                    maxLines: 1,
                    decoration: textFormDecoration.copyWith(
                      counterText: '',
                      labelText: 'Enter your name',
                      hintText: 'Enter your name',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your name';
                      } else if (value.length < 3) {
                        return 'Name must be atleast 3 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      name = value.trim();
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                    decoration: textFormDecoration.copyWith(
                      labelText: 'Enter your email',
                      hintText: 'Enter your email',
                    ),
                    validator: validateEmailField,
                    onChanged: (value) {
                      email = value.trim();
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.done,
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
                  const SizedBox(height: 20),
                  Obx(() => authController.isLoading
                      ? const CircularProgressIndicator()
                      : MainAuthButton(
                          lable: 'SIGN UP',
                          onPressed: signUpUser,
                          fontSize: 24.0,
                        )),
                  const SizedBox(height: 40),
                  HaveAccountWidget(
                    label: 'Have an account?',
                    labelAction: 'Sign In',
                    onPressed: () {
                      Get.back();
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
