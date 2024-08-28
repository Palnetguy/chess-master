import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/audio_controller.dart';
import '../services/share_app_service.dart';
import '../views/about_us_view.dart';

class SettingsDrawer extends StatelessWidget {
  SettingsDrawer({Key? key}) : super(key: key);
  final AudioController audioController = Get.find<AudioController>();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
                // color: Colors.brown,
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage("assets/media/chess2.jpg"))),
            child: Text('Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                )),
          ),
          // ListTile(
          //   title: const Text('Game Sound Volume'),
          //   subtitle: Obx(() {
          //     return Slider(
          //       value: audioController.volume.value,
          //       onChanged: (value) {
          //         audioController.setVolume(value);
          //       },
          //       min: 0.0,
          //       max: 1.0,
          //     );
          //   }),
          // ),
          ListTile(
            title: const Text('Game Volume'),
            subtitle: Obx(() {
              return Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: audioController.gameVolume.value,
                      min: 0.0,
                      max: 10,
                      onChanged: (value) {
                        audioController.setGameVolume(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${audioController.gameVolume.value.toStringAsFixed(1)}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              );
            }),
          ),
          ListTile(
            title: const Text('Music Volume'),
            subtitle: Obx(() {
              return Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: audioController.musicVolume.value,
                      min: 0.0,
                      max: 100,
                      onChanged: (value) {
                        audioController.setMusicVolume(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      audioController.musicVolume.value.toStringAsFixed(1),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              );
            }),
          ),
          ListTile(
            title: Obx(() {
              return Text(audioController.soundEffectsEnabled.value
                  ? 'Disable Sound Effects'
                  : 'Enable Sound Effects');
            }),
            trailing: Obx(() {
              return Switch(
                value: audioController.soundEffectsEnabled.value,
                onChanged: (value) {
                  audioController.toggleSoundEffects(value);
                },
              );
            }),
          ),
          ListTile(
            title: Obx(() {
              return Text(audioController.backgroundMusicEnabled.value
                  ? 'Disable Background Music'
                  : 'Enable Background Music');
            }),
            trailing: Obx(() {
              return Switch(
                value: audioController.backgroundMusicEnabled.value,
                onChanged: (value) {
                  audioController.toggleBackgroundMusic(value);
                },
              );
            }),
          ),
          ListTile(
            title: const Text('About Us'),
            onTap: () {
              // Navigate to About Us screen
              Get.to(() => const AboutUsScreen());
            },
          ),
          ListTile(
            title: const Text('Share App'),
            onTap: () {
              // Share the app
              // ShareService.shareApp();
              Share.share(
                'Check out this awesome Chess app! https://tak-kinship-devs.vercel.app/',
                subject: 'Chess Master App',
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              // Handle logout
            },
          ),
        ],
      ),
    );
  }
}
