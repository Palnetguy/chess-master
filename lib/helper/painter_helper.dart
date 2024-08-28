import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/audio_controller.dart';
import '../controllers/game_controller.dart';
import '../engines/fruit.dart';
import '../engines/lousy.dart';
import '../engines/owl.dart';

// square
class sqData {
  ui.Rect? rect;
}

// This supports the most important
//   Painter class that makes drawings in canvas.
//
// Just to keep CustomPainter code minimal,
//   to wrap around because CustomPainter is the main game loop,
//   to keep shared variables and pass pointer as parameter,
//   to provide various functions - chess, drawables, images, etc.
//
// Everything around CustomPainter.
//
// -------
// Also some gesture detector helpers there. Mouse clicks or taps.
//

class PainterHelper extends GetxController {
  late CustomPainter CP;
  late Canvas canvas;
  late int width, height;
  RxDouble squareSize = 70.0.obs;

  RxBool repaint = true.obs;

  RxBool imPlayingWhite = true.obs;

  RxInt pauseWait = 0.obs; // Can set to pause and paint only

  int animTCnt = 10;
  RxInt animTck = 0.obs; // Animation ticker
  RxInt animFromSquare = 0.obs;
  RxInt animToSquare = 0.obs;

  RxBool isCheck = false.obs;
  RxBool isCheckMate = false.obs;
  RxBool isStaleMate = false.obs;
  RxBool isRep3x = false.obs;
  RxString gameResult = "".obs;

  RxBool txtYourMove = false.obs;
  RxBool txtThinking = false.obs;

  RxBool goGitHub = false.obs; // if should redirect to GitHub page
  RxBool goWorkSheet = false.obs; // if should redirect to worksheet page

  ui.Image? wk, wq, wr, wb, wn, wp;
  ui.Image? bk, bq, br, bb, bn, bp;
  ui.Image? ex1, ex2, ex3, ex4;
  ui.Image? bNG, bTB, bOw, bFr, bLo, bPG, bGI;
  ui.Image? tYM, tTH, tST, tCK, tCM10, tCM01, tRP;
  ui.Image? lm1, lm0;

  static const engineOwl = 1;
  static const engineFruit = 2;
  static const engineLousy = 3;
  RxInt engineSelected = engineOwl.obs;

  late OwlEngine owl;
  late FruitEngine fruit;
  late LousyEngine lousy;
  RxBool is64bitOK = (((1 << 32) >>> 1) == (1 << 31)).obs;

  late List<sqData> sqDatas = [];
  late List<sqData> btDatas = [];

  RxInt dragSquare = (-1).obs;
  RxList<int> dSquares = <int>[].obs;

  // static PainterHelper get instance => Get.find<PainterHelper>();
  final AudioController audioController = Get.find<AudioController>();

  int btnIndex = 0;

  late DateTime startTime;
  final GameController gameController = Get.find<GameController>();

  // construct
  PainterHelper() {
    owl = OwlEngine();
    fruit = FruitEngine();
    if (is64bitOK.value) lousy = LousyEngine();

    for (int i = 0; i < 64; i++) {
      sqDatas.add(sqData());
    }
    for (int i = 0; i <= 7; i++) {
      btDatas.add(sqData());
    }
  }

  Map<String, ui.Image?> pieceImages = {};

  void setPieceImage(String imageName, ui.Image image) {
    pieceImages[imageName] = image;
  }

  // Add methods to retrieve images if necessary
  ui.Image? getPieceImage(String imageName) {
    return pieceImages[imageName];
  }

  // shoild repaint on animation or not
  bool shouldRepaint() {
    bool r = repaint.value;
    repaint.value = false;
    return r;
  }

  // various functions

  double SqSize() {
    return squareSize.value; // The size of square
  }

  // on each repaint (not optimal, but ok)
  adjustSqSize(int w, int h) {
    width = w;
    height = h;
    int mi = w;
    int ma = mi;

    if (mi > h) mi = h;
    if (ma < h) ma = h;

    // Resize chess board
    double a = mi / 8; // approx. sq.size for 8x8 board
    // if need more space for buttons
    if ((mi + a) > (ma - 4)) a = mi / 9;

    // Adjust board size...
    while (squareSize.value < (a + 11) && squareSize.value < 90) {
      squareSize.value++;
    }
    while (squareSize.value > (a - 1) && squareSize.value > 30) {
      squareSize.value--;
    }
  }

  bool isDarkSq(int sq) {
    return ((1 - (((sq >> 3) + (sq & 7)) & 1)) != 0);
  }

  // each chess piece image with scale and offset parameters
  ui.Image? imgCoTy(int col, int type) {
    return [wk, wq, wr, wb, wn, wp, bk, bq, br, bb, bn, bp][(col * 6) + type];
  }

  // chess pieces scale
  double scale(int type) {
    return [1.0, 1.0, 0.8, 0.85, 0.83, 0.7][type];
  }

  // X left +offset
  double x0(int type) {
    return [10.0, 10.0, 17.0, 16.0, 16.0, 20.0][type];
  }

  // y top +offset
  double y0(int type) {
    return [10.0, 10.0, 19.0, 16.0, 18.0, 22.0][type];
  }

  // buttons

  ui.Image? but_Img(int i) {
    return [bNG, bTB, bOw, bFr, bLo, bPG, bGI][i];
  }

  double but_scale(int i) {
    if (i < 7) return 1.2;
    if (i == 7) return 1.8;
    return 1;
  }

  double but_x0(int i) {
    if (i < 7) return 4.0;
    if (i == 7) return -2.0;
    return 0.0;
  }

  double but_y0(int i) {
    if (i < 7) return 4.0;
    if (i == 7) return -20.0;
    return 0.0;
  }

  saveSqRect(int sq, ui.Rect rect) {
    if (sq >= 0 && sq < sqDatas.length) {
      // Access sqDatas[sq] safely
      sqDatas[sq].rect = rect;
    }
  }

  saveButTxtRect(int i, ui.Rect rect) {
    btDatas[i].rect = rect;
  }

// take this from OWL engine only
  int pieceColAt(int sq) {
    return owl.pieceColAt(sq);
  }

  int pieceTypeAt(int sq) {
    return owl.pieceTypeAt(sq);
  }

  int animCol() {
    return owl.anm_cl;
  }

  int animType() {
    return owl.anm_pc - 1;
  }

  String get_MoveslistUcis() {
    return owl.MoveslistUcis;
  }

  // Gestures

  void verifyTap(double x, double y) {
    if (pauseWait.value > 0 || animTck.value > 0 || txtThinking.value) return;

    if (owl.isItMyMove(imPlayingWhite.value)) {
      for (int i = 0; i < 64; i++) {
        if (isCheckMate.value || isStaleMate.value) break;

        sqData ob = sqDatas[i];

        if ((ob.rect?.top)! <= y &&
            (ob.rect?.left)! <= x &&
            (ob.rect?.bottom)! >= y &&
            (ob.rect?.right)! >= x) {
          if (dragSquare.value != i) {
            List<int> legals = owl.LegalMovesToSquares(i);
            for (int j = 0; j < legals.length; j++) {
              if (dragSquare.value != i) dSquares = <int>[].obs;
              dragSquare.value = i;
              dSquares.add(legals[j]);
              repaint.value = true;
            }
          }

          if (dragSquare.value != -1) {
            for (int j = 0; j < dSquares.length; j++) {
              if (dSquares[j] == i) {
                AnimToMove(dragSquare.value, i);
                dragSquare.value = -1;
                dSquares.clear();
                // dSquares = <int>[].obs;
                repaint.value = true;
                break;
              }
            }
          }
        }
      }
    }

    // verify buttons

    if (isCheckMate.value) {
      audioController.playSound("assets/sounds/checkmate.mp3");
    }

    // for (var i = 0; i < 7; i++) {
    //   sqData Ob = btDatas[i];

    //   if (Ob.rect != null &&
    //       (Ob.rect?.top)! <= y &&
    //       (Ob.rect?.left)! <= x &&
    //       (Ob.rect?.bottom)! >= y &&
    //       (Ob.rect?.right)! >= x) {
    //     if (i == 0) NewGame();
    //     if (i == 1) TakeBack();

    //     if (i == 2) {
    //       engineSelected.value = engineOwl;
    //       owl.LampTck = 20;
    //       print("Clicked OWL Engine");
    //     }
    //     if (i == 3) {
    //       engineSelected.value = engineFruit;
    //       fruit.LampTck = 20;
    //       print("Clicked Fruit Engine");
    //     }
    //     if (i == 4 && is64bitOK.value) {
    //       engineSelected.value = engineLousy;
    //       lousy.LampTck = 20;
    //       print("Clicked Lousy Engine");
    //     }
    //     if (i == 5) goGitHub.value = true;
    //     if (i == 6) goWorkSheet.value = true;
    //   }
    // }
  }

  // Set animation on
  void AnimToMove(int fromSq, int toSq) {
    animTck.value = animTCnt;
    animFromSquare.value = fromSq;
    animToSquare.value = toSq;
    owl.HidePieceSq(fromSq);
    audioController.playSound("assets/sounds/sd2.mp3");
  }

  void MoveAfterAnimation() {
    owl.RestorePieceSq();
    owl.MakeMove(animFromSquare.value, animToSquare.value);
    fruit.MakeMove(animFromSquare.value, animToSquare.value);
    if (is64bitOK.value) {
      lousy.MakeMove(animFromSquare.value, animToSquare.value);
    }
    // audioController.playSound("assets/sounds/sd2.mp3");
  }

  void bottomButtonAction(int i) {
    if (i == 0) NewGame();
    if (i == 1) TakeBack();

    if (i == 2) {
      engineSelected.value = engineOwl;
      owl.LampTck = 20;
      print("Clicked OWL Engine");
    }
    if (i == 3) {
      engineSelected.value = engineFruit;
      fruit.LampTck = 20;
      print("Clicked Fruit Engine");
    }
    if (i == 4 && is64bitOK.value) {
      engineSelected.value = engineLousy;
      lousy.LampTck = 20;
      print("Clicked Lousy Engine");
    }
    // if (i == 5) goGitHub.value = true;
    // if (i == 6) goWorkSheet.value = true;

    repaint.value = true;
  }

  // Start a new game
  void NewGame() {
    dragSquare.value = -1;
    dSquares = <int>[].obs;

    imPlayingWhite.value = !imPlayingWhite.value;
    owl.NewGame();
    fruit.NewGame;
    if (is64bitOK.value) lousy.NewGame();
    audioController.playSound("assets/sounds/board-start.mp3");
    repaint.value = true;
    pauseWait.value = 10;

    // isCheck.value = false;
    // isCheckMate.value = false;
    // isStaleMate.value = false;
    // isRep3x.value = false;
    // gameResult.value = "";

    // txtYourMove.value = false;
    // txtThinking.value = false;

    // animTck.value = 0;
    // animFromSquare.value = 0;
    // animToSquare.value = 0;

    // Resetting other game states in your gameController if necessary
    gameController.resetGameState();
  }

  // Take back a move
  // TakeBack() {
  //   dragSquare = -1;
  //   dSquares = [];

  //   for (int i = 0; i < 2; i++) {
  //     owl.TakeBack();
  //     Fruit.TakeBack();
  //     if (is64bitOK.value) Lousy.TakeBack();
  //   }
  //   repaint = true;
  //   PauseWait = 10;
  // }

  void TakeBack() {
    dragSquare.value = -1;
    dSquares = <int>[].obs;

    for (int i = 0; i < 2; i++) {
      owl.TakeBack();
      fruit.TakeBack();
      if (is64bitOK.value) lousy.TakeBack();
    }
    repaint.value = true;
    audioController.playSound("assets/sounds/sd1.mp3");
    pauseWait.value = 10;
  }

  // if (owl.MoveslistUcis.isNotEmpty) {
  //   owl.TakeBack();
  //   fruit.TakeBack();
  //   if (is64bitOK.value) lousy.TakeBack();

  //   isCheck.value = false;
  //   isCheckMate.value = false;
  //   isStaleMate.value = false;
  //   isRep3x.value = false;
  //   gameResult.value = "";

  //   txtYourMove.value = false;
  //   txtThinking.value = false;

  //   repaint.value = true;
  // }
  // }

  // updates text messages
  void updateTexts() {
    String s = owl.Comment();
    gameResult.value = "";
    isCheck.value = (s.contains("Check!"));
    isCheckMate.value = (s.contains("CheckMate!"));
    isStaleMate.value = (s.contains("StaleMate!"));
    if (isCheckMate.value) {
      if (s.contains("1-0")) {
        gameResult.value = "1-0";
        gameController.updateGameResult("White Wins");
        // gameController.playerDefeated(); // Example to update level on defeat
      }
      if (s.contains("0-1")) {
        gameResult.value = "0-1";
        gameController.updateGameResult("Black Wins");
        // gameController.playerDefeated(); // Example to update level on defeat
      }
    }
    if (s.contains("1/2")) {
      gameResult.value = "1/2-1/2";
      gameController.updateGameResult("Draw");
    }
    if (s.contains("Repetition")) {
      isRep3x.value = true;
      gameController.updateGameResult("Repetition");
    }
  }

  // The main loop on animator.
  gameloop() {
    if (pauseWait.value > 0) {
      repaint.value = true;
      pauseWait.value--;
      if (pauseWait.value == 3) updateTexts();
      return;
    }
    if (animTck.value > 0) {
      animTck.value--;
      if (animTck.value == 0) {
        MoveAfterAnimation();
        pauseWait.value = 15;
      }
      repaint.value = true;
      return;
    }

    if (owl.LampTck > 0) {
      owl.LampTck--;
      if (owl.LampTck == 0) pauseWait.value = 15;
      repaint.value = true;
      return;
    }

    if (fruit.LampTck > 0) {
      fruit.LampTck--;
      if (fruit.LampTck == 0) pauseWait.value = 15;
      repaint.value = true;
      return;
    }

    if (is64bitOK.value) {
      if (lousy.LampTck > 0) {
        lousy.LampTck--;
        if (lousy.LampTck == 0) pauseWait.value = 15;
        repaint.value = true;
        return;
      }
    }

    if (isCheckMate.value || isStaleMate.value) return;

    txtThinking.value = false;
    txtYourMove.value = owl.isItMyMove(imPlayingWhite.value);

    if (dragSquare.value == -1) {
      String a = "";
      if (engineSelected.value == engineOwl) {
        a = owl.Calculate(imPlayingWhite.value);
      }
      if (engineSelected.value == engineFruit) {
        a = fruit.Calculate(imPlayingWhite.value);
      }

      if (engineSelected.value == engineLousy) {
        a = lousy.Calculate(imPlayingWhite.value);
        if (a.length >= 4) {
          // not sure all moves are ok
          if (!owl.areMovesOk(a)) {
            engineSelected.value = engineOwl;
            a = owl.Calculate(imPlayingWhite.value);
          }
        }
      }

      if (a.length == 1) {
        txtThinking.value = true;
      } else if (a.length >= 4) {
        // chess move
        int fromSq = owl.at2square(a.substring(0, 2));
        int toSq = owl.at2square(a.substring(2, 4));
        if (fromSq >= 0 && fromSq < 64 && toSq >= 0 && toSq < 64) {
          AnimToMove(fromSq, toSq);
          txtThinking.value = false;
        } else {
          // Handle invalid move gracefully
          print("Invalid movge detected Here Boss");
        }
      } else if (a.isNotEmpty) {
        repaint.value = true;
      }
    }
  }

  void updateGameTime() {
    final setTime = DateTime.now();
    final minutes = setTime.minute;
    final seconds = setTime.second % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    gameController.updateGameTime(timeStr);
  }
}
