import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chess_controller.dart';
import '../widgets/chess_board.dart';

class ChessView extends StatelessWidget {
  final ChessController _chessController = Get.find();

  ChessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chess Game"),
        actions: [
          if (_chessController.isOnline.value)
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                // Logic to invite or start a multiplayer game
              },
            ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
                child:
                    ChessBoard(fen: _chessController.game.value.chessGame.fen)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                    "White: ${_formatTime(_chessController.timeLeftWhite.value)}"),
                Text(
                    "Black: ${_formatTime(_chessController.timeLeftBlack.value)}"),
              ],
            ),
            if (_chessController.isOnline.value)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "Turn: ${_chessController.game.value.chessGame.turn == 'w' ? 'White' : 'Black'}"),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chessController.startNewGame(
            offline: false, opponentId: 'opponentUserId'),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
