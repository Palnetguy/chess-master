import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'profile_view.dart';

class SettingsView extends StatelessWidget {
  final SettingsController _settingsController = Get.put(SettingsController());

  SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Obx(() => ListView(
            children: [
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: _settingsController.isDarkMode.value,
                onChanged: (value) => _settingsController.toggleDarkMode(),
              ),
              ListTile(
                title: const Text("Profile"),
                onTap: () => Get.to(() => ProfileView()),
              ),
            ],
          )),
    );
  }
}
