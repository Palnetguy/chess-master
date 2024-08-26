import 'package:get/get.dart';
import 'dart:async';

class GameController extends GetxController {
  var level = 'LEVEL 2'.obs; // Example level, replace with your logic
  var gameStatus = ''.obs; // 'In Progress', 'You Win', 'You Lost'
  var gameTime = ''.obs; // Time display
  var gameResult = 'In Progress'.obs; // Result message: 'You Win' or 'You Lost'

  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() {
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

  // void setGameResult(bool win) {
  //   _stopTimer();
  //   gameResult.value = win ? 'You Win' : 'You Lost';
  // }

  // Update game result
  void updateGameResult(String result) {
    gameResult.value = result;
    _stopTimer();
  }

  // Reset game values
  void reset() {
    gameStatus.value = '';
    // gameTime.value = '0:00';
    gameResult.value = '';
    // _startTimer();
    // update();
  }
}
