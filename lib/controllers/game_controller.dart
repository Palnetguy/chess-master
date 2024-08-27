import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:ui' as ui;

class GameController extends GetxController {
  var level = 'LEVEL 2'.obs;
  var gameStatus = ''.obs;
  var gameTime = ''.obs;
  var gameResult = 'In Progress'.obs;
  Rx<ui.Image?> imageText = Rx<ui.Image?>(null);

  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer before starting a new one
    _elapsedSeconds = 0; // Reset the elapsed time
    gameTime.value = _formatTime(_elapsedSeconds);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      gameTime.value = _formatTime(_elapsedSeconds);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    seconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Update game time
  void updateGameTime(String time) {
    gameTime.value = time;
  }

  // Update game result
  void updateGameResult(String result) {
    // Use a delayed callback to avoid triggering state changes during rendering.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      gameResult.value = result;
      _stopTimer();
    });
  }

  // Reset game values
  void reset() {
    gameStatus.value = '';
    gameResult.value = 'In Progress';
    _startTimer(); // Restart the timer from 0
  }

  void drawImageText(ui.Image? imageResultText) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      imageText.value = imageResultText;
    });
    // update();
  }
}
