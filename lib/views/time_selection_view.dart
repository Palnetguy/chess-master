import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chess_controller.dart';
import 'chess_view.dart';

class TimeSelectionView extends StatelessWidget {
  final ChessController _chessController = Get.put(ChessController());

  final List<String> timeControls = [
    "1 min",
    "3 min",
    "5 min",
    "10 min",
    "15 min",
    "30 min"
  ];

  TimeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Time Control"),
      ),
      body: ListView.builder(
        itemCount: timeControls.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(timeControls[index]),
            onTap: () {
              // Set the selected time control and start the game
              _chessController.setTimeControl(timeControls[index]);
              Get.to(() => ChessView());
            },
          );
        },
      ),
    );
  }
}
