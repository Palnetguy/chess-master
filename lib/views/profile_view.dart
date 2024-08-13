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
        title: Text("Profile"),
      ),
      body: Obx(() {
        final user = _profileController.user.value;
        if (user == null) return CircularProgressIndicator();
        return Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.photoURL),
            ),
            SizedBox(height: 20),
            Text(user.displayName, style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text(user.email, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _profileController.signOut(),
              child: Text("Sign Out"),
            ),
          ],
        );
      }),
    );
  }
}
