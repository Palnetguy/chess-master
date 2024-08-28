import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatelessWidget {
  final ProfileController _profileController = Get.put(ProfileController());

  ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Obx(() {
        final user = _profileController.user.value;
        if (user == null) return const CircularProgressIndicator();
        return Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.photoURL),
            ),
            const SizedBox(height: 20),
            Text(user.displayName, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _profileController.signOut(),
              child: const Text("Sign Out"),
            ),
          ],
        );
      }),
    );
  }
}
