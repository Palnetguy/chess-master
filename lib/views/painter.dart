import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/game_controller.dart';
import '../helper/painter_helper.dart';
import '../url_launcher_mixin.dart';

//---
//
//  The main canvas CustomPainter.
//  Not the best way to draw, but it works anyway here with limited
//    amounts of drawings. A bunch of chess pieces to draw.
//
//---
//  Preload images and draw canvas
//
class Painter extends StatefulWidget {
  const Painter({
    Key? key,
  }) : super(key: key);

  @override
  State<Painter> createState() => _GameBoardState();
}

//
//    This class defines animation ticker.
//    It is parent level above CustomPainter, just to get it working
//      as main game loop - in FPS manner.
//    Otherwise can't make CustomPainter to refresh anything.
//      setState() there (in listener) initiates
//      an internal call of myPainter.paint()
//
class _GameBoardState extends State<Painter>
    with TickerProviderStateMixin, UrlLauncherMixin {
  PainterHelper PH = PainterHelper(); // create helper object

  late AnimationController animation;

  Future<void> startAnimation() async {
    await animation.forward();
  }

  @override
  void dispose() {
    animation.dispose(); // remove on closing
    super.dispose();
  }

  @override
  void initState() {
    animation = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    animation.addStatusListener((status) {
      // loop forever
      if (status == AnimationStatus.completed) animation.repeat();
    });
    animation.addListener(() {
      if (PH.shouldRepaint()) setState(() {}); // redraw everything
      PH.gameloop(); // Go the main FPS-loop and do what needed.
    });

    startAnimation();

    String A = "assets/images/";
    // preload images from assets
    ldImg(A + "wking.png").then((r) => setState(() => PH.wk = r));
    ldImg(A + "wqueen.png").then((r) => setState(() => PH.wq = r));
    ldImg(A + "wrook.png").then((r) => setState(() => PH.wr = r));
    ldImg(A + "wbishop.png").then((r) => setState(() => PH.wb = r));
    ldImg(A + "wknight.png").then((r) => setState(() => PH.wn = r));
    ldImg(A + "wpawn.png").then((r) => setState(() => PH.wp = r));
    ldImg(A + "bking.png").then((r) => setState(() => PH.bk = r));
    ldImg(A + "bqueen.png").then((r) => setState(() => PH.bq = r));
    ldImg(A + "brook.png").then((r) => setState(() => PH.br = r));
    ldImg(A + "bbishop.png").then((r) => setState(() => PH.bb = r));
    ldImg(A + "bknight.png").then((r) => setState(() => PH.bn = r));
    ldImg(A + "bpawn.png").then((r) => setState(() => PH.bp = r));
    ldImg(A + "expl1.png").then((r) => setState(() => PH.ex1 = r));
    ldImg(A + "expl2.png").then((r) => setState(() => PH.ex2 = r));
    ldImg(A + "expl3.png").then((r) => setState(() => PH.ex3 = r));
    ldImg(A + "expl4.png").then((r) => setState(() => PH.ex4 = r));
    ldImg(A + "red-off-16.png").then((r) => setState(() => PH.lm0 = r));
    ldImg(A + "red-on-16.png").then((r) => setState(() => PH.lm1 = r));
    ldImg(A + "newgame.png").then((r) => setState(() => PH.bNG = r));
    ldImg(A + "takeback.png").then((r) => setState(() => PH.bTB = r));
    ldImg(A + "pgnview.png").then((r) => setState(() => PH.bPG = r));
    ldImg(A + "about.png").then((r) => setState(() => PH.bGI = r));
    ldImg(A + "owl.png").then((r) => setState(() => PH.bOw = r));
    ldImg(A + "fruit.png").then((r) => setState(() => PH.bFr = r));
    ldImg(A + "lousy.png").then((r) => setState(() => PH.bLo = r));
    ldImg(A + "yourmove.png").then((r) => setState(() => PH.tYM = r));
    ldImg(A + "thinking.png").then((r) => setState(() => PH.tTH = r));
    ldImg(A + "stalemate.png").then((r) => setState(() => PH.tST = r));
    ldImg(A + "check.png").then((r) => setState(() => PH.tCK = r));
    ldImg(A + "checkmate_10.png").then((r) => setState(() => PH.tCM10 = r));
    ldImg(A + "checkmate_01.png").then((r) => setState(() => PH.tCM01 = r));
    ldImg(A + "repeating.png").then((r) => setState(() => PH.tRP = r));
    super.initState();
  }

  // Images loading is async. and takes some time (theoretically)
  Future<ui.Image> ldImg(String assetPath) async {
    ByteData bd = await rootBundle.load(assetPath);

    Uint8List bytes = Uint8List.view(bd.buffer);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  }

  // builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double boardSize = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return Center(
            child: CustomPaint(
              size: Size(boardSize, boardSize),
              painter: myPainter(PH: PH),
              child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  myTap(details);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // verify clickables on which square or button pressed
  myTap(TapDownDetails details) {
    PH.verifyTap(details.localPosition.dx, details.localPosition.dy);
    // on redraw will use shared variables
  }
}

//
//    Importantly that this painter class is the main.
//    Others just somehow around drawings.
//

class myPainter extends CustomPainter {
  final GameController gameController = Get.find<GameController>();
  PainterHelper PH;

  myPainter({required this.PH}) {
    PH.CP = this;
  }

  // Just like java applet paint :)
  // This redraws the canvas. When resize or on animator.

  @override
  void paint(Canvas canvas, Size size) {
    PH.canvas = canvas;
    PH.adjustSqSize(size.width.toInt(), size.height.toInt());

    drawBoard();

    drawButtonsTexts();
    if (PH.AnimTck > 0) drawAnim();
  }

  // This paints an image
  void drawImage(Rect rect, ui.Image? img, double scale) {
    Canvas canvas = PH.canvas;
    if (img != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: img,
        scale: scale,
        fit: BoxFit.fill,
      );
    }
  }

  // put all buttons on screen
  void drawButtonsTexts() {
    for (int i = 0; i < 7; i++) {
      bool f = true;
      // Lousy uses 64bits
      if (i == 4 && (!PH.is64bitOK)) f = false;

      //-------if disable url_launcher

      //---- pgn part, not to go to WorkSheet
      //if (i == 5) f = false;
      //---- not to go to GitHub
      //if (i == 6) f = false;

      if (f) drawButtTxt(PH.but_Img(i), i);
    }

    ui.Image? iT;
    var gameStatus = '';

    // position 7 is text
    // if (PH.isRep3x) iT = PH.tRP;

    // if (PH.txtYourMove) iT = PH.tYM;

    // if (PH.isStaleMate) iT = PH.tST;
    // if (PH.isCheck) iT = PH.tCK;
    // if (PH.isCheckMate) iT = (PH.gameResult == "1-0" ? PH.tCM10 : PH.tCM01);

    // if (PH.txtThinking) iT = PH.tTH;
    // if (iT != null) drawButtTxt(iT, 7);

    if (PH.isRep3x) {
      iT = PH.tRP;
      gameStatus = 'Repetition';
    }

    if (PH.txtYourMove) {
      iT = PH.tYM;
      gameStatus = 'Your Move';
    }

    if (PH.isStaleMate) {
      iT = PH.tST;
      gameStatus = 'Stale Mate';
    }

    if (PH.isCheck) {
      iT = PH.tCK;
      gameStatus = 'Check +';
    }
    if (PH.isCheckMate) {
      iT = (PH.gameResult == "1-0" ? PH.tCM10 : PH.tCM01);
      gameStatus = 'Check Mate';
    }

    if (PH.txtThinking) {
      iT = PH.tTH;
      gameStatus = 'Thinking';
    }
    if (iT != null) {
      drawButtTxt(iT, 7);
      // gameController.updateGameResult(gameStatus);
      gameController.drawImageText(iT);
    }
  }

  // chess-board
  void drawBoard() {
    for (int v = 7; v >= 0; v--) for (int h = 0; h < 8; h++) drawSquare(v, h);
  }

  // chess-square
  void drawSquare(int v, int h) {
    Canvas canvas = PH.canvas;
    double sqSize = PH.SqSize();
    int sq = (v << 3) | h;
    if (!PH.ImPlayingWhite) {
      sq = 63 - sq; // flip board
    }

    double x = h * sqSize, y = (7 - v) * sqSize;

    Rect rect0 = Rect.fromLTWH(8 + x, 8 + y, sqSize, sqSize);

    // Draw square background
    canvas.drawRect(
        rect0,
        Paint()
          ..color = PH.isDarkSq(sq)
              ? ui.Color.fromARGB(255, 100, 61, 43)
              : ui.Color.fromARGB(255, 240, 239, 202));

    PH.saveSqRect(sq, rect0);

    int col = PH.pieceColAt(sq);

    // Draw chess piece on it
    if (col != -1) {
      int type = PH.pieceTypeAt(sq);
      ui.Image? img = PH.imgCoTy(col, type);
      double scale = PH.scale(type);
      double imgSz = sqSize * scale;
      // Some ackward adjustables to better fit pieces in square :)
      // Could Gimp litte bit more png-images instead...
      double a = 1 - ((7 - (sqSize / 10)) / 18);

      double X0 = PH.x0(type) * a, Y0 = PH.y0(type) * a;

      Rect rect = Rect.fromLTWH(x + X0, y + Y0, imgSz, imgSz);

      drawImage(rect, img, scale);

      // Drag chess piece
      if (PH.dragSquare == sq) {
        final Paint drag = Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xff0056eb)
          ..strokeWidth = 3.0;

        canvas.drawRect(rect, drag);
      }
    }
    for (int k = 0; k < PH.dSquares.length; k++) {
      if (PH.dSquares[k] == sq) {
        final Paint drag = Paint()
          ..style = PaintingStyle.stroke
          ..color = ui.Color.fromARGB(255, 235, 0, 71)
          ..strokeWidth = 3.0;

        canvas.drawRect(rect0, drag);
      }
    }
  }

  // buttons-square
  void drawButtTxt(ui.Image? img, int I) {
    double sqSize = PH.SqSize();
    double x = 0, y = 0;
    double margin =
        20; // Define a margin to create space between the board and buttons

    // layout
    if (PH.width > PH.height) {
      y = I * sqSize; // Apply margin to vertical position
      x = 8 * sqSize + margin; // Apply margin to horizontal position
    } else {
      y = 8 * sqSize + margin; // Apply margin to vertical position
      x = I * sqSize; // Apply margin to horizontal position
    }

    // Draw a button on it
    double scale = PH.but_scale(I);
    double imgSz = sqSize * scale;

    double a = 1 - ((7 - (sqSize / 10)) / 18);

    double X0 = PH.but_x0(I) * a, Y0 = PH.but_y0(I) * a;

    Rect rect = Rect.fromLTWH(x + X0, y + Y0, imgSz, imgSz);

    drawImage(rect, img, scale);

    if (I == 2 || I == 3 || I == 4) {
      double sc2 = 12 * scale;
      Rect rect2 =
          Rect.fromLTWH(x + (imgSz * 0.55), y + (imgSz * 0.60), sc2, sc2);

      bool Lamp = (I == 2 && (PH.Owl.Tck > 0 || PH.Owl.LampTck > 0)) ||
          (I == 3 && (PH.Fruit.Tck > 0 || PH.Fruit.LampTck > 0)) ||
          (I == 4 && (PH.Lousy.Tck > 0 || PH.Lousy.LampTck > 0));

      ui.Image? img2 = (Lamp ? PH.lm1 : PH.lm0);

      drawImage(rect2, img2, 1);
    }

    PH.saveButTxtRect(I, rect);
    // gameController.drawImageText(img);
  }

  // draw animation of moving piece
  drawAnim() {
    double sqSize = PH.SqSize();

    int sq1 = PH.Anim_from_square;
    int sq2 = PH.Anim_to_square;

    if (!PH.ImPlayingWhite) {
      sq1 = 63 - sq1; // flip board
      sq2 = 63 - sq2;
    }
    int h1 = sq1 & 7, v1 = sq1 >> 3;
    int h2 = sq2 & 7, v2 = sq2 >> 3;

    double tck = 1 - (PH.AnimTck / PH.AnimTCnt);
    double x = h1 * sqSize, y = (7 - v1) * sqSize;
    double dx = (h2 - h1) * sqSize, dy = (v1 - v2) * sqSize;
    dx *= tck;
    dy *= tck;

    int col = PH.animCol();
    int type = PH.animType();
    ui.Image? img = PH.imgCoTy(col, type);
    double scale = PH.scale(type);
    double imgSz = sqSize * scale;

    double a = 1 - ((7 - (sqSize / 10)) / 18);

    double X0 = PH.x0(type) * a, Y0 = PH.y0(type) * a;

    Rect rect = Rect.fromLTWH(x + dx + X0, y + dy + Y0, imgSz, imgSz);

    drawImage(rect, img, scale);

    if (PH.AnimTck < 8) {
      int sq3 = PH.Anim_to_square;
      int col = PH.pieceColAt(sq3);
      if (col != -1) {
        if (PH.AnimTck < 8) img = PH.ex1;
        if (PH.AnimTck < 6) img = PH.ex2;
        if (PH.AnimTck < 4) img = PH.ex3;
        if (PH.AnimTck < 2) img = PH.ex4;
        Rect? rect3 = PH.sqDatas[sq3].rect!;
        drawImage(rect3, img, scale);
      }
    }
  }

  // This allows CustomPainter to redraw, or disallows.
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
