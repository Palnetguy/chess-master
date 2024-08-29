import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chess/chess.dart' as chess;
import '../models/chess_game.dart';
import 'auth_controller.dart';
import 'dart:async';

class ChessController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find();
  var game = ChessGame().obs;
  var gameId = ''.obs;
  var isOnline = false.obs;
  var timeLeftWhite = 0.obs;
  var timeLeftBlack = 0.obs;
  var selectedTimeControl = "5 min".obs;
  Timer? _timer;

  void setTimeControl(String timeControl) {
    selectedTimeControl.value = timeControl;
    int minutes = int.parse(timeControl.split(' ')[0]);
    timeLeftWhite.value = timeLeftBlack.value = minutes * 60;
  }

  void startNewGame({bool offline = true, String? opponentId}) async {
    isOnline.value = !offline;

    if (offline) {
      game.value = ChessGame(chess.Chess());
      _startTimer();
    } else {
      // // Create a new game in Firestore
      // DocumentReference gameRef = await _firestore.collection('games').add({
      //   'player1': _authController.user.value!.uid,
      //   'player2': opponentId,
      //   'fen': game.value.chessGame.fen,
      //   'turn': 'w',
      //   'lastMove': null,
      //   'timeControl': selectedTimeControl.value,
      //   'timeLeftWhite': timeLeftWhite.value,
      //   'timeLeftBlack': timeLeftBlack.value,
      // });
      // gameId.value = gameRef.id;

      // Listen for game updates
      _listenToGameUpdates(gameId.value);
    }
  }

  void joinGame(String existingGameId) {
    gameId.value = existingGameId;
    isOnline.value = true;

    _listenToGameUpdates(existingGameId);
  }

  void _listenToGameUpdates(String gameId) {
    _firestore.collection('games').doc(gameId).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        game.value.chessGame.load(data['fen']);
        timeLeftWhite.value = data['timeLeftWhite'];
        timeLeftBlack.value = data['timeLeftBlack'];
        update();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (game.value.chessGame.turn == 'w') {
        if (timeLeftWhite.value > 0) {
          timeLeftWhite.value--;
        } else {
          _timer?.cancel();
          _endGame("Black wins on time!");
        }
      } else {
        if (timeLeftBlack.value > 0) {
          timeLeftBlack.value--;
        } else {
          _timer?.cancel();
          _endGame("White wins on time!");
        }
      }
    });
  }

  void makeMove(String from, String to) {
    if (game.value.chessGame.move({'from': from, 'to': to})) {
      update();

      if (isOnline.value) {
        // Update Firestore with the new move and remaining time
        _firestore.collection('games').doc(gameId.value).update({
          'fen': game.value.chessGame.fen,
          'turn': game.value.chessGame.turn,
          'lastMove': '$from$to',
          'timeLeftWhite': timeLeftWhite.value,
          'timeLeftBlack': timeLeftBlack.value,
        });
      }

      _startTimer(); // Restart timer for the next player
    }
  }

  void _endGame(String result) {
    Get.snackbar("Game Over", result);
    // Additional logic to handle the end of the game
  }
}
