import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import 'profile_view.dart';

class SettingsView extends StatelessWidget {
  final SettingsController _settingsController = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Obx(() => ListView(
            children: [
              SwitchListTile(
                title: Text("Dark Mode"),
                value: _settingsController.isDarkMode.value,
                onChanged: (value) => _settingsController.toggleDarkMode(),
              ),
              ListTile(
                title: Text("Profile"),
                onTap: () => Get.to(() => ProfileView()),
              ),
            ],
          )),
    );
  }
}
