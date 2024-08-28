import "fruit/fruitchess.dart";

class FruitEngine {
  int Tck = 0; // Thinking ticker
  int LampTck = 0; // Selector ticker

  String mlist = "";

  late FruitChess Fru;
  FruitEngine() {
    Fru = FruitChess();
  }

  bool isItMyMove(bool myColorIsWhite) {
    bool isWhiteToMove = ((mlist.length % 10) == 0);
    return (myColorIsWhite == isWhiteToMove);
  }

  String sq2at(int sq) {
    int x = sq & 7, y = sq >> 3;
    return String.fromCharCode(97 + x) + String.fromCharCode(49 + y);
  }

  // move by mouse or tap
  MakeMove(int fromSquare, int toSquare) {
    String ucimove = sq2at(fromSquare) + sq2at(toSquare);
    mlist += "$ucimove ";
  }

  // Do engine shoud make a move? Then calculate and do it.
  // Returns repaint flag.
  String Calculate(bool myColorIsWhite) {
    if (!isItMyMove(myColorIsWhite)) {
      // Should do a move
      //
      if (Tck == 0) Tck = 3;
      // wait little pause for screen update and then start
      if (Tck > 0) {
        if ((--Tck) == 0) {
          if (!Fru.randomopening(mlist)) {
            Fru.do_input("position moves $mlist");

            Fru.do_input("go movetime 4");
          }
          return Fru.bestmv;
        }
        return "*"; // repaint
      }
    }
    return "";
  }

  NewGame() {
    mlist = "";
  }

  TakeBack() {
    if (mlist.isNotEmpty) {
      mlist = mlist.substring(0, mlist.length - 5);
    }
  }
}
