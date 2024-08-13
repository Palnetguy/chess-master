import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'home_view.dart';

class AuthView extends StatelessWidget {
  final AuthController _authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login or Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool success = await _authController.signIn(
                  email: emailController.text,
                  password: passwordController.text,
                );
                if (success) {
                  Get.off(() => HomeView());
                } else {
                  Get.snackbar('Error', 'Failed to sign in');
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () async {
                bool success = await _authController.register(
                  email: emailController.text,
                  password: passwordController.text,
                );
                if (success) {
                  Get.off(() => HomeView());
                } else {
                  Get.snackbar('Error', 'Failed to register');
                }
              },
              child: Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
