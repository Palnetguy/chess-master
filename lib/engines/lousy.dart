import "lousy/lousychess.dart";
import "lousy/chessopenings.dart";

class LousyEngine {
  late Engine engine;
  late Board Bo; // chess board
  late MoveGenerator MG; // movegenerator
  late SearchMove ss; // searcher

  late c0_openings Opn;

  int Tck = 0; // Thinking ticker
  int LampTck = 0; // Selector ticker

  String mlist = "";

  LousyEngine() {
    engine = Engine();
    Bo = engine.board;
    MG = Bo.moveGenerator;
    ss = engine.searchMove;

    SEARCH_DEPTH = 3;
    SEARCH_SECONDS = 4;

    Opn = c0_openings();

    // randomize more
    int rollRnd = DateTime.now().second << 2;
    while ((rollRnd--) > 0) {
      BitBoard.rnd.nextInt(1);
    }
  }

  bool isItMyMove(bool myColorIsWhite) {
    return ((myColorIsWhite ? Const.White : Const.Black) == Bo.colorToMove);
  }

  // returns legal moves from square
  List<int> LegalMovesToSquares(int fromSquare) {
    List<int> legals = [];

    MG.GenerateMoves([]);
    var moves = MG.movelist;

    for (int j = 0; j < moves.length; j++) {
      Move m = moves[j];
      if (m.fromPosition == fromSquare) {
        Bo.MakeMove(m);
        Bo.colorToMove ^= 1;
        Bo.enemyColor ^= 1;
        bool f = !Bo.IsInCheck();
        Bo.colorToMove ^= 1;
        Bo.enemyColor ^= 1;
        Bo.UnMakeMove(m);
        if (f) {
          legals.add(m.toPosition);
        }
      }
    }
    return legals;
  }

  String sq2at(int sq) {
    int x = sq & 7, y = sq >> 3;
    return String.fromCharCode(97 + x) + String.fromCharCode(49 + y);
  }

  // move by mouse or tap
  MakeMove(int fromSquare, int toSquare) {
    String ucimove = sq2at(fromSquare) + sq2at(toSquare);
    Move mv = Bo.FindMoveOnBoard(ucimove);
    Bo.MakeMove(mv);
    mlist += ucimove;
  }

  // Do engine shoud make a move? Then calculate and do it.
  // Returns repaint flag.
  String Calculate(bool myColorIsWhite) {
    if ((myColorIsWhite ? Const.White : Const.Black) == Bo.enemyColor) {
      // Should do a move
      //
      if (Tck == 0) Tck = 3;
      // wait little pause for screen update and then start
      if (Tck > 0) {
        if ((--Tck) == 0) {
          String foundmove = Opn.c0_Opening(mlist); // openings or...

          if (foundmove.isEmpty) {
            ss.FindBestMove(); // let the engine search
            foundmove = ss.EngineResults.bestmovestring;
            print(foundmove);
          }

          if (foundmove.isNotEmpty) {
            // style g7-g8=Q
            return foundmove;
          }
        }
        return "*"; // repaint
      }
    }
    return "";
  }

  NewGame() {
    engine.SetupInitialBoard(true);
    mlist = "";
  }

  TakeBack() {
    if (mlist.isNotEmpty) {
      Bo.UnMakeMove(Bo.movesHist[Bo.movesHist.length - 1]);
      mlist = mlist.substring(0, mlist.length - 4);
    }
  }
}
