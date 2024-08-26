import "owl/owlchess.dart";

class OwlEngine {
  late OWL owl;

  int Tck = 0; // Thinking ticker
  int LampTck = 0; // Selector ticker

  // save piece and color before movement from square
  int anm_sq = -1, anm_pc = 0, anm_cl = 0;

  String MoveslistUcis = ""; // contains uci list of moves for web link

  OwlEngine() {
    owl = OWL();
    MAXPLY = 4;
    MAXSECS = 4;

    // randomize more
    int roll_rnd = DateTime.now().second << 2;
    while ((roll_rnd--) > 0) OWL.rnd.nextInt(1);
  }

  int toOwlSquare(int sq) {
    int v = sq >>> 3, h = sq & 7;
    return (v << 4) + h;
  }

  int fromOwlSquare(int owlsq) {
    int v = owlsq >>> 4, h = owlsq & 7;
    return (v << 3) + h;
  }

  int pieceColAt(int sq) {
    BOARDTYPE o = owl.Board[toOwlSquare(sq)];
    return (o.piece == 0 ? -1 : o.color);
  }

  int pieceTypeAt(int sq) {
    BOARDTYPE o = owl.Board[toOwlSquare(sq)];
    return (o.piece - 1);
  }

  bool isItMyMove(bool myColorIsWhite) {
    return ((myColorIsWhite ? 0 : 1) == owl.Player);
  }

  int at2square(String at) {
    int h = at.codeUnits[0] - 97;
    int v = at.codeUnits[1] - 49;
    return (v << 3) | h;
  }

// returns legal moves from square
  List<int> LegalMovesToSquares(int fromSquare) {
    int sq = toOwlSquare(fromSquare);

    List<int> legals = [];
    owl.InitMovGen();
    for (int i = 0; i < owl.BufCount; i++) {
      owl.MovGen();
      if (!owl.IllegalMove(owl.Next)) {
        if (sq == owl.Next.old) {
          legals.add(fromOwlSquare(owl.Next.nw1));
        }
      }
    }

    return legals;
  }

  // move by mouse or tap
  MakeMove(int fromSquare, int toSquare) {
    int f = toOwlSquare(fromSquare), t = toOwlSquare(toSquare);
    String from = owl.sq2str(f), to = owl.sq2str(t);
    String ucimove = from + to;
    owl.DoMoveByStr(ucimove);
    MoveslistUcis += ucimove + "_";
  }

  // Do engine shoud make a move? Then calculate and do it.
  // Returns repaint flag.
  String Calculate(bool myColorIsWhite) {
    if ((myColorIsWhite ? 0 : 1) == owl.Opponent) {
      // Should do a move
      //
      if (Tck == 0) Tck = 3;
      // wait little pause for screen update and then start
      if (Tck > 0) {
        if ((--Tck) == 0) {
          String foundmove = owl.FindOpeningMove(); // openings or...

          if (!owl.LibFound) {
            foundmove = owl.FindMove(); // let the engine search
          }

          if (foundmove.length > 0) {
            // style g7-g8=Q
            return foundmove;
          }
        }
        return "*"; // repaint
      }
    }
    return "";
  }

  // a small workaround for animation
  HidePieceSq(int sq) {
    anm_sq = toOwlSquare(sq);
    var O = owl.Board[anm_sq];
    anm_pc = O.piece;
    anm_cl = O.color;
    O.piece = 0;
    O.color = 0;
  }

  RestorePieceSq() {
    var O = owl.Board[anm_sq];
    O.piece = anm_pc;
    O.color = anm_cl;
    anm_sq = -1;
  }

  NewGame() {
    owl.ResetGame();
    MoveslistUcis = "";
  }

  TakeBack() {
    if (owl.mc > 1) {
      owl.UndoMove();
      MoveslistUcis = MoveslistUcis.substring(0, MoveslistUcis.length - 5);
    }
  }

  String Comment() {
    return owl.Comment();
  }

  bool areMovesOk(String ucimove) {
    int fsq = at2square(ucimove.substring(0, 2));
    int tsq = at2square(ucimove.substring(2, 4));
    int f = toOwlSquare(fsq);
    int t = toOwlSquare(tsq);

    owl.InitMovGen();
    for (int i = 0; i < owl.BufCount; i++) {
      owl.MovGen();
      if (owl.Next.old == f &&
          owl.Next.nw1 == t &&
          !owl.IllegalMove(owl.Next)) {
        return true;
      }
    }

    return false;
  }
}
