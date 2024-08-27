import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

class PainterHelper {
  late CustomPainter CP;
  late Canvas canvas;
  late int width, height;
  double SquareSize = 70.0;

  bool repaint = true;

  bool ImPlayingWhite = true;

  int PauseWait = 0; // Can set to pause and paint only

  int AnimTCnt = 10;
  int AnimTck = 0; // Animation ticker
  int Anim_from_square = 0;
  int Anim_to_square = 0;

  bool isCheck = false;
  bool isCheckMate = false;
  bool isStaleMate = false;
  bool isRep3x = false;
  String gameResult = "";

  bool txtYourMove = false;
  bool txtThinking = false;

  bool goGitHub = false; // if should redirect to GitHub page
  bool goWorkSheet = false; // if should redirect to worksheet page

  // objects of preloaded images of pieces
  ui.Image? wk, wq, wr, wb, wn, wp;
  ui.Image? bk, bq, br, bb, bn, bp;

  // explosion animation
  ui.Image? ex1, ex2, ex3, ex4;
  // buttons
  ui.Image? bNG, bTB, bOw, bFr, bLo, bPG, bGI;
  // texts on screen
  ui.Image? tYM, tTH, tST, tCK, tCM10, tCM01, tRP;
  // a small lamp on-off
  ui.Image? lm1, lm0;

  static const Engine_OWL = 1;
  static const Engine_FRUIT = 2;
  static const Engine_LOUSY = 3;
  int Engine_Selected = Engine_OWL;

  // Chess engines
  late OwlEngine Owl;
  late FruitEngine Fruit;
  late LousyEngine Lousy;
  bool is64bitOK = (((1 << 32) >>> 1) == (1 << 31));

// squares positions
  late List<sqData> sqDatas = [];
  // rectangles for buttons or texts
  late List<sqData> btDatas = [];

  // Various status variables
  int dragSquare = -1;
  List<int> dSquares = [];

  // Game timing and status
  late DateTime startTime;
  final GameController gameController =
      Get.find<GameController>(); // Use GetX to get the controller

  // construct
  PainterHelper() {
    Owl = OwlEngine();
    Fruit = FruitEngine();
    if (is64bitOK) Lousy = LousyEngine();

    int i;
    for (i = 0; i < 64; i++) sqDatas.add(sqData());
    for (i = 0; i <= 7; i++) btDatas.add(sqData());
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
    bool r = repaint;
    repaint = false;
    return r;
  }

  // various functions

  double SqSize() {
    return SquareSize; // The size of square
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
    while (SquareSize < (a + 11) && SquareSize < 90) SquareSize++;
    while (SquareSize > (a - 1) && SquareSize > 30) SquareSize--;
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
    sqDatas[sq].rect = rect;
  }

  saveButTxtRect(int i, ui.Rect rect) {
    btDatas[i].rect = rect;
  }

// take this from OWL engine only
  int pieceColAt(int sq) {
    return Owl.pieceColAt(sq);
  }

  int pieceTypeAt(int sq) {
    return Owl.pieceTypeAt(sq);
  }

  int animCol() {
    return Owl.anm_cl;
  }

  int animType() {
    return Owl.anm_pc - 1;
  }

  String get_MoveslistUcis() {
    return Owl.MoveslistUcis;
  }

  // Gestures

  verifyTap(double x, double y) {
    int i, j;

    if (PauseWait > 0 || AnimTck > 0 || txtThinking) return;

    // verify chess board
    if (Owl.isItMyMove(ImPlayingWhite)) {
      for (i = 0; i < 64; i++) {
        if (isCheckMate || isStaleMate) break;

        sqData Ob = sqDatas[i];

        if ((Ob.rect?.top)! <= y &&
            (Ob.rect?.left)! <= x &&
            (Ob.rect?.bottom)! >= y &&
            (Ob.rect?.right)! >= x) {
          // drag piece on square
          if (dragSquare != i) {
            List<int> Legals = Owl.LegalMovesToSquares(i);
            for (j = 0; j < Legals.length; j++) {
              // can move from here
              if (dragSquare != i) dSquares = [];
              dragSquare = i;
              dSquares.add(Legals[j]);
              repaint = true;
            }
          }

          if (dragSquare != -1) {
            for (j = 0; j < dSquares.length; j++) {
              // can move from here
              if (dSquares[j] == i) {
                // move piece
                AnimToMove(dragSquare, i);
                dragSquare = -1;
                dSquares = [];
                repaint = true;
              }
            }
          }
        }
      }
    }

    // verify buttons

    for (i = 0; i < 7; i++) {
      sqData Ob = btDatas[i];

      if (Ob.rect != null &&
          (Ob.rect?.top)! <= y &&
          (Ob.rect?.left)! <= x &&
          (Ob.rect?.bottom)! >= y &&
          (Ob.rect?.right)! >= x) {
        if (i == 0) NewGame();
        if (i == 1) TakeBack();

        if (i == 2) {
          Engine_Selected = Engine_OWL;
          Owl.LampTck = 20;
          print("Clicked OWL Engine");
        }
        if (i == 3) {
          Engine_Selected = Engine_FRUIT;
          Fruit.LampTck = 20;
          print("Clicked Fruit Engine");
        }
        if (i == 4) {
          Engine_Selected = Engine_LOUSY;
          Lousy.LampTck = 20;
          print("Clicked LOUSY Engine");
        }

        // allow for flutter build web
        if (i == 5) goWorkSheet = false;
        if (i == 6) goGitHub = false;
      }
    }
  }

  // Set animation on
  AnimToMove(fromSq, toSq) {
    AnimTck = AnimTCnt;
    Anim_from_square = fromSq;
    Anim_to_square = toSq;
    Owl.HidePieceSq(fromSq);
  }

  MoveAfterAnimation() {
    Owl.RestorePieceSq();
    Owl.MakeMove(Anim_from_square, Anim_to_square);
    Fruit.MakeMove(Anim_from_square, Anim_to_square);
    if (is64bitOK) Lousy.MakeMove(Anim_from_square, Anim_to_square);
  }

  // Start a new game
  NewGame() {
    dragSquare = -1;
    dSquares = [];

    ImPlayingWhite = !ImPlayingWhite;
    Owl.NewGame();
    Fruit.NewGame();
    if (is64bitOK) Lousy.NewGame();
    repaint = true;
    PauseWait = 10;

    // Reset game time and status message using GetX
    // startTime = DateTime.now();
    // updateGameTime();
    gameController.reset();
  }

  // Take back a move
  TakeBack() {
    dragSquare = -1;
    dSquares = [];

    for (int i = 0; i < 2; i++) {
      Owl.TakeBack();
      Fruit.TakeBack();
      if (is64bitOK) Lousy.TakeBack();
    }
    repaint = true;
    PauseWait = 10;
  }

  // updates text messages
  void updateTexts() {
    String s = Owl.Comment();
    gameResult = "";
    isCheck = (s.contains("Check!"));
    isCheckMate = (s.contains("CheckMate!"));
    isStaleMate = (s.contains("StaleMate!"));
    if (isCheckMate) {
      if (s.contains("1-0")) {
        gameResult = "1-0";
        gameController.updateGameResult("White Wins");
        // gameController.playerDefeated(); // Example to update level on defeat
      }
      if (s.contains("0-1")) {
        gameResult = "0-1";
        gameController.updateGameResult("Black Wins");
        // gameController.playerDefeated(); // Example to update level on defeat
      }
    }
    if (s.contains("1/2")) {
      gameResult = "1/2-1/2";
      gameController.updateGameResult("Draw");
    }
    if (s.contains("Repetition")) isRep3x = true;
  }

  // The main loop on animator.
  gameloop() {
    if (PauseWait > 0) {
      repaint = true;
      PauseWait--;
      if (PauseWait == 3) updateTexts();
      return;
    }
    if (AnimTck > 0) {
      AnimTck--;
      if (AnimTck == 0) {
        MoveAfterAnimation();
        PauseWait = 15;
      }
      repaint = true;
      return;
    }

    if (Owl.LampTck > 0) {
      Owl.LampTck--;
      if (Owl.LampTck == 0) PauseWait = 15;
      repaint = true;
      return;
    }

    if (Fruit.LampTck > 0) {
      Fruit.LampTck--;
      if (Fruit.LampTck == 0) PauseWait = 15;
      repaint = true;
      return;
    }

    if (is64bitOK) {
      if (Lousy.LampTck > 0) {
        Lousy.LampTck--;
        if (Lousy.LampTck == 0) PauseWait = 15;
        repaint = true;
        return;
      }
    }

    if (isCheckMate || isStaleMate) return;

    txtThinking = false;
    txtYourMove = Owl.isItMyMove(ImPlayingWhite);

    if (dragSquare == -1) {
      String a = "";
      if (Engine_Selected == Engine_OWL) a = Owl.Calculate(ImPlayingWhite);
      if (Engine_Selected == Engine_FRUIT) a = Fruit.Calculate(ImPlayingWhite);

      if (Engine_Selected == Engine_LOUSY) {
        a = Lousy.Calculate(ImPlayingWhite);
        if (a.length >= 4) {
          // not sure all moves are ok
          if (!Owl.areMovesOk(a)) {
            Engine_Selected = Engine_OWL;
            a = Owl.Calculate(ImPlayingWhite);
          }
        }
      }

      if (a.length == 1) txtThinking = true;

      if (a.length >= 4) {
        // chess move
        int from_sq = Owl.at2square(a.substring(0, 2));
        int to_sq = Owl.at2square(a.substring(2, 4));
        AnimToMove(from_sq, to_sq);
        txtThinking = false;
      }
      if (a.length > 0) repaint = true;
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
