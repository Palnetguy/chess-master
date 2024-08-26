/*
A dart port of
 OWL CHESS written in Borland Turbo C (year 1992-95)
done by http://chessforeva.blogspot.com (03.2024)

It is good 32-bit chess engine, none of Uint64 variables.
Javascript VM likes it.

Usage:
  OWL owl = OWL();
  owl.playSampleAIvsAI();

*/

//   Dart randomizer may give same results, so an ackward
//    n-seconds-loop solves it.

import 'dart:math';

import 'owlbook.dart';

int MAXPLY = 6; // max.ply
int MAXSECS = 8; // max.seconds to search

class MOVETYPE //struct
{
  int nw1 = 0, old = 0; /*  new and old square  */
  bool spe = false;
  /*  Indicates special move:
    case movepiece of
      king: castling
      pawn: e.p. capture
      else : pawn promotion  */
  int movpiece = 0; /* moving piece */
  int content = 0; /* evt. captured piece  */
}

class BOARDTYPE {
  int piece = 0, color = 0, index = 0, attacked = 0;
}

class PIECETAB {
  int isquare = 0, ipiece = 0;
}

class CASTTYPE {
  int castsquare = 0, cornersquare = 0;
}

class ATTACKTABTYPE {
  /*  A set of king..pawn.  gives the pieces, which can move to the square */
  int pieceset = 0;
  int direction = 0; /*  The direction from the piece to the square  */
}

class CSTPE {
  int castnew = 0, castold = 0;

  CSTPE(int n, int o) {
    castnew = n;
    castold = o;
  }
}

class PAWNBITTYPE {
  int one = 0, dob = 0;
}

class TIMERTYPE {
  DateTime started = DateTime.now();
  int elapsed = 0;
}

class INFTYPE {
  bool principv = false; /*  Principal variation search  */
  int value = 0; /*  Static incremental evaluation  */
  int evaluation = 0; /*  Evaluation of position */
}

class MLINE {
  late List<MOVETYPE> a = [];
  MLINE() {
    int i = 0;
    while ((i++) < MAXPLY + 2) a.add(MOVETYPE());
  }
}

class SEARCHTYPE {
  MLINE line = MLINE(); /*  best line at next ply  */
  bool capturesearch = false; /*  indicates capture search  */
  int maxval = 0; /*  maximal evaluation returned in search */
  int nextply = 0; /*  Depth of search at next ply  */
  INFTYPE next = INFTYPE(); /* information at Next ply  */
  bool zerowindow = false; /*  Zero-width alpha-beta-window  */
  int movgentype = 0;
}

class PARAMTYPE {
  int alpha = 0, beta = 0, ply = 0;
  INFTYPE inf = INFTYPE();
  MLINE bestline = MLINE();
  SEARCHTYPE S = SEARCHTYPE();
}

class OWL {
  static const int InitialSeed = 12345;
  static Random rnd = Random(InitialSeed);

/* constants and globals */
  static const int empty = 0,
      king = 1,
      queen = 2,
      rook = 3,
      bishop = 4,
      knight = 5,
      pawn = 6; // pieces
  static const int white = 0, black = 1; // colours
  static const int zero = 0, lng = 1, shrt = 2; // castlings

  int Player = white;
  int Opponent = black; // Side to move, opponent
  int ProgramColor = white; // AI side

  static const List<int> Pieces = [
    rook,
    knight,
    bishop,
    queen,
    king,
    bishop,
    knight,
    rook
  ]; // [8]

  var PieceTab = [[], []];
  var Board = List.filled(0x78, BOARDTYPE()); // [0x78]

  List<MOVETYPE> MovTab = [];
  int mc = 0; // count of moves

  late MOVETYPE Mo; // pointer to MovTab[mc] - current move
  late MOVETYPE Mpre; // pointer to MovTab[mc-1] - previous move by opponent

  var OfficerNo = [];
  var PawnNo = []; // 2

  int UseLib = 200;

  int Depth =
      1; // search current depth (originally Depth starts from 0)  1..MAXPLY
  List<ATTACKTABTYPE> AttackTab = [];
  static const BitTab = [0, 1, 2, 4, 8, 0x10, 0x20]; // [7]
  static const DirTab = [1, -1, 0x10, -0x10, 0x11, -0x11, 0x0f, -0x0f]; // [8]
  static const KnightDir = [
    0x0E,
    -0x0E,
    0x12,
    -0x12,
    0x1f,
    -0x1f,
    0x21,
    -0x21
  ]; // [8]
  static const PawnDir = [0x10, -0x10]; // [2]
  int BufCount = 0;
  int BufPnt = 0;
  late MOVETYPE Next;
  List<MOVETYPE> Buffer = [];
  var ZeroMove = MOVETYPE();

  static const int LOSEVALUE = 0x7D00, MATEVALUE = 0x7C80, DEPTHFACTOR = 0x80;

  int MainEvalu = 0;

  // [2][2] of new,old squares
  var CastMove = [
    [CSTPE(2, 4), CSTPE(6, 4)],
    [CSTPE(0x72, 0x74), CSTPE(0x76, 0x74)]
  ];

  String substr(String s, int from, int len) {
    return s.substring(from, from + len);
  }

  InsertPiece(int p, int c, int sq) {
    var O = Board[sq];
    O.piece = p;
    O.color = c;
  }

  ResetMoves() {
    mc = 1;
    MovTab = [MOVETYPE(), MOVETYPE(), MOVETYPE()];
    Mo = MovTab[mc];
    Mpre = MovTab[mc - 1];
  }

  ClearBoard() {
    for (int sq = 0; sq <= 0x77; sq++) Board[sq] = BOARDTYPE();
  }

/*
 *  Clears indexes in board and piecetab
 */

  ClearIndex() {
    var square, col, index;

    for (square = 0; square <= 0x77; square++) Board[square].index = 16;
    for (col = white; col <= black; col++) {
      PieceTab[col] = [];
      for (index = 0; index <= 16; index++) PieceTab[col].add(PIECETAB());
    }

    OfficerNo = [-1, -1];
    PawnNo = [-1, -1];
  }

/*
 *  Calcualates Piece table from scratch
 */

  CalcPieceTab() {
    var square, piece1, o, p, w, q;

    ClearIndex();

    for (piece1 = king; piece1 <= pawn; piece1++) {
      if (piece1 == pawn) {
        OfficerNo[white] = PawnNo[white];
        OfficerNo[black] = PawnNo[black];
      }
      square = 0;
      do {
        o = Board[square];
        if (o.piece == piece1) {
          w = o.color;
          PawnNo[w]++;
          p = PawnNo[w];
          q = PieceTab[w][p];
          q.ipiece = piece1;
          q.isquare = square;
          o.index = p;
        }
        square ^= 0x77;
        if ((square & 4) == 0) {
          if (square >= 0x70)
            square = (square + 0x11) & 0x73;
          else
            square += 0x10;
        }
      } while (square != 0);
    }
  }

  ResetGame() {
    ClearBoard();
    for (var i = 0; i < 8; i++) {
      InsertPiece(Pieces[i], white, i);
      InsertPiece(pawn, white, i + 0x10);
      InsertPiece(pawn, black, i + 0x60);
      InsertPiece(Pieces[i], black, i + 0x70);
    }
    CalcPieceTab();
    Player = white;
    Opponent = black; // Side to move, opponent
    ResetMoves();
    UseLib = 200;
  }

  MOVETYPE cloneMove(MOVETYPE m) {
    MOVETYPE n = MOVETYPE();
    n.nw1 = m.nw1;
    n.old = m.old;
    n.spe = m.spe;
    n.movpiece = m.movpiece;
    n.content = m.content;
    return n;
  }

  copyMove(MOVETYPE t, MOVETYPE f) {
    t.nw1 = f.nw1;
    t.old = f.old;
    t.spe = f.spe;
    t.movpiece = f.movpiece;
    t.content = f.content;
  }

  /* === MOVEGEN === */

  CalcAttackTab() {
    int dir, i;
    var o;

    for (i = 0; i <= (120 + 0x77); i++) AttackTab.add(ATTACKTABTYPE());
    for (dir = 7; dir >= 0; dir--) {
      for (i = 1; i < 8; i++) {
        o = AttackTab[120 + (DirTab[dir] * i)];
        o.pieceset = BitTab[queen] + BitTab[(dir < 4 ? rook : bishop)];
        o.direction = DirTab[dir];
      }
      o = AttackTab[120 + DirTab[dir]];
      o.pieceset += BitTab[king];
      o = AttackTab[120 + KnightDir[dir]];
      o.pieceset = BitTab[knight];
      o.direction = KnightDir[dir];
    }
  }

/*
 *  calculate whether apiece placed on asquare attacks the square
 */

  bool PieceAttacks(int apiece, int acolor, int asquare, int square) {
    int x = square - asquare;
    if (apiece == pawn) /*  pawn attacks  */
      return ((x - PawnDir[acolor]).abs() == 1);

    /*  other attacks: can the piece move to the square?  */
    else if ((AttackTab[120 + x].pieceset & BitTab[apiece]) != 0) {
      if (apiece == king || apiece == knight)
        return true;
      else {
        /*  are there any blocking pieces in between?  */
        var sq = asquare;
        do {
          sq += AttackTab[120 + x].direction;
        } while (sq != square && Board[sq].piece == empty);
        return (sq == square);
      }
    } else
      return false;
  }

/*
 *  calculate whether acolor attacks the square with at pawn
 */

  bool PawnAttacks(int acolor, int square) {
    var o, sq = square - PawnDir[acolor] - 1; /*  left square  */
    if ((sq & 0x88) == 0) {
      o = Board[sq];
      if (o.piece == pawn && o.color == acolor) return true;
    }
    sq += 2; /*  right square  */
    if ((sq & 0x88) == 0) {
      o = Board[sq];
      if (o.piece == pawn && o.color == acolor) return true;
    }
    return false;
  }

/*
 *  Calculates whether acolor attacks the square
 */

  bool Attacks(int acolor, int square) {
    if (PawnAttacks(acolor, square)) /*  pawn attacks  */
      return true;
    /*  Other attacks:  try all pieces, starting with the smallest  */
    for (var i = OfficerNo[acolor]; i >= 0; i--) {
      var o = PieceTab[acolor][i];
      if (o.ipiece != empty) if (PieceAttacks(
          o.ipiece, acolor, o.isquare, square)) return true;
    }
    return false;
  }

  /*
 *  check whether inpiece is placed on square and has never moved
 */

  bool Check(int square, int inpiece, int incolor) {
    var o = Board[square];
    if (o.piece == inpiece && o.color == incolor) {
      var dep = mc - 1;
      while (dep >= 0 && MovTab[dep].movpiece != empty) {
        if (MovTab[dep].nw1 == square) return false;
        dep--;
      }
      return true;
    }
    return false;
  }

/*
 *  Calculate whether incolor can castle
 */

  int CalcCastling(int incolor) {
    var square = 0, cast = zero;

    if (incolor == black) square = 0x70;
    if (Check(square + 4, king, incolor)) /*  check king  */
    {
      if (Check(square, rook, incolor)) cast += lng; /*  check a-rook  */
      if (Check(square + 7, rook, incolor)) cast += shrt; /*  check h-rook  */
    }
    return cast;
  }

/*
 *  check if move is a pawn move or a capture
 */

  bool RepeatMove(MOVETYPE move) {
    return (move.movpiece != empty &&
        move.movpiece != pawn &&
        move.content == empty &&
        !move.spe);
  }

/*
 *  Count the number of moves since last capture or pawn move
 *  The game is a draw when fiftymovecnt = 100
 */

  int FiftyMoveCnt() {
    var cnt = 0;
    while (RepeatMove(MovTab[mc - cnt])) cnt++;
    return cnt;
  }

/*
 *  Calculate how many times the move has occurred before
 *  The game is a draw when repetition = 3
 *  MovTab contains the previous moves
 *  When immediate is set, only immediate repetition is checked
 */

  int Repetition(bool immediate) {
    var lastdep,
        compdep,
        tracedep,
        checkdep,
        samedepth,
        tracesq,
        checksq,
        repeatcount,
        o;

    repeatcount = 1;
    lastdep = mc; /*  current position  */
    samedepth = lastdep;
    compdep = samedepth - 4; /*  First position to compare  */

    /*  MovTab contains previous relevant moves  */
    while (RepeatMove(MovTab[lastdep - 1]) && (compdep < lastdep || !immediate))
      lastdep--;
    if (compdep < lastdep) return 1;
    checkdep = samedepth;
    for (;;) {
      checkdep--;
      checksq = MovTab[checkdep].nw1;
      bool f = true;
      for (tracedep = checkdep + 2; tracedep < samedepth; tracedep += 2)
        if (MovTab[tracedep].old == checksq) {
          f = false;
          break;
        }

      if (f) {
        /*  Trace the move backward to see if it has been 'undone' earlier  */
        tracedep = checkdep;
        tracesq = MovTab[tracedep].old;
        do {
          if (tracedep - 2 < lastdep) return repeatcount;
          tracedep -= 2;
          /*  Check if piece has been moved before  */
          o = MovTab[tracedep];
          if (tracesq == o.nw1) tracesq = o.old;
        } while (tracesq != checksq || tracedep > compdep + 1);
        if (tracedep < compdep) /*  Adjust evt. compdep  */
        {
          compdep = tracedep;
          if ((samedepth - compdep) % 2 == 1) {
            if (compdep == lastdep) return repeatcount;
            compdep--;
          }
          checkdep = samedepth;
        }
      }

      /*  All moves between SAMEDEP and compdep have been checked,
            so a repetition is found  */
//TEN :
      if (checkdep <= compdep) {
        repeatcount++;
        if (compdep - 2 < lastdep) return repeatcount;
        checkdep = samedepth = compdep;
        compdep -= 2;
      }
    }
  }

/*
 *  Test whether a move is possible
 *
 *  On entry:
 *    Move contains a full description of a move, which
 *    has been legally generated in a different position.
 *    MovTab[mc] contains last performed move.
 *
 *  On exit:
 *    KillMovGen indicates whether the move is possible
 */

  bool KillMovGen(MOVETYPE move) {
    int castsq, promote = 0, castdir, cast = 0;
    var q;
    bool killmov = false;

    if (move.spe && (move.movpiece == king)) {
      cast = CalcCastling(Player); /*  Castling  */
      castdir = ((move.nw1 > move.old) ? shrt : lng);

      if ((cast & castdir) != 0) /*  Has king or rook moved before  */
      {
        castsq = ((move.nw1 + move.old) >>> 1);
        /*  Are the squares empty ?  */
        if (Board[move.nw1].piece == empty) if (Board[castsq].piece ==
            empty) if ((move.nw1 >
                move.old) ||
            (Board[move.nw1 - 1].piece == empty))
        /*  Are the squares unattacked  */
        if (!Attacks(Opponent, move.old)) if (!Attacks(
            Opponent, move.nw1)) if (!Attacks(Opponent, castsq)) killmov = true;
      }
    } else {
      if (move.spe && (move.movpiece == pawn)) {
        /*  E.p. capture  */
        /*  Was the Opponent's move a 2 square move?  */
        if (Mpre.movpiece == pawn) if ((Mpre.nw1 - Mpre.old).abs() >= 0x20) {
          q = Board[move.old];
          if ((q.piece == pawn) && (q.color == Player))
            killmov = (move.nw1 == ((Mpre.nw1 + Mpre.old) >>> 1));
        }
      } else {
        if (move.spe) /*  Normal test  */
        {
          promote = move.movpiece; /*  Pawnpromotion  */
          move.movpiece = pawn;
        }

        /*  Is the content of Old and nw1 squares correct?  */
        if (Board[move.old].piece == move.movpiece) if (Board[move.old].color ==
            Player) if (Board[move.nw1].piece == move.content) if (move
                    .content ==
                empty ||
            Board[move.nw1].color == Opponent) {
          if (move.movpiece == pawn) /*  Is the move possible?  */
          {
            if ((move.nw1 - move.old).abs() < 0x20)
              killmov = true;
            else
              killmov = Board[(move.nw1 + move.old) >>> 1].piece == empty;
          } else
            killmov = PieceAttacks(move.movpiece, Player, move.old, move.nw1);
        }
        if (move.spe) move.movpiece = promote;
      }
    }
    return killmov;
  }

/*
 *  Store a move in buffer
 */

  Generate() {
    while (Buffer.length <= (BufCount + 1)) Buffer.add(MOVETYPE());
    Buffer[++BufCount] = cloneMove(Next); /* new copied MOVETYPE() */
  }

/*
 *  Generates pawn promotion
 */

  PawnPromotionGen() {
    Next.spe = true;
    for (int promote = queen; promote <= knight; promote++) {
      Next.movpiece = promote;
      Generate();
    }
    Next.spe = false;
  }

/*
 *  Generates captures of the piece on nw1 using PieceTab
 */

  CapMovGen() {
    var nextsq, sq, i, o, p;

    Next.spe = false;
    Next.content = Board[Next.nw1].piece;
    Next.movpiece = pawn;
    nextsq = Next.nw1 - PawnDir[Player];
    for (sq = nextsq - 1; sq <= nextsq + 1; sq++)
      if (sq != nextsq) if ((sq & 0x88) == 0) {
        o = Board[sq];
        if (o.piece == pawn && o.color == Player) {
          Next.old = sq;
          if (Next.nw1 < 8 || Next.nw1 >= 0x70)
            PawnPromotionGen();
          else
            Generate();
        }
      }
    /*  Other captures, starting with the smallest pieces  */
    for (i = OfficerNo[Player]; i >= 0; i--) {
      o = PieceTab[Player][i];
      p = o.ipiece;
      if (p != empty &&
          p != pawn) if (PieceAttacks(p, Player, o.isquare, Next.nw1)) {
        Next.old = o.isquare;
        Next.movpiece = p;
        Generate();
      }
    }
  }

/*
 *  generates non captures for the piece on old
 */

  NonCapMovGen() {
    var first, last, dir, direction, newsq;

    Next.spe = false;
    Next.movpiece = Board[Next.old].piece;
    Next.content = empty;
    switch (Next.movpiece) {
      case king:
        for (dir = 7; dir >= 0; dir--) {
          newsq = Next.old + DirTab[dir];
          if ((newsq & 0x88) == 0) if (Board[newsq].piece == empty) {
            Next.nw1 = newsq;
            Generate();
          }
        }
        break;
      case knight:
        for (dir = 7; dir >= 0; dir--) {
          newsq = Next.old + KnightDir[dir];
          if ((newsq & 0x88) == 0) if (Board[newsq].piece == empty) {
            Next.nw1 = newsq;
            Generate();
          }
        }
        break;
      case queen:
      case rook:
      case bishop:
        first = 7;
        last = 0;
        if (Next.movpiece == rook) first = 3;
        if (Next.movpiece == bishop) last = 4;
        for (dir = first; dir >= last; dir--) {
          direction = DirTab[dir];
          newsq = Next.old + direction;
          /*  Generate all non captures in the direction  */
          while ((newsq & 0x88) == 0) {
            if (Board[newsq].piece != empty) break;
            Next.nw1 = newsq;
            Generate();
            newsq = Next.nw1 + direction;
          }
        }
        break;
      case pawn:
        Next.nw1 = Next.old + PawnDir[Player]; /*  one square forward  */
        if (Board[Next.nw1].piece == empty) {
          if (Next.nw1 < 8 || Next.nw1 >= 0x70)
            PawnPromotionGen();
          else {
            Generate();
            if (Next.old < 0x18 || Next.old >= 0x60) {
              Next.nw1 += (Next.nw1 - Next.old); /* 2 squares forward */
              if (Board[Next.nw1].piece == empty) Generate();
            }
          }
        }
    } /* switch */
  }

  /*
 *  The move generator.
 *  InitMovGen generates all possible moves and places them in a buffer.
 *  Movgen will the generate the moves one by one and place them in next.
 *
 *  On entry:
 *    Player contains the color to move.
 *    MovTab[mc-1] the last performed move.
 *
 *  On exit:
 *    Buffer contains the generated moves.
 *
 *    The moves are generated in the order :
 *      Captures
 *      Castlings
 *      Non captures
 *      E.p. captures
 */

  InitMovGen() {
    var castdir, sq, index, o;
    Next = MOVETYPE();
    Buffer = [];
    BufCount = 0;
    BufPnt = 0;
    /*  generate all captures starting with captures of
        largest pieces  */
    for (index = 1; index <= PawnNo[Opponent]; index++) {
      o = PieceTab[Opponent][index];
      if (o.ipiece != empty) {
        Next.nw1 = o.isquare;
        CapMovGen();
      }
    }
    Next.spe = true;
    Next.movpiece = king;
    Next.content = empty;
    for (castdir = (lng - 1); castdir <= shrt - 1; castdir++) {
      o = CastMove[Player][castdir];
      Next.nw1 = o.castnew;
      Next.old = o.castold;
      if (KillMovGen(Next)) Generate();
    }

    /*  generate non captures, starting with pawns  */
    for (index = PawnNo[Player]; index >= 0; index--) {
      o = PieceTab[Player][index];
      if (o.ipiece != empty) {
        Next.old = o.isquare;
        NonCapMovGen();
      }
    }

    if (Mpre.movpiece == pawn) /*  E.p. captures  */
    if ((Mpre.nw1 - Mpre.old).abs() >= 0x20) {
      Next.spe = true;
      Next.movpiece = pawn;
      Next.content = empty;
      Next.nw1 = (Mpre.nw1 + Mpre.old) >>> 1;
      for (sq = Mpre.nw1 - 1; sq <= Mpre.nw1 + 1; sq++)
        if (sq != Mpre.nw1) if ((sq & 0x88) == 0) {
          Next.old = sq;
          if (KillMovGen(Next)) Generate();
        }
    }
  }

/*
 *  place next move from the buffer in next.  Generate zeromove when there
 *  are no more moves.
 */

  MovGen() {
    if (BufPnt >= BufCount)
      Next = ZeroMove;
    else {
      Next = Buffer[++BufPnt];
    }
  }

/*
 *  Test if the move is legal for color == player in the
 *  given position
 */

  IllegalMove(MOVETYPE move) {
    Perform(move, false);
    var illegal = Attacks(Opponent, PieceTab[Player][0].isquare);
    Perform(move, true);
    return illegal;
  }

/*
 *  Prints comment to the game (check, mate, draw, resign)
 */

  Comment() {
    var s = "";
    bool check = false, possiblemove = false, checkmate = false;

    InitMovGen();
    for (var i = 0; i < BufCount; i++) {
      MovGen();
      if (!IllegalMove(Next)) {
        possiblemove = true;
        break;
      }
    }

    check = Attacks(Opponent, PieceTab[Player][0].isquare); //calculate check
    //  No possible move means checkmate or stalemate
    if (!possiblemove) {
      if (check) {
        checkmate = true;
        s += "CheckMate! " + (Opponent == white ? "1-0" : "0-1");
      } else
        s += "StaleMate! 1/2-1/2";
    } else if (MainEvalu >= MATEVALUE - DEPTHFACTOR * 16) {
      var nummoves = ((MATEVALUE - MainEvalu + 0x40) ~/ (DEPTHFACTOR * 2));
      if (nummoves > 0)
        s += "Mate in " +
            nummoves.toString() +
            " move" +
            ((nummoves > 1) ? "s" : "") +
            "!";
    }
    if (check && !checkmate)
      s += "Check!";
    else //test 50 move rule and repetition of moves
    {
      if (FiftyMoveCnt() >= 100) {
        s += "50 Move rule";
      } else if (Repetition(false) >= 3) {
        s += "3 fold Repetition";
      } else //Resign if the position is hopeless
      if (Opponent == ProgramColor &&
          (-25500 < MainEvalu && MainEvalu < -0x880)) {
        s += (Opponent == white ? "White" : "Black") + " resigns";
      }
    }
    return s;
  }

  String CHR(int n) {
    return String.fromCharCode(n);
  }

  String sq2str(int square) {
    return CHR(97 + (square & 7)) + CHR(49 + (square >>> 4));
  }

/*
 *  convert a move to a string
 */

  String MoveStr(MOVETYPE move) {
    if (move.movpiece != empty) {
      if (move.spe && move.movpiece == king) /*  castling  */
      {
        return "O-O" + ((move.nw1 > move.old) ? "" : "-O");
      } else {
        var s = "", piece = Board[move.old].piece, ispawn = (piece == pawn);
        var c = (move.content != 0) ||
            (ispawn && ((move.nw1 - move.old) - 0x10).abs() == 1);
        var p = ispawn && move.movpiece < 6;
        if (!ispawn) s += (" KQRBN")[move.movpiece];
        s += sq2str(move.old);
        s += (c ? 'x' : '-');
        s += sq2str(move.nw1);
        if (p) s += "=" + ("QRBN")[move.movpiece - 2];
        return s;
      }
    }
    return "?";
  }

// generates string of possible moves,
// does not include check,checkmate,stalemate flags
  GenMovesStr() {
    var s = "";
    InitMovGen();
    for (var i = 0; i < BufCount; i++) {
      MovGen();
      if (!IllegalMove(Next)) s += "," + MoveStr(Next);
    }
    ;
    return s.substring(1);
  }

  log_print(String s) {
    print(s);
  }

  printboard() {
    for (var v = 8; (--v) >= 0;) {
      var s = "";
      for (var h = 0; h < 8; h++) {
        var o = Board[(v << 4) + h], p = (".kqrbnp")[o.piece];
        if (o.color == white) p = p.toUpperCase();
        s += p;
      }
      log_print(s);
    }
  }

/* === DO MOVE, UNDO MOVE === */

/*
 *  move a piece to a new location on the board
 */

  MovePiece(int nw1, int old) {
    var n = Board[nw1], o = Board[old];
    Board[nw1] = o;
    Board[old] = n;
    PieceTab[o.color][o.index].isquare = nw1;
  }

/*
 *  Calculate the squares for the rook move in castling
 */

  GenCastSquare(int nw1, CASTTYPE Cast) {
    if ((nw1 & 7) >= 4) /* short castle */
    {
      Cast.castsquare = nw1 - 1;
      Cast.cornersquare = nw1 + 1;
    } else /* long castle */
    {
      Cast.castsquare = nw1 + 1;
      Cast.cornersquare = nw1 - 2;
    }
  }

/*
 *  This function used in captures.  insquare must not be empty.
 */

  DeletePiece(int insquare) {
    var o = Board[insquare];
    o.piece = empty;
    PieceTab[o.color][o.index].ipiece = empty;
  }

/*
 *  Take back captures
 */

  InsertPTabPiece(int inpiece, int incolor, int insquare) {
    var o = Board[insquare], q = PieceTab[incolor][o.index];
    o.piece = inpiece;
    q.ipiece = inpiece;
    o.color = incolor;
    q.isquare = insquare;
  }

/*
 *  Used for pawn promotion
 */

  ChangeType(int newtype, int insquare) {
    var o = Board[insquare];
    o.piece = newtype;
    PieceTab[o.color][o.index].ipiece = newtype;
    if (OfficerNo[o.color] < o.index) OfficerNo[o.color] = o.index;
  }

/*
 Do move
*/
  DoMove(MOVETYPE move) {
    Perform(move, false);
    Player ^= 1;
    Opponent ^= 1;
  }

/*
 Undo move
*/
  UndoMove() {
    Player ^= 1;
    Opponent ^= 1;
    unPerform();
  }

/*
 *  Perform or take back move (takes back if resetmove is true),
 *  and perform the updating of Board and PieceTab.  Player must
 *  contain the color of the moving player, Opponent the color of the
 *  Opponent.
 *
 *  MovePiece, DeletePiece, InsertPTabPiece and ChangeType are used to update
 *  the Board module.
 */

  int sqByAt(String square) {
    return ((square.codeUnits[0] - 97) + (0x10 * (square.codeUnits[1] - 49)));
  }

  String DoMoveByStr(String mstr) {
    var ret = "";
    var old = sqByAt(substr(mstr, 0, 2)), nw1 = sqByAt(substr(mstr, 2, 2));
    InitMovGen();
    for (var i = 0; i < BufCount; i++) {
      MovGen();
      if (Next.old == old &&
          Next.nw1 == nw1 &&
          (mstr.length < 5 ||
              (Next.spe && ("qrbn").indexOf(mstr[4]) == Next.movpiece - 2))) {
        ret = MoveStr(Next);
        DoMove(Next);
        break;
      }
    }
    ;
    return ret;
  }

  Perform(MOVETYPE move, bool resetmove) {
    if (resetmove) {
      MovePiece(move.old, move.nw1);
      if (move.content != empty)
        InsertPTabPiece(move.content, Opponent, move.nw1);
    } else {
      if (move.content != empty) DeletePiece(move.nw1);
      MovePiece(move.nw1, move.old);
    }

    if (move.spe) {
      if (move.movpiece == king) {
        var Cast = CASTTYPE();
        GenCastSquare(move.nw1, Cast);
        if (resetmove) {
          MovePiece(Cast.cornersquare, Cast.castsquare);
        } else {
          MovePiece(Cast.castsquare, Cast.cornersquare);
        }
      } else {
        if (move.movpiece == pawn) {
          var epsquare = (move.nw1 & 7) + (move.old & 0x70); /* E.p. capture */
          if (resetmove)
            InsertPTabPiece(pawn, Opponent, epsquare);
          else
            DeletePiece(epsquare);
        } else {
          if (resetmove)
            ChangeType(pawn, move.old);
          else
            ChangeType(move.movpiece, move.nw1);
        }
      }
    }

    if (resetmove) {
      MovTab[mc--] = MOVETYPE();
    } else {
      MovTab[mc++] = cloneMove(move);
      while (MovTab.length <= mc) MovTab.add(MOVETYPE());
    }
    Mo = MovTab[mc];
    Mpre = MovTab[mc - 1];
  }

/* simply undo last move in searching */
  unPerform() {
    Perform(Mpre, true);
  }

/*
 * Compare two moves
 */

  bool EqMove(a, b) {
    return (a.movpiece == b.movpiece &&
        a.nw1 == b.nw1 &&
        a.old == b.old &&
        a.content == b.content &&
        a.spe == b.spe);
  }

  /* === EVALUATE === */

  static const int TOLERANCE = 8; /*  Tolerance width  */
  static const int EXCHANGEVALUE = 32;
  /*  Value for exchanging pieces when ahead (not pawns)  */
  static const int ISOLATEDPAWN = 20;
  /*  Isolated pawn.  Double isolated pawn is 3 * 20  */
  static const int DOUBLEPAWN = 8; /*  Double pawn  */
  static const int SIDEPAWN = 6; /*  Having a pawn on the side  */
  static const int CHAINPAWN = 3; /*  Being covered by a pawn  */
  static const int COVERPAWN = 3; /*  covering a pawn  */
  static const int NOTMOVEPAWN = 2; /*  Penalty for moving pawn  */
  static const int BISHOPBLOCKVALUE = 20;
  /*  Penalty for bishop blocking d2/e2 pawn  */
  static const int ROOKBEHINDPASSPAWN =
      16; /*  Bonus for Rook behind passed pawn  */

/* constants and globals */

  static const PieceValue = [
    0,
    0x1000,
    0x900,
    0x4c0,
    0x300,
    0x300,
    0x100
  ]; // [7]
  static const distan = [3, 2, 1, 0, 0, 1, 2, 3]; // [8]
  /*  The value of a pawn is the sum of Rank and file values.
        The file value is equal to PawnFileFactor * (Rank Number + 2) */
  static const pawnrank = [0, 0, 0, 2, 4, 8, 30, 0]; // [8]
  static const passpawnrank = [0, 0, 10, 20, 40, 60, 70, 0]; // [8]
  static const pawnfilefactor = [0, 0, 2, 5, 6, 2, 0, 0]; // [8]
  static const castvalue = [4, 32]; // [2]  /*  Value of castling  */

  static const filebittab = [1, 2, 4, 8, 0x10, 0x20, 0x40, 0x80]; // [8]
  int totalmaterial = 0;
  int pawntotalmaterial = 0;
  int material = 0;
  /*  Material level of the game
        (early middlegame = 43 - 32, endgame = 0)  */
  int materiallevel = 0;
  static const squarerankvalue = [0, 0, 0, 0, 1, 2, 4, 4]; // [8]

  bool mating = false; /*  mating evaluation function is used  */

  List<List<List<int>>> PVTable = []; //[2][7][0x78]

  copyPwBt(PAWNBITTYPE t, PAWNBITTYPE f) {
    t.one = f.one;
    t.dob = f.dob;
  }

  var pawnbit = [];

  static const int MAXINT = 32767;

  int RootValue = 0;

  var bitcount = []; // count the number of set bits in b (0..255)

  prepareBitCounts() {
    int i = 0, b, c;
    for (; i < 256; i++) {
      b = i;
      c = 0;
      while (b != 0) {
        if ((b & 1) != 0) c++;
        b >>>= 1;
      }
      bitcount.add(c);
    }
  }

  prepare_PVTable() {
    for (int c = 0; c < 2; c++) {
      PVTable.add([]);
      for (int i = 0; i < 7; i++) {
        PVTable[c].add(List.filled(0x78, 0));
      }
    }
  }

/*
 *  Calculate value of the pawn structure in pawnbit[color][depth]
 */

  int pawnstrval(int depth, int color) {
    /*  contains FILEs with isolated pawns  */

    var o = pawnbit[color][depth], v = o.one, d = o.dob;
    var iso = v & ~((v << 1) | (v >>> 1));
    return (-(bitcount[d] * DOUBLEPAWN +
        bitcount[iso] * ISOLATEDPAWN +
        bitcount[iso & d] * ISOLATEDPAWN * 2));
  }

/*
 *  calculate the value of the piece on the square
 */

  int PiecePosVal(int piece, int color, int square) {
    return (PieceValue[piece] + PVTable[color][piece][square]);
  }

/*
 *  calculates piece-value table for the static evaluation function
 */

  CalcPVTable() {
    /*  Bit tables for static pawn structure evaluation  */
    int pawnfiletab,
        bit,
        oppasstab,
        behindoppass,
        leftsidetab,
        rightsidetab,
        sidetab,
        leftchaintab,
        rightchaintab,
        chaintab,
        leftcovertab,
        rightcovertab;

    /*  Importance of an attack of the square  */
    var attackvalue = [List.filled(0x78, 0), List.filled(0x78, 0)]; //[2][0x78]

    var pawntab = [List.filled(8, 0), List.filled(8, 0)]; // [2][8]

    /*  Value of squares controlled from the square  */
    var pvcontrol = []; //[2][5][0x78]

    int losingcolor; /*  the color which is being mated  */
    int posval; /*  The positional value of piece  */
    int attval; /*  The attack value of the square  */
    int line; /*  The file of the piece  */
    int rank; /*  The rank of the piece  */
    int dist, kingdist; /*  Distance to center, to opponents king */
    int cast; /*  Possible castlings  */
    bool direct; /*  Indicates direct attack  */
    int cnt; /*  Counter for attack values  */
    int strval; /*  Pawnstructure value  */
    int color, oppcolor; /*  Color and opponents color  */
    int piececount; /*  Piece counter  */
    int square; /*  Square counter  */
    int dir; /*  Direction counter  */
    int sq; /*  Square counter  */
    int t, t2, t3; /*  temporary junk  */
    int p, v;
    var o;

    for (int c = 0; c < 2; c++) {
      pvcontrol.add([]);
      for (int i = 0; i < 5; i++) {
        pvcontrol[c].add(List.filled(0x78, 0));
      }
    }

    /*  Calculate SAMMAT, PAWNSAMMAT and Material  */
    material = 0;
    pawntotalmaterial = 0;
    totalmaterial = 0;
    mating = false;

    for (square = 0; square < 0x78; square++)
      if ((square & 0x88) == 0) {
        o = Board[square];
        p = o.piece;
        if (p != empty) if (p != king) {
          t = PieceValue[p];
          totalmaterial += t;
          if (p == pawn) pawntotalmaterial += PieceValue[pawn];
          if (o.color == white) t = -t;
          material -= t;
        }
      }
    materiallevel = (max(0, totalmaterial - 0x2000) ~/ 0x100);
    /*  Set mating if weakest player has less than the equivalence
    of two bishops and the advantage is at least a rook for a bishop  */
    losingcolor = ((material < 0) ? white : black);
    v = (material).abs();
    mating = ((totalmaterial - v) / 2 <= PieceValue[bishop] * 2) &&
        (v >= PieceValue[rook] - PieceValue[bishop]);
    /*  Calculate ATTACKVAL (importance of each square)  */
    for (rank = 0; rank < 8; rank++)
      for (line = 0; line < 8; line++) {
        square = (rank << 4) + line;
        attval = max(0, 8 - 3 * (distan[rank] + distan[line]));
        /*  center importance */
        /*  Rank importrance  */
        for (color = white; color <= black; color++) {
          attackvalue[color][square] =
              ((squarerankvalue[rank] * 3 * (materiallevel + 8)) >> 5) + attval;
          square ^= 0x70;
        }
      }
    for (color = white; color <= black; color++) {
      oppcolor = (color ^ 1);
      cast = CalcCastling(oppcolor);
      if (cast != shrt && materiallevel > 0)
        /*  Importance of the 8 squares around the opponent's King  */
        for (dir = 0; dir < 8; dir++) {
          sq = PieceTab[oppcolor][0].isquare + DirTab[dir];
          if ((sq & 0x88) == 0)
            attackvalue[color][sq] += ((12 * (materiallevel + 8)) >> 5);
        }
    }

    /*  Calculate PVControl  */
    for (square = 0x77; square >= 0; square--)
      if ((square & 0x88) == 0)
        for (color = white; color <= black; color++)
          for (piececount = rook; piececount <= bishop; piececount++)
            pvcontrol[color][piececount][square] = 0;
    for (square = 0x77; square >= 0; square--)
      if ((square & 0x88) == 0)
        for (color = white; color <= black; color++) {
          for (dir = 7; dir >= 0; dir--) {
            piececount = ((dir < 4) ? rook : bishop);
            /*  Count value of all attacs from the square in
                    the Direction.
                    The Value of attacking a Square is Found in ATTACKVAL.
                    Indirect Attacks (e.g. a Rook attacking through
                    another Rook) counts for a Normal attack,
                    Attacks through another Piece counts half  */
            cnt = 0;
            sq = square;
            direct = true;
            do {
              sq += DirTab[dir];
              if ((sq & 0x88) != 0) break; //goto TEN
              t = attackvalue[color][sq];
              if (direct)
                cnt += t;
              else
                cnt += (t >> 1);
              p = Board[sq].piece;
              if (p != empty) if ((p != piececount) && (p != queen))
                direct = false;
            } while (p != pawn);
/*TEN:*/ pvcontrol[color][piececount][square] += (cnt >> 2);
          }
        }

    /*  Calculate PVTable, value by value  */
    for (square = 0x77; square >= 0; square--)
      if ((square & 0x88) == 0) {
        for (color = white; color <= black; color++) {
          oppcolor = (color ^ 1);
          line = square & 7;
          rank = square >> 4;
          if (color == black) rank = 7 - rank;
          dist = distan[rank] + distan[line];
          v = PieceTab[oppcolor][0].isquare;
          kingdist = ((square >> 4) - (v >> 4)).abs() + ((square - v) & 7);
          for (piececount = king; piececount <= pawn; piececount++) {
            posval = 0; /*  Calculate POSITIONAL Value for  */
            /*  The piece on the Square  */
            if (mating && (piececount != pawn)) {
              if (piececount == king) if (color ==
                  losingcolor) /*  Mating evaluation  */
              {
                posval = 128 - 16 * distan[rank] - 12 * distan[line];
                if (distan[rank] == 3) posval -= 16;
              } else {
                posval = 128 - 4 * kingdist;
                if ((distan[rank] >= 2) || (distan[line] == 3)) posval -= 16;
              }
            } else {
              t = pvcontrol[color][rook][square];
              t2 = pvcontrol[color][bishop][square];
              /*  Normal evaluation function  */
              switch (piececount) {
                case king:
                  if (materiallevel <= 0) posval = -2 * dist;
                  break;
                case queen:
                  posval = (t + t2) >> 2;
                  break;
                case rook:
                  posval = t;
                  break;
                case bishop:
                  posval = t2;
                  break;
                case knight:
                  cnt = 0;
                  for (dir = 0; dir < 8; dir++) {
                    sq = square + KnightDir[dir];
                    if ((sq & 0x88) == 0) cnt += attackvalue[color][sq];
                  }
                  posval = (cnt >> 1) - dist * 3;
                  break;
                case pawn:
                  if ((rank != 0) && (rank != 7))
                    posval =
                        pawnrank[rank] + pawnfilefactor[line] * (rank + 2) - 12;
              }
            }
            PVTable[color][piececount][square] = posval;
          }
        }
      }

    /*  Calculate pawntab (indicates which squares contain pawns)  */

    for (color = white; color <= black; color++)
      for (rank = 0; rank < 8; rank++) pawntab[color][rank] = 0;
    for (square = 0x77; square >= 0; square--)
      if ((square & 0x88) == 0) {
        o = Board[square];
        if (o.piece == pawn) {
          rank = square >> 4;
          if (o.color == black) rank = 7 - rank;
          pawntab[o.color][rank] |= filebittab[square & 7];
        }
      }
    for (color = white; color <= black; color++) /*  initialize pawnbit  */
    {
      o = pawnbit[color][0];
      o.dob = 0;
      o.one = 0;
      for (rank = 1; rank < 7; rank++) {
        t = pawntab[color][rank];
        o.dob |= (o.one & t);
        o.one |= t;
      }
    }
    /*  Calculate pawnstructurevalue  */
    RootValue = pawnstrval(0, Player) - pawnstrval(0, Opponent);

    /*  Calculate static value for pawn structure  */
    for (color = white; color <= black; color++) {
      oppcolor = (color ^ 1);
      pawnfiletab = 0;
      leftsidetab = 0;
      rightsidetab = 0;
      behindoppass = 0;
      oppasstab = 0xff;
      for (rank = 1; rank < 7; rank++)
      /*  Squares where opponents pawns are passed pawns  */
      {
        oppasstab &= (~(pawnfiletab | leftsidetab | rightsidetab));
        /*  Squares behind the opponents passed pawns  */
        behindoppass |= (oppasstab & pawntab[oppcolor][7 - rank]);
        /*  squares which are covered by a pawn  */
        leftchaintab = leftsidetab;
        rightchaintab = rightsidetab;
        pawnfiletab = pawntab[color][rank]; /*  squares w/ pawns  */
        /*  squares w/ a pawn beside them  */
        leftsidetab = (pawnfiletab << 1) & 0xff;
        rightsidetab = (pawnfiletab >> 1) & 0xff;
        sidetab = leftsidetab | rightsidetab;
        chaintab = leftchaintab | rightchaintab;
        /*  squares covering a pawn  */
        t = pawntab[color][rank + 1];
        leftcovertab = (t << 1) & 0xff;
        rightcovertab = (t >> 1) & 0xff;
        sq = rank << 4;
        if (color == black) sq ^= 0x70;
        bit = 1;
        while (bit != 0) {
          strval = 0;
          if ((bit & sidetab) != 0)
            strval = SIDEPAWN;
          else if ((bit & chaintab) != 0) strval = CHAINPAWN;
          if ((bit & leftcovertab) != 0) strval += COVERPAWN;
          if ((bit & rightcovertab) != 0) strval += COVERPAWN;
          if ((bit & pawnfiletab) != 0) strval += NOTMOVEPAWN;
          PVTable[color][pawn][sq] += strval;
          if ((materiallevel <= 0) || (oppcolor != ProgramColor)) {
            if ((bit & oppasstab) != 0)
              PVTable[oppcolor][pawn][sq] += passpawnrank[7 - rank];
            if ((bit & behindoppass) != 0) {
              t = sq ^ 0x10;
              for (t3 = black; t3 >= white; t3--) {
                PVTable[t3][rook][sq] += ROOKBEHINDPASSPAWN;
                if (rank == 6) PVTable[t3][rook][t] += ROOKBEHINDPASSPAWN;
              }
            }
          }
          sq++;
          bit = (bit << 1) & 0xff;
        }
      }
    }
    /*  Calculate penalty for blocking center pawns with a bishop  */
    for (sq = 3; sq < 5; sq++) {
      o = Board[sq + 0x10];
      if ((o.piece == pawn) && (o.color == white))
        PVTable[white][bishop][sq + 0x20] -= BISHOPBLOCKVALUE;
      o = Board[sq + 0x60];
      if ((o.piece == pawn) && (o.color == black))
        PVTable[black][bishop][sq + 0x50] -= BISHOPBLOCKVALUE;
    }
    for (square = 0x77; square >= 0; square--) /*  Calculate RootValue  */
      if ((square & 0x88) == 0) {
        o = Board[square];
        p = o.piece;
        if (p != empty) if (o.color == Player)
          RootValue += PiecePosVal(p, Player, square);
        else
          RootValue -= PiecePosVal(p, Opponent, square);
      }
  }

/*
 *  Update pawnbit and calculates value when a pawn is removed from line
 */

  int decpawnstrval(int color, int line) {
    var o = pawnbit[color][Depth];
    var t = ~filebittab[line];
    o.one = (o.one & t) | o.dob;
    o.dob &= t;
    return (pawnstrval(Depth, color) - pawnstrval(Depth - 1, color));
  }

/*
 *  Update pawnbit and calculates value when a pawn moves
 *  from old to nw1 file
 */

  int movepawnstrval(int color, int nw1, int old) {
    var o = pawnbit[color][Depth];
    var t = filebittab[nw1];
    var t2 = ~filebittab[old];
    o.dob |= (o.one & t);
    o.one = ((o.one & t2) | o.dob) | t;
    o.dob &= t2;
    return (pawnstrval(Depth, color) - pawnstrval(Depth - 1, color));
  }

/*
 *  Calculate STATIC evaluation of the move
 */

  int StatEvalu(MOVETYPE move) {
    var value = 0;
    if (move.spe) if (move.movpiece == king) {
      var Cast = CASTTYPE();
      GenCastSquare(move.nw1, Cast);
      value = PiecePosVal(rook, Player, Cast.castsquare) -
          PiecePosVal(rook, Player, Cast.cornersquare);
      if (move.nw1 > move.old)
        value += castvalue[shrt - 1];
      else
        value += castvalue[lng - 1];
    } else if (move.movpiece == pawn) {
      var epsquare = move.nw1 - PawnDir[Player]; /*  E.p. capture  */
      value = PiecePosVal(pawn, Opponent, epsquare);
    } else /*  Pawnpromotion  */
      value = PiecePosVal(move.movpiece, Player, move.old) -
          PiecePosVal(pawn, Player, move.old) +
          decpawnstrval(Player, move.old & 7);

    if (move.content != empty) /*  normal moves  */
    {
      value += PiecePosVal(move.content, Opponent, move.nw1);
      /*  Penalty for exchanging pieces when behind in material  */
      if ((MainEvalu).abs() >= 0x100) if (move.content !=
          pawn) if ((ProgramColor == Opponent) == (MainEvalu >= 0))
        value -= EXCHANGEVALUE;
    }
    /*  calculate pawnbit  */
    copyPwBt(pawnbit[black][Depth], pawnbit[black][Depth - 1]);
    copyPwBt(pawnbit[white][Depth], pawnbit[white][Depth - 1]);
    if ((move.movpiece == pawn) && ((move.content != empty) || move.spe))
      value += movepawnstrval(Player, move.nw1 & 7, move.old & 7);
    if ((move.content == pawn) || move.spe && (move.movpiece == pawn))
      value -= decpawnstrval(Opponent, move.nw1 & 7);
    /*  Calculate value of move  */
    return (value +
        PiecePosVal(move.movpiece, Player, move.nw1) -
        PiecePosVal(move.movpiece, Player, move.old));
  }

/* === SEARCH with own MOVEGEN 2 === */

/*
 *  Global Variables for this module
 */

  bool Analysis = true; // to display
  bool MateSrch = false; // set 1 to search mate only

  int MaxDepth = 0; // max.ply reached (=Depth-1)
  int LegalMoves = 0;
  bool SkipSearch = false;

  static const rank7 = [0x60, 0x10];

  late TIMERTYPE timer;

  int Nodes = 0;

  var killingmove = [[], []]; // [2][MAXPLY+1]

  var checktab =
      List.filled(MAXPLY + 3, false); //[MAXPLY+3], start from 1, not 0
/*  Square of eventual pawn on 7th rank  */
  var passedpawn = List.filled(MAXPLY + 4, 0); // [MAXPLY+4], start from 2

  int alphawindow = 0; /*  alpha window value  */
  int repeatevalu = 0; /*  MainEvalu at ply one  */

  INFTYPE startinf = INFTYPE(); /*  Inf at first ply  */

  static const int mane = 0,
      specialcap = 1,
      kill = 2,
      norml = 3; /*  move type  */

  List<MOVETYPE> copyMLine(List<MOVETYPE> a) {
    List<MOVETYPE> b = [];
    for (int i = 0; i < a.length;) b.add(cloneMove(a[i++]));
    return b;
  }

  MLINE MainLine = MLINE();

  MOVETYPE preDispMv = MOVETYPE();
  int preDisp_mxdp = 0;

  DisplayMove() {
    if (Analysis && Depth == 1) {
      MOVETYPE move = MainLine.a[1];
      if (((move.movpiece) != 0) &&
          (preDisp_mxdp < MaxDepth || !EqMove(preDispMv, move))) {
        preDispMv = cloneMove(move);
        preDisp_mxdp = MaxDepth;
        log_print(MaxDepth.toString() +
            " ply " +
            timer.elapsed.toString() +
            " sec. " +
            Nodes.toString() +
            " nodes " +
            sq2str(move.old) +
            sq2str(move.nw1));
        PrintBestMove();
      }
    }
  }

  PrintBestMove() {
    var s = "";
    int dep = 1;
    for (;;) {
      var move = MainLine.a[dep++];
      if (move.movpiece == empty) break;
      s += sq2str(move.old) + sq2str(move.nw1) + " ";
    }

    log_print('ev:' + EvValStr() + " " + s);
  }

// evalvalue as string
  String EvValStr() {
    double e = (MainEvalu / 256);
    if (Player == black) e = -e;
    return e.toStringAsFixed(2);
  }

/*
 *  Initialize killingmove, checktab and passedpawn
 */

  clearkillmove() {
    int dep, col, sq, i;
    var o;

    for (i = 0; i < 2; i++) {
      killingmove[i] = [];
      for (dep = 0; dep <= MAXPLY; dep++) killingmove[i].add(ZeroMove);
    }
    checktab[0] = false;
    passedpawn[0] = -1; /*  No check at first ply  */
    passedpawn[1] = -1;
    /*  Place eventual pawns on 7th rank in passedpawn  */
    for (col = white; col <= black; col++)
      for (sq = rank7[col]; sq <= rank7[col] + 7; sq++) {
        o = Board[sq];
        if ((o.piece == pawn) && (o.color == col)) if (col == Player)
          passedpawn[0] = sq;
        else
          passedpawn[1] = sq;
      }
  }

/*
 *  Update killingmove using bestmove
 */

  updatekill(MOVETYPE bestmove) {
    if (bestmove.movpiece != empty) {
      /*  Update killingmove unless the move is a capture of last
        piece moved  */
      if ((Mpre.movpiece == empty) ||
          (bestmove.nw1 != Mpre.nw1)) if ((killingmove[0][Depth].movpiece ==
              empty) ||
          (EqMove(bestmove, killingmove[1][Depth]))) {
        killingmove[1][Depth] = cloneMove(killingmove[0][Depth]);
        killingmove[0][Depth] = cloneMove(bestmove);
      } else if (!EqMove(bestmove, killingmove[0][Depth]))
        killingmove[1][Depth] = cloneMove(bestmove);
    }
  } /*  Updatekill  */

/*
 *  Test if move has been generated before
 */

  bool generatedbefore(PARAMTYPE P) {
    if (P.S.movgentype != mane) {
      if (EqMove(Mo, P.bestline.a[Depth])) return true;

      if (!P.S.capturesearch) if (P.S.movgentype != kill)
        for (var i = 0; i < 2; i++)
          if (EqMove(Mo, killingmove[i][Depth])) return true;
    }
    return false;
  }

/*
 *  Test cut-off.  Cutval cantains the maximal possible evaluation
 */

  bool cut(int cutval, PARAMTYPE P) {
    bool ct = false;
    if (cutval <= P.alpha) {
      ct = true;
      if (P.S.maxval < cutval) P.S.maxval = cutval;
    }
    return ct;
  }

/*
 *  Perform move, calculate evaluation, test cut-off, etc
 */
  bool tkbkmv() {
    unPerform();
    return true;
  }

  bool update(PARAMTYPE P) {
    Nodes++;
    P.S.nextply = P.ply - 1; /*  Calculate next ply  */
    if (MateSrch) /*  MateSrch  */
    {
      Perform(Mo, false); /*  Perform Move on the board  */
      /*  Check if Move is legal  */
      if (Attacks(Opponent, PieceTab[Player][0].isquare))
        return tkbkmv(); //TAKEBACKMOVE
      if (Depth == 1) LegalMoves++;
      checktab[Depth] = false;
      passedpawn[1 + Depth] = -1;
      var d = P.S.next;
      d.value = 0;
      d.evaluation = 0;
      if (P.S.nextply <= 0) /*  Calculate chech and perform evt. cut-off  */
      {
        if (P.S.nextply == 0)
          checktab[Depth] = Attacks(Player, PieceTab[Opponent][0].isquare);
        if (!checktab[Depth]) if (cut(P.S.next.value, P))
          return tkbkmv(); //TAKEBACKMOVE
      }

      DisplayMove();
      return false; //ACCEPTMOVE
    }

    /*  Make special limited capturesearch at first iteration  */
    if (MaxDepth <= 1) if (P.S.capturesearch && Depth >= 3) {
      if (!((Mo.content < Mo.movpiece) ||
          (P.S.movgentype == specialcap) ||
          (Mo.old == MovTab[mc - 2].nw1))) {
        DisplayMove();
        return true; // CUTMOVE
      }
    }
    /*  Calculate nxt static incremental evaluation  */
    P.S.next.value = -P.inf.value + StatEvalu(Mo);
    /*  Calculate checktab (only checks with moved piece are calculated)
        Giving Check does not count as a ply  */
    checktab[Depth] = PieceAttacks(
        Mo.movpiece, Player, Mo.nw1, PieceTab[Opponent][0].isquare);
    if (checktab[Depth]) P.S.nextply = P.ply;
    /*  Calculate passedpawn.  Moving a pawn to 7th rank does not
        count as a ply  */
    passedpawn[1 + Depth] = passedpawn[1 + (Depth - 2)];
    if (Mo.movpiece == pawn) if ((Mo.nw1 < 0x18) || (Mo.nw1 >= 0x60)) {
      passedpawn[1 + Depth] = Mo.nw1;
      P.S.nextply = P.ply;
    }
    /*  Perform selection at last ply and in capture search  */
    var selection = ((P.S.nextply <= 0) && !checktab[Depth] && (Depth > 1));
    if (selection) /*  check evaluation  */
    if (cut(P.S.next.value + 0, P)) {
      DisplayMove();
      return true;
    } // CUTMOVE
    Perform(Mo, false); /*  perform move on the board  */
    /*  check if move is legal  */
    if (Attacks(Opponent, PieceTab[Player][0].isquare))
      return tkbkmv(); //TAKEBACKMOVE
    var p = passedpawn[1 + Depth];
    if (p >= 0) /*  check passedpawn  */
    {
      var b = Board[p];
      if (b.piece != pawn || b.color != Player) passedpawn[1 + Depth] = -1;
    }
    if (Depth == 1) {
      LegalMoves++;
      P.S.next.value += rnd.nextInt(4);
    }
    P.S.next.evaluation = P.S.next.value;
//ACCEPTMOVE:
    DisplayMove();
    return false;
  }

/*
 *  Calculate draw bonus/penalty, and set draw if the game is a draw
 */

  bool drawgame(SEARCHTYPE S) {
    var o = S.next;
    if (Depth == 2) {
      var searchfifty = FiftyMoveCnt();
      var searchrepeat = Repetition(false);
      if (searchrepeat >= 3) {
        o.evaluation = 0;
        return true;
      }
      var drawcount = 0;
      if (searchfifty >= 96) /*  48 moves without pawn moves or captures */
        drawcount = 3;
      else {
        if (searchrepeat >= 2) /*  2nd repetition  */
          drawcount = 2;
        else if (searchfifty >= 20) /*  10 moves without pawn moves or  */
          drawcount = 1; /*  captures  */
      }
      var n = ((repeatevalu * drawcount) ~/ 4); // int
      o.value += n;
      o.evaluation += n; //int
    }
    if (Depth >= 4) {
      var searchrepeat = Repetition(true);
      if (searchrepeat >= 2) /*  Immediate repetition counts as  */
      {
        /*  a draw                          */
        o.evaluation = 0;
        return true;
      }
    }
    return false;
  }

/*
 *  Update bestline and MainEvalu using line and maxval
 */

  updatebestline(PARAMTYPE P) {
    P.bestline.a = copyMLine(P.S.line.a);
    P.bestline.a[Depth] = cloneMove(Mo); /* copies to new MOVETYPE() */

    if (Depth == 1) {
      MainEvalu = P.S.maxval;
      if (MateSrch) P.S.maxval = alphawindow;
      DisplayMove();
    }
  }

/*
 *  The inner loop of the search procedure.  MovTab[mc] contains the move.
 */

  bool loopbody(PARAMTYPE P) {
    if (generatedbefore(P)) return false;
    if (Depth < MAXPLY) {
      if (P.S.movgentype == mane) P.S.line.a = copyMLine(P.bestline.a);
      P.S.line.a[Depth + 1] = ZeroMove;
    }
    /*  principv indicates principal variation search  */
    /*  Zerowindow indicates zero - width alpha - beta window  */
    P.S.next.principv = false;
    P.S.zerowindow = false;
    if (P.inf.principv) if (P.S.movgentype == mane)
      P.S.next.principv = (P.bestline.a[Depth + 1].movpiece != empty);
    else
      P.S.zerowindow = (P.S.maxval >= P.alpha);

    for (;;) {
//REPEATSEARCH:

      if (update(P)) return false;
      bool f = true;
      if (MateSrch) /*  stop evt. search  */
      if ((P.S.nextply <= 0) && !checktab[Depth]) f = false;
      if (f && drawgame(P.S)) f = false;
      if (f && Depth >= MAXPLY) f = false;
      if (f) {
        /*  Analyse nextply using a recursive call to search  */
        var oldplayer = Player;
        Player = Opponent;
        Opponent = oldplayer;
        Depth++;
        if (P.S.zerowindow)
          P.S.next.evaluation =
              -search(-P.alpha - 1, -P.alpha, P.S.nextply, P.S.next, P.S.line);
        else
          P.S.next.evaluation =
              -search(-P.beta, -P.alpha, P.S.nextply, P.S.next, P.S.line);
        Depth--;
        oldplayer = Opponent;
        Opponent = Player;
        Player = oldplayer;
      }
//NOTSEARCH:
      unPerform(); /*  take back move  */
      if (SkipSearch) return true;
      if (Analysis) {
        if (MainEvalu > alphawindow) SkipSearch = timeused();
        if (MaxDepth <= 1) SkipSearch = false;
      }
      P.S.maxval = max(P.S.maxval, P.S.next.evaluation); /*  Update Maxval  */
      if (EqMove(P.bestline.a[Depth], Mo)) /*  Update evt. bestline  */
        updatebestline(P);
      if (P.alpha < P.S.maxval) /*  update alpha and test cutoff */
      {
        updatebestline(P);
        if (P.S.maxval >= P.beta) return true;
        /*  Adjust maxval (tolerance search)  */
        if (P.ply >= 2 && P.inf.principv && !P.S.zerowindow)
          P.S.maxval = min(P.S.maxval + TOLERANCE, P.beta - 1);
        P.alpha = P.S.maxval;
        if (P.S.zerowindow && !SkipSearch) {
          /*  repeat search with full window  */
          P.S.zerowindow = false;
          continue; //goto REPEATSEARCH;
        }
      }
      break;
    }

    return SkipSearch;
  }

/*
 *  generate  pawn promotions
 */

  bool pawnpromotiongen(PARAMTYPE P) {
    Mo.spe = true;
    for (var promote = queen; promote <= knight; promote++) {
      Mo.movpiece = promote;
      if (loopbody(P)) return true;
    }
    Mo.spe = false;
    return false;
  }

/*
 *  Generate captures of the piece on Newsq
 */

  bool capmovgen(int newsq, PARAMTYPE P) {
    var nxtsq, sq, i, p, q, m, b;
    Mo.content = Board[newsq].piece;
    Mo.spe = false;
    Mo.nw1 = newsq;
    Mo.movpiece = pawn; /*  pawn captures  */
    nxtsq = Mo.nw1 - PawnDir[Player];
    for (sq = nxtsq - 1; sq <= nxtsq + 1; sq++)
      if (sq != nxtsq) if ((sq & 0x88) == 0) {
        b = Board[sq];
        if (b.piece == pawn && b.color == Player) {
          Mo.old = sq;
          if (Mo.nw1 < 8 || Mo.nw1 >= 0x70) {
            if (pawnpromotiongen(P)) return true;
          } else if (loopbody(P)) return true;
        }
      }
    for (i = OfficerNo[Player]; i >= 0; i--) /*  other captures  */
    {
      m = PieceTab[Player][i];
      p = m.ipiece;
      q = m.isquare;

      if (p != empty && p != pawn) if (PieceAttacks(p, Player, q, newsq)) {
        Mo.old = q;
        Mo.movpiece = p;
        if (loopbody(P)) return true;
      }
    }
    return false;
  }

/*
 *  Generates non captures for the piece on oldsq
 */

  bool noncapmovgen(int oldsq, PARAMTYPE P) {
    var first, last, dir, direction, newsq;
    Mo.spe = false;
    Mo.old = oldsq;
    Mo.movpiece = Board[oldsq].piece;
    Mo.content = empty;

    switch (Mo.movpiece) {
      case king:
        for (dir = 7; dir >= 0; dir--) {
          newsq = Mo.old + DirTab[dir];
          if ((newsq & 0x88) == 0) if (Board[newsq].piece == empty) {
            Mo.nw1 = newsq;
            if (loopbody(P)) return true;
          }
        }
        break;
      case knight:
        for (dir = 7; dir >= 0; dir--) {
          newsq = Mo.old + KnightDir[dir];
          if ((newsq & 0x88) == 0) if (Board[newsq].piece == empty) {
            Mo.nw1 = newsq;
            if (loopbody(P)) return true;
          }
        }
        break;
      case queen:
      case rook:
      case bishop:
        first = 7;
        last = 0;
        if (Mo.movpiece == rook)
          first = 3;
        else if (Mo.movpiece == bishop) last = 4;
        for (dir = first; dir >= last; dir--) {
          direction = DirTab[dir];
          newsq = Mo.old + direction;
          while ((newsq & 0x88) == 0) {
            if (Board[newsq].piece != empty) break; // goto TEN
            Mo.nw1 = newsq;
            if (loopbody(P)) return true;
            newsq = Mo.nw1 + direction;
          }
//TEN:
          continue;
        }
        break;
      case pawn:
        /*  One square forward  */
        Mo.nw1 = Mo.old + PawnDir[Player];
        if (Board[Mo.nw1].piece == empty) if (Mo.nw1 < 8 || Mo.nw1 >= 0x70) {
          if (pawnpromotiongen(P)) return true;
        } else {
          if (loopbody(P)) return true;
          if (Mo.old < 0x18 || Mo.old >= 0x60) {
            /*  two squares forward  */
            Mo.nw1 += (Mo.nw1 - Mo.old);
            if (Board[Mo.nw1].piece == empty) if (loopbody(P)) return true;
          }
        }
    } /*  switch  */
    return false;
  }

/*
 *  castling moves
 */

  bool castlingmovgen(PARAMTYPE P) {
    Mo.spe = true;
    Mo.movpiece = king;
    Mo.content = empty;
    for (var castdir = (lng - 1); castdir <= shrt - 1; castdir++) {
      var m = CastMove[Player][castdir];
      Mo.nw1 = m.castnew;
      Mo.old = m.castold;
      if (KillMovGen(Mo)) if (loopbody(P)) return true;
    }
    return false;
  }

/*
 *  e.p. captures
 */

  bool epcapmovgen(PARAMTYPE P) {
    if (Mpre.movpiece == pawn) if ((Mpre.nw1 - Mpre.old).abs() >= 0x20) {
      Mo.spe = true;
      Mo.movpiece = pawn;
      Mo.content = empty;
      Mo.nw1 = (Mpre.nw1 + Mpre.old) ~/ 2;
      for (var sq = Mpre.nw1 - 1; sq <= Mpre.nw1 + 1; sq++)
        if (sq != Mpre.nw1) if ((sq & 0x88) == 0) {
          Mo.old = sq;
          if (KillMovGen(Mo)) if (loopbody(P)) return true;
        }
    }
    return false;
  }

/*
 *  Generate the next move to be analysed.
 *   Controls the order of the movegeneration.
 *      The moves are generated in the order:
 *      Main variation
 *      Captures of last moved piece
 *      Killing moves
 *      Other captures
 *      Pawnpromotions
 *      Castling
 *      Normal moves
 *      E.p. captures
 */

  searchmovgen(PARAMTYPE P) {
    var index, w = P.bestline.a[Depth], p;
    var u;

    copyMove(Mo, ZeroMove);

    /*  generate move from the main variation  */
    if (w.movpiece != empty) {
      copyMove(Mo, w);
      P.S.movgentype = mane;
      if (loopbody(P)) return;
    }
    if (Mpre.movpiece != empty) if (Mpre.movpiece != king) {
      P.S.movgentype = specialcap;
      if (capmovgen(Mpre.nw1, P)) return;
    }
    P.S.movgentype = kill;
    if (!P.S.capturesearch)
      for (var killno = 0; killno <= 1; killno++) {
        copyMove(Mo, killingmove[killno][Depth]);
        if (Mpre.movpiece != empty) if (KillMovGen(Mo)) if (loopbody(P)) return;
      }
    P.S.movgentype = norml;

    for (index = 1; index <= PawnNo[Opponent]; index++) {
      u = PieceTab[Opponent][index];
      if (u.ipiece != empty) if (Mpre.movpiece == empty ||
          u.isquare != Mpre.nw1) if (capmovgen(u.isquare, P)) return;
    }
    if (P.S.capturesearch) {
      p = passedpawn[1 + (Depth - 2)];
      if (p >= 0) {
        BOARDTYPE o = Board[p];
        if (o.piece == pawn && o.color == Player) if (noncapmovgen(p, P))
          return;
      }
    }
    if (!P.S.capturesearch) /*  non-captures  */
    {
      if (castlingmovgen(P)) return; /*  castling  */
      for (index = PawnNo[Player]; index >= 0; index--) {
        u = PieceTab[Player][index];
        if (u.ipiece != empty) if (noncapmovgen(u.isquare, P)) return;
      }
    }
    if (epcapmovgen(P)) return; /*  e.p. captures  */
  }

/*
 *  Perform the search
 *  On entry :
 *    Player is next to move
 *    MovTab[Depth-1] contains last move
 *    alpha, beta contains the alpha - beta window
 *    ply contains the Depth of the search
 *    inf contains various information
 *
 *  On exit :
 *    Bestline contains the principal variation
 *    search contains the evaluation for Player
 */

  int search(int alpha, int beta, int ply, INFTYPE inf, MLINE bestline) {
    var S = SEARCHTYPE(), P = PARAMTYPE();
    /*  Perform capturesearch if ply <= 0 and !check  */
    S.capturesearch = ((ply <= 0) && !checktab[Depth - 1]);
    if (S.capturesearch) /*  initialize maxval  */
    {
      S.maxval = -inf.evaluation;
      if (alpha < S.maxval) {
        alpha = S.maxval;
        if (S.maxval >= beta) return S.maxval; //goto STOP
      }
    } else {
      S.maxval = -(LOSEVALUE - (Depth - 1) * DEPTHFACTOR);
    }
    P.alpha = alpha;
    P.beta = beta;
    P.ply = ply;
    P.inf = inf;
    P.bestline = bestline;
    P.S = S;
    searchmovgen(P); /*  The search loop  */
    if (SkipSearch) return S.maxval; // goto STOP
    if (S.maxval ==
        -(LOSEVALUE - (Depth - 1) * DEPTHFACTOR)) /*  Test stalemate  */
    if (!Attacks(Opponent, PieceTab[Player][0].isquare)) {
      S.maxval = 0;
      return S.maxval; //goto STOP
    }
    updatekill(P.bestline.a[Depth]);
//STOP:
    return S.maxval;
  }

/*
 *  Begin the search
 */

  int callsearch(int alpha, int beta) {
    startinf.principv = (MainLine.a[1].movpiece != empty);
    LegalMoves = 0;
    var maxval = search(alpha, beta, MaxDepth, startinf, MainLine);
    if (LegalMoves == 0) MainEvalu = maxval;
    return maxval;
  }

/*
 *  Checks whether the search time is used
 */

  bool timeused() {
    if (Analysis) {
      timer.elapsed = timer.started.difference(DateTime.now()).inSeconds.abs();
      return (timer.elapsed >= MAXSECS);
    }
    return false;
  }

/*
 *  setup search (Player = color to play, Opponent = opposite)
 */

  String FindMove() {
    ProgramColor = Player;
    timer = TIMERTYPE();
    Nodes = 0;
    SkipSearch = false;
    clearkillmove();

    pawnbit = [[], []];
    for (int c = 0; c < 2; c++)
      for (int i = 0; i <= MAXPLY; i++) pawnbit[c].add(PAWNBITTYPE());

    CalcPVTable();
    startinf.value = -RootValue;
    startinf.evaluation = -RootValue;
    MaxDepth = 0;
    MainLine = MLINE();
    MainEvalu = RootValue;
    alphawindow = MAXINT;

    do {
      /*  update various variables  */
      if (MaxDepth <= 1) repeatevalu = MainEvalu;
      alphawindow = min(alphawindow, MainEvalu - 0x80);
      if (MateSrch) {
        alphawindow = 0x6000;
        if (MaxDepth > 0) MaxDepth++;
      }
      MaxDepth++;
      var maxval = callsearch(alphawindow, 0x7f00); /*  perform the search  */
      if (maxval <= alphawindow && !SkipSearch && !MateSrch && LegalMoves > 0) {
        /*  Repeat the search if the value falls below the
                    alpha-window  */
        MainEvalu = alphawindow;
        maxval = callsearch(-0x7F00, alphawindow - TOLERANCE * 2);
        LegalMoves = 2;
      }
    } while (!SkipSearch &&
        !timeused() &&
        (MaxDepth < MAXPLY) &&
        (LegalMoves > 1) &&
        ((MainEvalu).abs() < MATEVALUE - 24 * DEPTHFACTOR));

    DisplayMove();
    PrintBestMove();
    //printboard();
    return retMvStr();
  }

  String retMvStr() {
    var ret = "", move = MainLine.a[1], p = move.movpiece;
    if (move.movpiece != 0) {
      ret = sq2str(move.old) + sq2str(move.nw1);
      if (move.spe && (p != pawn && p != king)) ret += ("qrbn")[p - 2];
    }
    return ret;
  }

/* === Opening book === */

/* Globals */
  int LibNo = 0; // [0...32000]
  int OpCount = 0; // current move in list
  int LibMc = 0;
  List<MOVETYPE> LibMTab = []; // MOVETYPE[]
  bool LibFound = false;

  static const UNPLAYMARK = 0x3f;

/*
 *  Sets libno to the previous move in the block
 */

  PreviousLibNo() {
    var n = 0;
    do {
      LibNo--;
      var o = OwlBook.Openings[LibNo];
      if (o >= 128) n++;
      if ((o & 64) != 0) n--;
    } while (n != 0);
  }

/*
 *  Set libno to the first move in the block
 */

  FirstLibNo() {
    while ((OwlBook.Openings[LibNo - 1] & 64) == 0) PreviousLibNo();
  }

/*
 *  set libno to the next move in the block.  Unplayable
 *  moves are skipped if skip is set
 */

  NextLibNo(bool skip) {
    if (OwlBook.Openings[LibNo] >= 128)
      FirstLibNo();
    else {
      int n = 0;
      do {
        var o = OwlBook.Openings[LibNo];
        if ((o & 64) != 0) n++;
        if (o >= 128) n--;
        LibNo++;
      } while (n != 0);
      if (skip && (OwlBook.Openings[LibNo] == UNPLAYMARK)) FirstLibNo();
    }
  }

/*
 *  find the node corresponding to the correct block
 */

  FindNode() {
    int o = 0;
    LibNo++;
    if (mc >= LibMc) {
      LibFound = true;
      return;
    }
    OpCount = -1;
    InitMovGen();
    for (int i = 0; i < BufCount; i++) {
      OpCount++;
      MovGen();
      if (EqMove(Next, LibMTab[mc])) break;
    }

    if (Next.movpiece != empty) {
      for (;;) {
        o = OwlBook.Openings[LibNo];
        if (((o & 63) == OpCount) || (o >= 128)) break;
        NextLibNo(false);
      }

      if ((o & 127) == (64 + OpCount)) {
        DoMove(Next);
        FindNode();
        UndoMove();
      }
    }
  }

  CalcLibNo() {
    LibNo = 0;
    if (mc <= UseLib) {
      LibMTab = copyMLine(MovTab);
      LibMc = mc;
      ResetGame();
      LibFound = false;
      FindNode();
      while (mc < LibMc) {
        DoMove(LibMTab[mc]);
      }
      if (!LibFound) {
        UseLib = mc - 1;
        LibNo = 0;
      }
    }
  }

/*
 *  find an opening move from the library,
 *  return move string or "", also sets LibFound
 */

  String FindOpeningMove() {
    Nodes = 0;
    CalcLibNo();
    if (LibNo == 0) return "";

    const weight = [7, 10, 12, 13, 14, 15, 16]; // [7]
    int cnt = 0, p = 0, countp = 1;

    int r = rnd.nextInt(16); /*  calculate weighted random number in 0..16  */
    while (r >= weight[p]) p++;
    for (; countp <= p; countp++) /* find corresponding node */
      NextLibNo(true);
    OpCount = OwlBook.Openings[LibNo] & 63; /*  generate the move  */

    InitMovGen();
    for (int i = 0; cnt <= OpCount && i < BufCount; i++) {
      MovGen();
      cnt++;
    }

    /* store the move in mainline  */
    MainLine = MLINE();
    MainLine.a[1] = cloneMove(Next);
    MainEvalu = 0;
    PrintBestMove();
    return retMvStr();
  }

/* === STARTING === */

// initiate engine
  initEngine() {
    prepareBitCounts();
    prepare_PVTable();
    CalcAttackTab();
    ResetGame();
  }

  OWL() {
    initEngine();
  }

  playSampleAIvsAI() {
    // randomize more
    int roll_rnd = DateTime.now().second << 2;
    while ((roll_rnd--) > 0) rnd.nextInt(1);

//
// AI vs AI game for testing...
//

    var PGN = [];
    bool GameOver = false;
    bool checkmate = false;
    bool check = false;
    bool draw = false;
    bool resigned = false;

    ResetGame();

    while (!GameOver) {
      // style g7g8q
      var foundmove = FindOpeningMove(); // openings or...
      printboard();
      if (!LibFound) {
        foundmove = FindMove(); // let the engine search
      }
      log_print(foundmove +
          " Eval = " +
          EvValStr() +
          " , nodes = " +
          Nodes.toString());

      if (foundmove.length == 0) break;

      // style g7-g8=Q
      String notated = DoMoveByStr(foundmove);

      var s = Comment();
      if (LibFound) s = "(book) " + s;
      if (s.length > 0) log_print(s);

      GameOver = s.contains("Mate!"); // also stalemate
      checkmate = s.contains("CheckMate");
      check = s.contains("Check!");
      draw = s.contains("Draw,");
      resigned = s.contains("resigns");

      notated += (checkmate ? "#" : (check ? "+" : ""));
      while (PGN.length < mc) PGN.add("");
      PGN[mc - 1] = notated;
      log_print(notated);

      // 50 moves, 3x pos.
      if (draw) GameOver = true;

      // AI tries resign, ignore it, wanna see checkmate.
      if (resigned) {
        //  GameOver = true;
      }

      String pgn = "";
      for (int i = 1; i <= (mc - 1); i++) {
        pgn += (i % 2 == 1 ? ((i + 1) >>> 1).toString() + "." : "");
        pgn += PGN[i] + " ";
      }

      if (GameOver) pgn += "{" + s + "}";
      printboard();

      log_print(pgn);
    }

    if (checkmate || resigned) {
      print(Opponent == white ? "1-0" : "0-1");
    } else {
      print("1/2-1/2");
    }

    printboard();
  }
}
