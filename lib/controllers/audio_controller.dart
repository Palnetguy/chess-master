import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

class AudioController extends GetxController {
  static final Logger _log = Logger('AudioController');

  SoLoud? _soloud;
  SoundHandle? _musicHandle;
  final Map<String, AudioSource> _loadedSounds = {};

  // Volume and sound control properties
  var gameVolume = 0.5.obs;
  var musicVolume = 0.5.obs;
  var soundEffectsEnabled = true.obs;
  var backgroundMusicEnabled = true.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _soloud = SoLoud.instance;
    await _soloud!.init();

    // Set initial global volume
    _soloud!.setGlobalVolume(gameVolume.value);

    // Preload sound effects
    await _preloadSounds();
  }

  Future<void> _preloadSounds() async {
    final soundEffects = [
      'assets/sounds/board-start.mp3',
      'assets/sounds/checkmate.mp3',
      'assets/sounds/sd1.mp3',
      'assets/sounds/sd2.mp3',
    ];

    for (final soundPath in soundEffects) {
      try {
        final sound = await _soloud!.loadAsset(soundPath);
        _loadedSounds[soundPath] = sound;
        _log.info('Preloaded sound: $soundPath');
      } catch (e) {
        _log.severe('Failed to preload sound: $soundPath', e);
      }
    }
  }

  @override
  void dispose() {
    _disposeLoadedSounds();
    _soloud?.deinit();
    super.dispose();
  }

  void _disposeLoadedSounds() {
    for (final sound in _loadedSounds.values) {
      _soloud?.disposeSource(sound);
    }
    _loadedSounds.clear();
  }

  // Method to play one-shot sound effects
  Future<void> playSound(String assetKey) async {
    if (!soundEffectsEnabled.value) {
      _log.info("Sound effects are disabled. Not playing: $assetKey");
      return;
    }
    try {
      if (_loadedSounds.containsKey(assetKey)) {
        await _soloud!.play(_loadedSounds[assetKey]!);
      } else {
        _log.warning("Sound not preloaded: $assetKey. Loading now...");
        final source = await _soloud!.loadAsset(assetKey);
        _loadedSounds[assetKey] = source;
        await _soloud!.play(source);
      }
    } on SoLoudException catch (e) {
      _log.severe("Cannot play sound '$assetKey'. Ignoring.", e);
    }
  }

  // Method to start playing background music
  Future<void> startMusic() async {
    if (!backgroundMusicEnabled.value) {
      _log.info("Background Music is disabled. Not playing");
      return;
    }
    if (_musicHandle != null) {
      if (_soloud!.getIsValidVoiceHandle(_musicHandle!)) {
        _log.info('Music is already playing. Stopping first.');
        await _soloud!.stop(_musicHandle!);
      }
    }
    _log.info('Loading music');
    final musicSource = await _soloud!
        .loadAsset('assets/music/looped-song.ogg', mode: LoadMode.disk);
    musicSource.allInstancesFinished.first.then((_) {
      _soloud!.disposeSource(musicSource);
      _log.info('Music source disposed');
      _musicHandle = null;
    });

    _log.info('Playing music');
    _musicHandle = await _soloud!.play(
      musicSource,
      volume: musicVolume.value,
      looping: true,
      loopingStartAt: const Duration(seconds: 25, milliseconds: 43),
    );
  }

  // Method to fade out the currently playing music
  void fadeOutMusic() {
    if (_musicHandle == null) {
      _log.info('Nothing to fade out');
      return;
    }
    const length = Duration(seconds: 5);
    _soloud!.fadeVolume(_musicHandle!, 0, length);
    _soloud!.scheduleStop(_musicHandle!, length);
  }

  // Method to apply an environmental effect filter
  void applyFilter() {
    _soloud!.addGlobalFilter(FilterType.freeverbFilter);
    _soloud!.setFilterParameter(FilterType.freeverbFilter, 0, 0.2);
    _soloud!.setFilterParameter(FilterType.freeverbFilter, 2, 0.9);
  }

  // Method to remove the applied environmental effect filter
  void removeFilter() {
    _soloud!.removeGlobalFilter(FilterType.freeverbFilter);
  }

  // Method to set game volume
  void setGameVolume(double value) {
    gameVolume.value = value;
    _soloud!.setGlobalVolume(value);
  }

  // Method to set music volume
  void setMusicVolume(double value) {
    musicVolume.value = value;
    if (_musicHandle != null && _soloud!.getIsValidVoiceHandle(_musicHandle!)) {
      _soloud!.setVolume(_musicHandle!, value);
    }
  }

  // Method to enable or disable sound effects
  void toggleSoundEffects(bool value) {
    soundEffectsEnabled.value = value;
  }

  // Method to enable or disable background music
  void toggleBackgroundMusic(bool value) {
    backgroundMusicEnabled.value = value;
    if (backgroundMusicEnabled.value) {
      startMusic();
    } else {
      fadeOutMusic();
    }
  }
}
