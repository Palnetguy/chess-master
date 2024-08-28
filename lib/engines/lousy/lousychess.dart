//=============================================
//
//  This is a port to dart of
//   Lousy named chess engine (64bit) written in csharp for silverlight.
//  Modified for new magics, removed hash tables.
//
//  Important:
//   It works for flutter windows desktop app, android apps.
//   Does not work on web-javascript VM (32bit), because 64-bits required.
//    Therefore isInt64ok should be true.
//
//  Notes1:
//   The garbage-collector in dart there, so minimal memory usage in everything.
//   Dart memory objects management will reduce nodes per second performance.
//   Interpreted chess also is slow always, so minimum nodes and timeout on search.
//   Good selective search present.
//   Anyway can play till checkmate.
//
//--------------------------------------------
//  Just chosen one for Flutter project.
//
//  Author FdH???
//  Port by Chessforeva
//  mar.2024
//
//  Notes2:
//   Flutter can build in a strong C-chess, so dart is not the best choice.
//
//--------------------------------------------
//  Just run playSampleAIvsAI() from main() in dart to see it playing.
//
//  Notes3:
//   BitBoards, MagicMoves inits take time. It makes longer inits
//    on new Engine(), so, do it once at beginning. Not on every move.
//
//   MoveGen moves contain illegal moves too that search finds after.
//    Take into account when using elsewhere.
//
//   Dart randomizer may give same results, so an ackward
//    n-seconds-loop solves it.
//
//====

import 'dart:math';
import 'chessmagics.dart';

// included a small book, randomized first moves choices
import 'chessopenings.dart';

// global constants for chess engine

// Just set timeout limits and limit depth, otherwise not playable
int SEARCH_DEPTH = 8;
int SEARCH_SECONDS = 8;

bool isInt64ok = true; // flag that engine can work.

// ------ Chess Engine

class Const {
  // for matrix declarations
  static const int NrColors = 2,
      NrPieceTypes = 6,
      MaxNrPiecesPerType = 10,
      NrSquares = 64;

  static const piece_C = [
    ["K", "Q", "R", "B", "N", "P"],
    ["k", "q", "r", "b", "n", "p"]
  ];

  static const PieceStr = ["K", "Q", "R", "B", "N", ""];

  static const int White = 0, Black = 1;

  // MoveTypes (must be <= 63, due to move compacting !) :
  // The first 6 are also PieceType ID's
  static const int KingID = 0,
      QueenID = 1,
      RookID = 2,
      BishopID = 3,
      KnightID = 4,
      PawnID = 5;

  //
  static const int SpecialMoveID = 10;

  static const int CastleQSID = SpecialMoveID + 1,
      CastleKSID = SpecialMoveID + 2,
      Pawn2StepID = SpecialMoveID + 3;
  // from here on, the material score is changed. Used in Futility pruning
  static const int EnPassantCaptureID = SpecialMoveID + 4,
      PawnPromoteQueenID = SpecialMoveID + 5,
      PawnPromoteRookID = SpecialMoveID + 6,
      PawnPromoteBishopID = SpecialMoveID + 7,
      PawnPromoteKnightID = SpecialMoveID + 8,
      NullMoveID = SpecialMoveID + 9,
      NoMoveID = SpecialMoveID + 10;

  // miscellaneous
  static const int InvalidID = -1, EmptyID = -1;

  // The maximum bit sizes of various things and their bitmasks

  // a Piece = 0..5
  static const int NrPieceTypeBits = 3;
  static const int PieceTypeBitMask = 7;

  // The value for no capture : lowest 6 bits set, 2x3 bits for captured/capturing piece.
  // This is possible, since the largest PieceType = 5
  static const int NoCaptureID = 63;
}

class EPD {
  //==== char/string and rank/file/position stuff

  static bool IsFileChar(int c) {
    return (c >= 97 && c <= 104);
  }

  static bool IsRankChar(int c) {
    return (c >= 49 && c <= 56);
  }

  static bool IsPieceChar(int c) {
    return ([75, 81, 82, 66, 78].contains(c));
  }

  static String PositionToFileString(int position) {
    return String.fromCharCode((position & 7) + 97);
  }

  static String PositionToRankString(int position) {
    return String.fromCharCode((position >> 3) + 49);
  }

  static String PositionToString(int position) {
    return PositionToFileString(position) + PositionToRankString(position);
  }

  static String PieceTypeToString(int pieceType) {
    switch (pieceType) {
      case Const.KingID:
        return "K";
      case Const.QueenID:
        return "Q";
      case Const.RookID:
        return "R";
      case Const.BishopID:
        return "B";
      case Const.KnightID:
        return "N";
      case Const.PawnID:
        return "";
      default:
        logPrint("invalid PieceType : $pieceType");
    }
    return "";
  }

  static int StringToPosition(String s) {
    if (s.length != 2) logPrint("invalid PositionString : $s");
    return CharToFile(s.codeUnits[0]) + (CharToRank(s.codeUnits[1]) << 3);
  }

  static int CharToFile(int fileChar) {
    if (fileChar < 97 || fileChar > 104) {
      logPrint("invalid fileChar : ${String.fromCharCode(fileChar)}");
    }
    return (fileChar - 97);
  }

  static int CharToRank(int rankChar) {
    if (rankChar < 49 || rankChar > 56) {
      logPrint("invalid rankChar : ${String.fromCharCode(rankChar)}");
    }
    return (rankChar - 49);
  }

  static int CharToPieceType(int pieceChar) {
    switch (pieceChar) {
      case 75:
        return Const.KingID;
      case 81:
        return Const.QueenID;
      case 82:
        return Const.RookID;
      case 66:
        return Const.BishopID;
      case 78:
        return Const.KnightID;
      default:
        logPrint("invalid PieceChar : ${String.fromCharCode(pieceChar)}");
    }
    return -1;
  }

  static String PromotionPieceToString(int moveType) {
    switch (moveType) {
      case Const.PawnPromoteQueenID:
        return "Q";
      case Const.PawnPromoteRookID:
        return "R";
      case Const.PawnPromoteBishopID:
        return "B";
      case Const.PawnPromoteKnightID:
        return "N";
      default:
        logPrint("invalid moveType : ${String.fromCharCode(moveType)}");
    }
    return "";
  }

  static int CharToPromotionMoveType(int pieceChar) {
    switch (pieceChar) {
      case 81:
      case 113:
        return Const.PawnPromoteQueenID;
      case 82:
      case 114:
        return Const.PawnPromoteRookID;
      case 66:
      case 98:
        return Const.PawnPromoteBishopID;
      case 78:
      case 110:
        return Const.PawnPromoteKnightID;
      default:
        logPrint("invalid PieceChar : ${String.fromCharCode(pieceChar)}");
    }
    return -1;
  }

  static bool StringIsSanMove(String s) {
    // a3 Nb2 Bxc7 axb4 O-O O-O-O h8=Q . Can end on +, ! etc
    // nb : the string can always be followed by : +  =Q  ! ? etc
    int nrChars = s.length;
    if (nrChars < 2) return false; // must be at least 2 chars
    // test for O-O  O-O-O
    if (s.startsWith("O-O") || s.startsWith("0-0")) return true;
    // test for a3
    if (nrChars >= 2 &&
        IsFileChar(s.codeUnits[0]) &&
        IsRankChar(s.codeUnits[1])) return true;
    // Now there must be at least 3 chars
    if (nrChars < 3) return false;
    if (IsPieceChar(s.codeUnits[0])) {
      // starts with K,Q,R,B,N
      return true;
    }
    // test for axb4
    if (nrChars >= 4 &&
        IsFileChar(s.codeUnits[0]) &&
        s[1] == 'x' &&
        IsFileChar(s.codeUnits[2]) &&
        IsRankChar(s.codeUnits[3])) return true;
    return false;
  }

  static bool StringIsLANMove(String s) {
    // a 4 char string as : e2e4, or e7e8q
    return s.length >= 4 &&
        IsFileChar(s.codeUnits[0]) &&
        IsRankChar(s.codeUnits[1]) &&
        IsFileChar(s.codeUnits[2]) &&
        IsRankChar(s.codeUnits[3]);
  }

//==== SAN & LAN String <-> Move

  static String MoveToLANString(var move) // parm Move
  {
    // e.g. e2e4  e1g1 (KS castle), e7e8q (promotion)
    String s = EPD.PositionToString(move.fromPosition) +
        EPD.PositionToString(move.toPosition);
    if (move.moveType >= Const.SpecialMoveID) {
      switch (move.moveType) {
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          s += EPD.PromotionPieceToString(move.moveType).toLowerCase();
          break;
      }
    }
    return s;
  }

  //====
}

class BitBoard {
  // Direction constants : North is pointing from White to Black
  static const int North = 0;
  static const int East = 1;
  static const int South = 2;
  static const int West = 3;
  static const int NorthEast = 4;
  static const int SouthEast = 5;
  static const int SouthWest = 6;
  static const int NorthWest = 7;

  int All1sBB = 0; //U64  a bitboard with a 1 at each position

  // Just a 1 at the position bit, a 0 on all other bits
  // { for normal bitboard : 64 bit : starting from A1..H1, B2..H2 ,,,,,,, A8..H8 ]
  //U64[Const.NrSquares]
  static var Identity = List.filled(Const.NrSquares, 0);

  static const int InitialSeed = 12345;
  static Random rnd = Random(InitialSeed);

  // a matrix of bitboards. For each square 8 bitboards, with the squares which can be reached
  // from this square. 8 directions :
  // 0=N, 1=E, 2=S, 3=W   , 4=NE, 5=SE, 6=SW, 7=NW
  //U64[][]
  var Ray = [];

  // A matrix with FromSquares and ToSquares. The contents of each element is the Direction (see before)
  // how one should travel in a straight line from the FromSquare to the ToSquare.
  // If it is not possible in a straight line, the element is -1;
  //int[Const.NrSquares, Const.NrSquares]
  var Direction = [];

  // An array with bitboards, representing a rectangle around each square
  var Box1 = List.filled(
      64, 0); //U64[] a 3x3 rectangle with 1's. 0's inside and outside
  var Box2 = List.filled(
      64, 0); //U64[] a 5x5 rectangle with 1's. 0's inside and outside

  // An array with bitboards, with 1's on the respective file and 0's otherwise
  var FileBB1 = List.filled(8, 0); //U64[8]
  // An array with bitboards, with 0's on the respective file and 1's otherwise
  var FileBB0 = List.filled(8, 0); //U64[8]
  // An array with bitboards, with 1's on the respective rank and 0's otherwise
  var RankBB1 = List.filled(8, 0); //U64[8]
  // An array with bitboards, with 0's on the respective rank and 1's otherwise
  var RankBB0 = List.filled(8, 0); //U64[8]

  // bitmasks with 1's on all ranks which are in front of this rank
  //U64[2, 8]
  var AllRanksInFrontBB1 = [List.filled(8, 0), List.filled(8, 0)];
  // bitmasks with 1's on the file in front of this square.
  //U64[2, 64]
  var FileInFrontBB1 = [List.filled(64, 0), List.filled(64, 0)];
  // bitmasks with 1's in front of this square, on files left and right of the square.
  //U64[2, 64]
  var FilesLeftRightInFrontBB1 = [List.filled(64, 0), List.filled(64, 0)];
  // 0=white, 1 = black
  var PawnAttackBB1 = [List.filled(64, 0), List.filled(64, 0)];

  static var flip = List.filled(64, 0);
  static var ColorOfSquare = List.filled(64, 0);

  BitBoard() {
    CreateIdentity();
    CreateFlipsCols();
    Initialize_msb_lsb();
    InitializeRays();
    InitializeDirections(); // NB. Rays must have been initialized
    CreateBoxes();
    CreateFileRankBBs();
    CreatePawnAttackBBs();
  }

  //==== Identity

  CreateIdentity() {
    int q = 1; //U64
    for (int i = 0; i < Const.NrSquares; i++) {
      Identity[i] = q;
      All1sBB |= q; // the BB with all 1's
      q <<= 1;
    }
  }

  //====

  //==== Flip board [56,57,...63, 48, 49,......15, 0, 1...7]

  CreateFlipsCols() {
    for (int i = 0; i < Const.NrSquares; i++) {
      flip[((7 - (i >> 3)) << 3) | (i & 7)] = i;

      ColorOfSquare[i] = 1 - (((i >> 3) + (i & 7)) & 1);
    }
  }

  //====

// to debug bitboards
  logBitsOfInt(int N) {
    for (int v = 7; v >= 0; v--) {
      String s = "";
      for (int h = 0; h < 7; h++) {
        int sq = (v << 3) | h;
        int bit = 1 << sq;
        s += " ${(N & bit) != 0 ? "1" : "."}";
      }
      logPrint(s);
    }
  }

  //==== Initialize Rays and Direction

  InitializeRays() {
    // A matrix of bitboards. For each square 8 bitboards, with the squares which can be reached
    // from this square. 8 directions :
    // 0=N, 1=E, 2=S, 3=W   , 4=NE, 5=SE, 6=SW, 7=NW
    // So, North is increasing rank, East is increasing rile etc.
    //U64[Const.NrSquares]
    Ray = [];
    for (int squareNr = 0; squareNr < Const.NrSquares; squareNr++) {
      Ray.add(List.filled(8, 0));

      // North
      int rank = squareNr >> 3;
      int file = squareNr & 7;
      while (true) {
        rank++;
        if (rank == 8) break;
        Ray[squareNr][North] |= Identity[(rank << 3) | file];
      }
      // East
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        file++;
        if (file == 8) break;
        Ray[squareNr][East] |= Identity[(rank << 3) | file];
      }
      // South
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        rank--;
        if (rank == -1) break;
        Ray[squareNr][South] |= Identity[(rank << 3) | file];
      }
      // West
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        file--;
        if (file == -1) break;
        Ray[squareNr][West] |= Identity[(rank << 3) | file];
      }
      // NorthEast
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        rank++;
        file++;
        if (rank == 8 || file == 8) break;
        Ray[squareNr][NorthEast] |= Identity[(rank << 3) | file];
      }
      // SouthEast
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        rank--;
        file++;
        if (rank == -1 || file == 8) break;
        Ray[squareNr][SouthEast] |= Identity[(rank << 3) | file];
      }
      // SouthWest
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        rank--;
        file--;
        if (rank == -1 || file == -1) break;
        Ray[squareNr][SouthWest] |= Identity[(rank << 3) | file];
      }
      // NorthWest
      rank = squareNr >> 3;
      file = squareNr & 7;
      while (true) {
        rank++;
        file--;
        if (rank == 8 || file == -1) break;
        Ray[squareNr][NorthWest] |= Identity[(rank << 3) | file];
      }
    }
  }

  InitializeDirections() {
    // A matrix with FromSquares and ToSquares. The contents of each element is the Direction (see below)
    // how one should travel in a straight line from the FromSquare to the ToSquare.
    // If it is not possible in a straight line, the element is -1;
    for (int fromSquare = 0; fromSquare < Const.NrSquares; fromSquare++) {
      Direction.add(List.filled(Const.NrSquares, 0));
      for (int toSquare = 0; toSquare < Const.NrSquares; toSquare++) {
        Direction[fromSquare][toSquare] = -1;
        int toBB = Identity[toSquare]; //U64
        for (int i = 0; i < 8; i++) {
          if ((Ray[fromSquare][i] & toBB) != 0) {
            Direction[fromSquare][toSquare] = i;
            break;
          }
        }
      }
    }
  }

  //====

  //==== least & most significant bit in a BitBoard : LSB()  &  MSB()

  static List<int> msb = List.filled(65536, 16);
  static List<int> lsb = List.filled(65536, 16);
  static List<int> pop = List.filled(65536, 0);

  Initialize_msb_lsb() {
    for (int i = 1; i < 65536; i++) {
      for (int j = 0; j < 16; j++) {
        if ((i & (1 << j)) != 0) {
          msb[i] = j;
          if (lsb[i] == 16) lsb[i] = j;
          pop[i]++;
        }
      }
    }
  }

  // Returns (most significant bit).

  int MSB(int bb) //U64
  {
    if (bb >>> 48 != 0) return (msb[bb >>> 48] + 48);
    if (((bb >>> 32) & 65535) != 0) return (msb[(bb >>> 32) & 65535] + 32);
    if (((bb >>> 16) & 65535) != 0) return (msb[(bb >>> 16) & 65535] + 16);
    return (msb[bb & 65535]);
  }

  // Returns the least significant bit.

  int LSB(int bb) //U64
  {
    if ((bb & 65535) != 0) return (lsb[bb & 65535]);
    if (((bb >>> 16) & 65535) != 0) return (lsb[(bb >>> 16) & 65535] + 16);
    if (((bb >>> 32) & 65535) != 0) return (lsb[(bb >>> 32) & 65535] + 32);
    return (lsb[bb >>> 48] + 48);
  }

  //====

  //==== PopCount

  static int PopCount(int bb) //U64
  {
    int r = 0;
    for (int k = 0; k < 4; k++) {
      r += pop[bb & 65535];
      bb >>>= 16;
    }
    return r;
  }

  //====

  //==== rectangularMasks

  CalculateRectangularMasks(var result, int delta) //U64[]
  {
    // Calculates rectangular bitmasks as bitboards around each square.
    // The center position is not set.
    // Delta=1, 1 'layer' around each square. Delta=2, 2 'layers' around each square, etc.

    for (int i = 0; i < 64; i++) {
      int bitmask = 0; //U64
      int file0 = i & 7;
      int rank0 = i >> 3;
      for (int m = -delta; m <= delta; m++) {
        int y = rank0 + m;
        if (y < 0 || y > 7) continue;
        for (int n = -delta; n <= delta; n++) {
          if (m == 0 && n == 0) continue; // exclude center
          int x = file0 + n;
          if (x < 0 || x > 7) continue;
          bitmask |= Identity[y * 8 + x];
        }
      }
      result[i] = bitmask;
    }
  }

  CreateBoxes() {
    CalculateRectangularMasks(Box1, 1);
    CalculateRectangularMasks(Box2, 2);
    for (int i = 0; i < 64; i++) {
      Box2[i] &= ~Box1[i]; // set inside to 0;
    }
  }

  //====

  CreateFileRankBBs() {
    // the files
    for (int i = 0; i < 8; i++) {
      FileBB1[i] = 0;
      FileBB0[i] = All1sBB;
    }
    for (int x = 0; x < 8; x++)
      for (int y = 0; y < 8; y++) {
        int squareNr = x + y * 8;
        FileBB1[x] |= Identity[squareNr];
        FileBB0[x] &= ~Identity[squareNr];
      }
    // the ranks
    for (int i = 0; i < 8; i++) {
      RankBB1[i] = 0;
      RankBB0[i] = All1sBB;
    }
    for (int y = 0; y < 8; y++)
      for (int x = 0; x < 8; x++) {
        int squareNr = x + y * 8;
        RankBB1[y] |= Identity[squareNr];
        RankBB0[y] &= ~Identity[squareNr];
      }
    // AllRanksInFrontBB1
    for (int y = 0; y < 8; y++) {
      AllRanksInFrontBB1[0][y] = 0;
      AllRanksInFrontBB1[1][y] = 0;
      // for white :
      for (int yy = y + 1; yy < 8; yy++) {
        AllRanksInFrontBB1[0][y] |= RankBB1[yy];
      }
      // for black :
      for (int yy = y - 1; yy >= 0; yy--) {
        AllRanksInFrontBB1[1][y] |= RankBB1[yy];
      }
    }
    // FileInFrontBB1
    for (int color = 0; color < 2; color++)
      for (int i = 0; i < 64; i++) {
        int x = i & 7;
        int y = i >> 3;
        FileInFrontBB1[color][i] = FileBB1[x] & AllRanksInFrontBB1[color][y];
      }
    // FilesLeftRightInFrontBB1
    for (int color = 0; color < 2; color++)
      for (int i = 0; i < 64; i++) {
        int x = i & 7;
        int y = i >> 3;
        FileInFrontBB1[color][i] = 0;
        if (x > 0) {
          FileInFrontBB1[color][i] |=
              FileBB1[x - 1] & AllRanksInFrontBB1[color][y];
        }
        if (x < 7) {
          FileInFrontBB1[color][i] |=
              FileBB1[x + 1] & AllRanksInFrontBB1[color][y];
        }
      }
  }

  CreatePawnAttackBBs() {
    // NB : en passant is NOT included !!
    // Include captures from rank 1 (white) and rank 8 (black) since these are used in Board.IsInCheck
    //
    // for white
    for (int i = 0; i < Const.NrSquares; i++) {
      PawnAttackBB1[Const.White][i] = 0;
      if (i <= 55) {
        int x = i & 7;
        if (x > 0) PawnAttackBB1[Const.White][i] |= Identity[i + 7]; // left
        if (x < 7) PawnAttackBB1[Const.White][i] |= Identity[i + 9]; // right
      }
    }
    // for black
    for (int i = 0; i < Const.NrSquares; i++) {
      PawnAttackBB1[Const.Black][i] = 0;
      if (i >= 8) {
        int x = i & 7;
        if (x > 0) PawnAttackBB1[Const.Black][i] |= Identity[i - 9]; // left
        if (x < 7) PawnAttackBB1[Const.Black][i] |= Identity[i - 7]; // right
      }
    }
  }
}

class SquareContentInfo {
  int pieceType = 0; // king, queen, rook, bishop, knight, pawn : 0..5
  int pieceColor = 0; // White, Black : 0..1
  int pieceIndex = 0; // index in PiecePos
}

class BoardState {
  // the state of the board. Used in MakeMove and UnMakeMove.
  bool canCastleKingSide_White = false;
  bool canCastleQueenSide_White = false;
  bool canCastleKingSide_Black = false;
  bool canCastleQueenSide_Black = false;
  bool hasCastled_White = false;
  bool hasCastled_Black = false;
  int enPassantPosition = 0;
  int fiftyMoveNr = 0;
  int capturedPieceType = 0;
  int capturedPiecePosition = 0;
  int repeatedPosition_SearchOffset = 0;
}

class Board {
  // pointers to other classes
  late MagicMoves magicMoves;
  late MoveGenerator moveGenerator;
  late Evaluator evaluator;
  late BitBoard bitboard;

  //===== board state data

  // for all 2-position arrays :  index 0=white,  index 1=black

  // bitboards
  var pieces = [0, 0]; //U64[NrColors]
  int allPiecesBB = 0; //U64

  // the bitboards of each PieceType of each color
  //U64[Const.NrColors, Const.NrPieceTypes]
  var pieceBB = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0]
  ];

  // these hold the positions (0..63) of the pieces
  // int[Const.NrColors, Const.NrPieceTypes, Const.MaxNrPiecesPerType]
  // always filled from low to high
  var PiecePos = [[], []];

  // these hold the number of each pieceType
  //int[Const.NrColors, Const.NrPieceTypes]
  var NrPieces = [
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0]
  ];

  // these hold the total nr of pieces (pawns + the rest) of each color
  //int[Const.NrColors]
  var TotalNrPieces = [0, 0];

  // describes the contents of each square
  // SquareContentInfo[Const.NrSquares]
  List<SquareContentInfo> SquareContents = [];

  // state of the game info
  int colorToMove = 0; // int 0=white, 1=black
  int enemyColor = 0; // int
  var canCastleKingSide = [false, false]; //bool[Const.NrColors]
  var canCastleQueenSide = [false, false]; //bool[Const.NrColors]
  var hasCastled = [false, false]; //bool[Const.NrColors]
  int enPassantPosition =
      0; // int   If the last move was not a 2-step pawn move : -1
  // If it was, this value holds the position where it can be captured.
  int halfMoveNr = 0; // int   starts at 0, and is incremented AFTER each move
  int fiftyMoveNr =
      0; // int   incremented after each move. Reset on pawn-move or capture.
  int capturedPiecePosition = 0; // int
  int capturedPieceType = 0; // int

  int repeatedPosition_SearchOffset = 0; // int
  //the move-nr from which a 3x repeated position should be searched.
  List<Move> movesHist = [];

  // These stores the state of the board for deeper ply-nrs
  //int maxNrStoredBoardStates = 100;
  //int nrStoredBoardStates = 0; // int
  List<BoardState> storedBoardStates = []; // BoardState[]

  // The static material score (queen = 900, etc).
  // For both black and white holds : The larger the better.
  //int[Const.NrColors]
  var StaticMaterialScore = [0, 0];

  // The static positional score (calculated from Evaluation.PieceSquareValues).
  // For both black and white holds : The larger the better.
  //int[Const.NrColors]
  var StaticPositionalScore = [0, 0];

  //=====

  Board() {
    for (int i = 0; i < Const.NrColors; i++)
      for (int j = 0; j < Const.NrPieceTypes; j++) {
        PiecePos[i].add(List.filled(Const.MaxNrPiecesPerType, 0));
      }
    for (int k = 0; k < 64; k++) {
      SquareContents.add(SquareContentInfo());
    }
  }

  //==== logPrintOut Board

  logPrintboard() {
    for (int i = 56; i >= 0; i -= 8) {
      String s = "";
      for (int j = 0; j < 8; j++) {
        int sq = i + j;
        var Q = SquareContents[sq];
        int t = Q.pieceType, p = Q.pieceColor;
        s += '${(t == Const.EmptyID) ? '.' : Const.piece_C[p][t]} ';
      }
      logPrint(s);
    }
    logPrint("${colorToMove == Const.White ? "White" : "Black"} to move");
  }
  //====

  //==== Clone Board

  LoadFrom(Board clone) {
    // load the entire contents from a clone
    magicMoves = clone.magicMoves;
    evaluator = clone.evaluator;
    ClearBoard();
    moveGenerator = clone.moveGenerator;
    //
    pieces = []; //new U64[clone.pieces.length]
    for (int i = 0; i < clone.pieces.length; i++) {
      pieces.add(clone.pieces[i]);
    }
    allPiecesBB = clone.allPiecesBB;
    for (int i = 0; i < Const.NrColors; i++)
      for (int j = 0; j < Const.NrPieceTypes; j++) {
        pieceBB[i][j] = clone.pieceBB[i][j];
      }
    // PiecePos
    for (int i = 0; i < Const.NrColors; i++)
      for (int j = 0; j < Const.NrPieceTypes; j++) {
        for (int k = 0; k < Const.MaxNrPiecesPerType; k++) {
          PiecePos[i][j][k] = clone.PiecePos[i][j][k];
      }
        }
    //..
    // nrPieces
    for (int i = 0; i < Const.NrColors; i++) {
      TotalNrPieces[i] = clone.TotalNrPieces[i];
      for (int j = 0; j < Const.NrPieceTypes; j++) {
        NrPieces[i][j] = clone.NrPieces[i][j];
      }
    }
    // SquareContents
    for (int i = 0; i < Const.NrSquares; i++) {
      SquareContents[i] = SquareContentInfo();
      SquareContents[i].pieceColor = clone.SquareContents[i].pieceColor;
      SquareContents[i].pieceIndex = clone.SquareContents[i].pieceIndex;
      SquareContents[i].pieceType = clone.SquareContents[i].pieceType;
    }
    //
    // state of the game info
    colorToMove = clone.colorToMove;
    enemyColor = clone.enemyColor;
    for (int i = 0; i < Const.NrColors; i++) {
      canCastleKingSide[i] = clone.canCastleKingSide[i];
      canCastleQueenSide[i] = clone.canCastleQueenSide[i];
      hasCastled[i] = clone.hasCastled[i];
    }
    // ..
    enPassantPosition = clone.enPassantPosition;
    //
    halfMoveNr = clone.halfMoveNr;
    fiftyMoveNr = clone.fiftyMoveNr;
    capturedPiecePosition = clone.capturedPiecePosition;
    capturedPieceType = clone.capturedPieceType;
    repeatedPosition_SearchOffset = clone.repeatedPosition_SearchOffset;
    //

    storedBoardStates = []; //new BoardState[clone.storedBoardStates.length]
    for (int i = 0; i < clone.storedBoardStates.length; i++) {
      storedBoardStates.add(clone.storedBoardStates[i]);
    }
    //

    for (int i = 0; i < Const.NrColors; i++) {
      StaticMaterialScore[i] = clone.StaticMaterialScore[i];
      StaticPositionalScore[i] = clone.StaticPositionalScore[i];
    }
    //
  }

  //====

  ToggleMoveColor() {
    if (colorToMove == Const.White) {
      colorToMove = Const.Black;
      enemyColor = Const.White;
    } else {
      colorToMove = Const.White;
      enemyColor = Const.Black;
    }
  }

  //==== Setup board : empty & from EPD

  ClearBoard() {
    colorToMove = Const.White;
    enemyColor = Const.Black;
    // the bitboards
    pieces[Const.White] = 0;
    pieces[Const.Black] = 0;
    allPiecesBB = 0;
    for (int i = 0; i < Const.NrColors; i++) {
      pieceBB[i] = List.filled(Const.NrPieceTypes, 0);
    }

    // en passant
    enPassantPosition = Const.InvalidID;
    // the pieces
    for (int c = 0; c < Const.NrColors; c++) {
      TotalNrPieces[c] = 0;
      NrPieces[c] = List.filled(Const.NrPieceTypes, 0);
      for (int j = 0; j < Const.NrPieceTypes; j++) {
        PiecePos[c][j] = List.filled(Const.MaxNrPiecesPerType, Const.InvalidID);
      }
      // Castle info
      canCastleKingSide[c] = false;
      canCastleQueenSide[c] = false;
      hasCastled[c] = false;
      // the static scores
      StaticMaterialScore[c] = 0;
      StaticPositionalScore[c] = 0;
      //
    }
    // the squares
    for (int i = 0; i < Const.NrSquares; i++) {
      var Obj = SquareContentInfo();
      Obj.pieceType = Const.EmptyID;
      Obj.pieceColor = Const.InvalidID;
      Obj.pieceIndex = Const.InvalidID;
      SquareContents[i] = Obj;
    }
    canCastleQueenSide[Const.White] = false;
    canCastleKingSide[Const.White] = false;
    canCastleQueenSide[Const.Black] = false;
    canCastleKingSide[Const.Black] = false;

    // miscillaneous
    repeatedPosition_SearchOffset = 0;
  }

  FEN_To_Board(String fen) {
    // NB : starts from rank 8 !!, so use flip, to go from normal square-nr to flipped square nr

    var fenStrings = fen.split(' ');
    if (fenStrings.length < 4) {
      logPrint("FEN_to_Board : invalid FEN format");
      return;
    }
    //
    ClearBoard();
    //
    // **** The positions ****
    String boardString = fenStrings[0];
    int squareNr = 0;
    int n = 0;
    while (n < boardString.length) {
      int c = boardString.codeUnits[n];

      if (c >= 48 && c <= 57) {
        // isdigit
        squareNr += (c - 48); // advance position
      } else if (c == 47) {
        // simply skip '/'
      } else if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122))
      //isLetter
      {
        int color = (c < 97) ? Const.White : Const.Black; // isUpper
        int flip = BitBoard.flip[squareNr];
        switch (c) {
          case 80:
          case 112:
            AddNewPieceToBoard(color, Const.PawnID, flip);
            break;
          case 78:
          case 110:
            AddNewPieceToBoard(color, Const.KnightID, flip);
            break;
          case 66:
          case 98:
            AddNewPieceToBoard(color, Const.BishopID, flip);
            break;
          case 82:
          case 114:
            AddNewPieceToBoard(color, Const.RookID, flip);
            break;
          case 81:
          case 113:
            AddNewPieceToBoard(color, Const.QueenID, flip);
            break;
          case 75:
          case 107:
            AddNewPieceToBoard(color, Const.KingID, flip);
            break;
          default:
            logPrint("FEN_to_Board : invalid piece char");
        }
        squareNr++;
      } else
        logPrint("FEN_to_Board : invalid char");
      n++;
    }
    if (squareNr != 64) logPrint("FEN_to_Board : not all squares are assigned");

    //
    // **** Side to move ****
    String colorString = fenStrings[1];
    if (colorString.length != 1) logPrint("FEN_to_Board : 'b' or 'w' expected");
    if (colorString[0] == 'w') {
      colorToMove = Const.White;
      enemyColor = Const.Black;
    } else if (colorString[0] == 'b') {
      colorToMove = Const.Black;
      enemyColor = Const.White;
    } else
      logPrint("FEN_to_Board : 'b' or 'w' expected");
    //
    // **** Castling ****
    String castlingString = fenStrings[Const.NrColors];
    canCastleQueenSide[Const.White] = false;
    canCastleKingSide[Const.White] = false;
    canCastleQueenSide[Const.Black] = false;
    canCastleKingSide[Const.Black] = false;
    n = 0;
    while (n < castlingString.length) {
      switch (castlingString[n]) {
        case '-':
          break;
        case 'q':
          canCastleQueenSide[Const.Black] = true;
          break;
        case 'k':
          canCastleKingSide[Const.Black] = true;
          break;
        case 'Q':
          canCastleQueenSide[Const.White] = true;
          break;
        case 'K':
          canCastleKingSide[Const.White] = true;
          break;
      }
      n++;
    }
    //
    // **** en-passant position ****
    String epString = fenStrings[3];
    if (epString.length == 1 && epString[0] == '-') {
      enPassantPosition = Const.InvalidID;
    } else {
      int e0 = epString.codeUnits[0];
      int e1 = epString.codeUnits[1];

      if (epString.length != 2) {
        logPrint("FEN_to_Board : wrong ep-String length");
      }
      if (!EPD.IsFileChar(e0)) logPrint("FEN_to_Board : 'a'-'h' expected");
      if (!EPD.IsRankChar(e1)) logPrint("FEN_to_Board : '1'-'8' expected");
      enPassantPosition = (e0 - 97) + ((e1 - 49) << 3);
    }
    //
    if (fenStrings.length < 6) {
      // 50-move rule && full move nr were ommitted. Use defaults
      fiftyMoveNr = 0;
      halfMoveNr = 0;
    } else {
      fiftyMoveNr = int.parse(fenStrings[4]);
      if (fiftyMoveNr == false) {
        //null
        logPrint("Invalid Fifty-Move nr");
      }
      int fullMoveNr;
      fullMoveNr = int.parse(fenStrings[5]);
      if (fullMoveNr == false) {
        //null
        logPrint("Invalid Full-Move nr");
      }
      if (fullMoveNr < 1) logPrint("Invalid Full-Move nr ( <1 ) ");
      halfMoveNr = (fullMoveNr - 1) * 2;
    }
    if (colorToMove == Const.Black) halfMoveNr++;

    // all done. Now also store the current state of the board. This also stores the HashValues.

    StoreBoardState();
    movesHist = [];
  }

  //====

  //==== SAN & LAN String <-> Move

  String MoveToLANString(var move) // parm Move
  {
    // e.g. e2e4  e1g1 (KS castle), e7e8q (promotion)
    String s = EPD.PositionToString(move.fromPosition) +
        EPD.PositionToString(move.toPosition);
    if (move.moveType >= Const.SpecialMoveID) {
      switch (move.moveType) {
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          s += EPD.PromotionPieceToString(move.moveType).toLowerCase();
          break;
      }
    }
    return s;
  }

  String MoveToSANString(var move) // parm Move
  {
    int fromPosition = move.fromPosition;
    int toPosition = move.toPosition;
    // first generate all (pseudo-legal) moves :

    moveGenerator.GenerateMoves([]);
    var moves = moveGenerator.movelist;
    int nrMoves = moves.length;
    // Check the list to see if the move is present
    int moveNr = -1;
    for (int i = 0; i < nrMoves; i++) {
      if (MoveDo.Eq(move, moves[i])) {
        moveNr = i;
        break;
      }
    }
    if (moveNr == -1) return "???";

    // maybe it's a special move

    if (move.moveType >= Const.SpecialMoveID) {
      // these are never ambiguous
      switch (move.moveType) {
        case Const.CastleQSID:
          return "O-O-O";
        case Const.CastleKSID:
          return "O-O";
        case Const.EnPassantCaptureID:
          return "${EPD.PositionToFileString(fromPosition)}x${EPD.PositionToString(toPosition)}";
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          String s = EPD.PositionToFileString(fromPosition);
          if (move.captureInfo == Const.NoCaptureID) {
            s += EPD.PositionToRankString(toPosition);
          } else {
            s += "x${EPD.PositionToString(toPosition)}";
          }
          return "$s=${EPD.PromotionPieceToString(move.moveType)}";
        case Const.Pawn2StepID:
          return EPD.PositionToString(toPosition);
        default:
          logPrint("Invalid Special MoveType");
      }
    }

    // maybe it's a pawn move :

    if (move.moveType == Const.PawnID) {
      // is never ambiguous
      if (move.captureInfo == Const.NoCaptureID) {
        return EPD.PositionToString(toPosition);
      } else {
        return "${EPD.PositionToFileString(fromPosition)}x${EPD.PositionToString(toPosition)}";
      }
    }

    // It's a major piece move.

    String ss = EPD.PieceTypeToString(move.moveType);
    // check whetter multiple moves of the same type end on the same square
    int nrAmbiguousMoves = 0;
    var ambiguousMove = MoveDo.NoMove(); // Move()
    for (int i = 0; i < nrMoves; i++) {
      if (i == moveNr) continue;
      if (move.moveType == moves[i].moveType &&
          toPosition == moves[i].toPosition) {
        nrAmbiguousMoves++;
        if (nrAmbiguousMoves > 1) {
          break; // more then 1, always specify both file and rank
        }
        // only need to store 1
        ambiguousMove = moves[i];
      }
    }
    if (nrAmbiguousMoves > 0) {
      // add either a FileChar, a RankChar or both
      if (nrAmbiguousMoves == 1) {
        // different files ?
        if (ambiguousMove.fromPosition & 7 != move.fromPosition & 7) {
          ss += EPD.PositionToFileString(move.fromPosition);
        } else {
          // no, so differnent ranks
          ss += EPD.PositionToRankString(move.fromPosition);
        }
      } else {
        // more then 1 ambiguous move. Use both file and rank
        ss += EPD.PositionToString(move.fromPosition);
      }
    }
    if (move.captureInfo != Const.NoCaptureID) ss += "x";
    return ss + EPD.PositionToString(toPosition);
  }

  Move FindLANMoveOnBoard(String s) {
    // something like e2e4, e1g1 (KS castle), e7e8q (promotion)
    // first generate all (pseudo-legal) moves :
    int fromPos = EPD.StringToPosition(s.substring(0, 2));
    int toPos = EPD.StringToPosition(s.substring(2, 4));
    int promotionType = -1;
    if (s.length == 5) {
      // it contains the promotion piece
      promotionType = EPD.CharToPromotionMoveType(s.codeUnits[4]);
    }

    moveGenerator.GenerateMoves([]);
    var moves = moveGenerator.movelist;
    int nrMoves = moves.length;
    for (int i = 0; i < nrMoves; i++) {
      if (moves[i].fromPosition == fromPos && moves[i].toPosition == toPos) {
        if (promotionType == -1) {
          return moves[i]; // it's not a promotion
        } else if (moves[i].moveType == promotionType) return moves[i];
      }
    }
    // nothing found
    return MoveDo.NoMove();
  }

  // Generate all possible moves & compare them to the SAN string. Return the move if found.

  Move FindSANMoveOnBoard(String s) {
    // first generate all (pseudo-legal) moves :
    moveGenerator.GenerateMoves([]);
    var moves = moveGenerator.movelist;
    int nrMoves = moves.length;
    // a3 Nb2 Bxc7 axb4 O-O O-O-O h8=Q . Can end on +, ! etc
    int nrChars = s.length;

    // First do the castlings

    if (s == "O-O" || s == "0-0") {
      // king side castle
      for (int i = 0; i < nrMoves; i++) {
        if (moves[i].moveType == Const.CastleKSID) return moves[i];
      }
      return MoveDo.NoMove();
    }
    if (s == "O-O-O" || s == "0-0-0") {
      // queen side castle
      for (int i = 0; i < nrMoves; i++) {
        if (moves[i].moveType == Const.CastleQSID) return moves[i];
      }
      return MoveDo.NoMove();
    }

    // Test for non-capturing pawn moves :  a3 , a8=Q , a8Q : these all start with a1

    if (nrChars >= 2 &&
        EPD.IsFileChar(s.codeUnits[0]) &&
        EPD.IsRankChar(s.codeUnits[1])) {
      int toPos = EPD.StringToPosition(s.substring(0, 2));
      // maybe it's a promotion
      int promotionChar = 32;
      if (nrChars >= 3 && EPD.IsPieceChar(s.codeUnits[2])) {
        promotionChar = s.codeUnits[2];
      } else if (nrChars >= 4 && EPD.IsPieceChar(s.codeUnits[3]))
        promotionChar = s.codeUnits[3];
      if (promotionChar != 32) {
        int moveType = Const.InvalidID;
        switch (promotionChar) {
          case 81:
          case 113:
            moveType = Const.PawnPromoteQueenID;
            break;
          case 82:
          case 114:
            moveType = Const.PawnPromoteRookID;
            break;
          case 66:
          case 98:
            moveType = Const.PawnPromoteBishopID;
            break;
          case 78:
          case 110:
            moveType = Const.PawnPromoteKnightID;
            break;
        }
        for (int i = 0; i < nrMoves; i++) {
          if (moves[i].moveType == moveType &&
              moves[i].toPosition == toPos &&
              moves[i].captureInfo == Const.NoCaptureID) return moves[i];
        }
        // nothing found :
        return MoveDo.NoMove();
      }
      // it is not a promotion, but a normal move
      for (int i = 0; i < nrMoves; i++) {
        if ((moves[i].moveType == Const.PawnID ||
                moves[i].moveType == Const.Pawn2StepID) &&
            moves[i].toPosition == toPos &&
            moves[i].captureInfo == Const.NoCaptureID) return moves[i];
      }
      // nothing found :
      return MoveDo.NoMove();
    }

    // Test for a capturing pawn moves :  axb7 , axb8Q , axb8=Q : these start with a FileChar & 'x'

    if (EPD.IsFileChar(s.codeUnits[0])) {
      if (nrChars < 4 || s.codeUnits[1] != 120) {
        // 'x'
        return MoveDo.NoMove();
      }
      int toPos = EPD.StringToPosition(s.substring(2, 4));
      int fromFileNr = EPD.CharToFile(s.codeUnits[0]);
      // maybe it's a capturing promotion
      int promotionChar = 32; // ' '
      if (nrChars >= 5 && EPD.IsPieceChar(s.codeUnits[4])) {
        promotionChar = s.codeUnits[4];
      } else if (nrChars >= 6 && EPD.IsPieceChar(s.codeUnits[5]))
        promotionChar = s.codeUnits[5];
      if (promotionChar != 32) {
        int moveType = EPD.CharToPromotionMoveType(promotionChar);
        for (int i = 0; i < nrMoves; i++) {
          if (moves[i].moveType == moveType &&
              moves[i].fromPosition & 7 == fromFileNr &&
              moves[i].toPosition == toPos &&
              moves[i].captureInfo != Const.NoCaptureID) return moves[i];
        }
        // nothing found :
        return MoveDo.NoMove();
      }
      // it is not a promotion, but a normal capture
      for (int i = 0; i < nrMoves; i++) {
        if ((moves[i].moveType == Const.PawnID ||
                moves[i].moveType == Const.EnPassantCaptureID) &&
            moves[i].fromPosition & 7 == fromFileNr &&
            moves[i].toPosition == toPos &&
            moves[i].captureInfo != Const.NoCaptureID) return moves[i];
      }
      // nothing found :
      return MoveDo.NoMove();
    }

    // So, handled all the pawn moves, now the Piece moves
    // Ne4 , Ngf3 , N5e4 , Ng5f3 , Bxe6 , Bgxe6 , B1xe6 , Be2xe3

    int moveType2 = EPD.CharToPieceType(s.codeUnits[0]);
    // normal moves can be treated just as capturing moves
    bool isCapture = s.contains("x");
    if (isCapture) {
      s = s.replaceAll("x", "");
      nrChars = s.length;
    }
    // now left with : Ne4 , Ngf3 , N5e4 , Ng5f3
    int fromRankNr2 = -1;
    int fromFileNr2 = -1;
    // First handle a few special cases where the FromFile and/or FromRank is specified
    if (nrChars >= 4 && EPD.IsRankChar(s.codeUnits[1])) {
      // N5e4 : has FromRank
      fromRankNr2 = EPD.CharToRank(s.codeUnits[1]) << 3;
      s = s.substring(0, 1) + s.substring(2); // remove the fromRankChar 1,1
      nrChars = s.length;
    }
    // now left with Ne4 , Ngf3 , Ng5f3
    if (nrChars >= 4 && EPD.IsFileChar(s.codeUnits[2])) {
      // Ngf3 : has FromFile
      fromFileNr2 = EPD.CharToFile(s.codeUnits[1]);
      s = s.substring(0, 1) + s.substring(2); // remove the fromFileChar 1,1
      nrChars = s.length;
    }
    // now left with Ne4 , Ng5f3
    if (nrChars >= 5 &&
        EPD.IsFileChar(s.codeUnits[3]) &&
        EPD.IsRankChar(s.codeUnits[4])) {
      // has both FromFile and FromRank
      fromFileNr2 = EPD.CharToFile(s.codeUnits[1]);
      fromRankNr2 = EPD.CharToRank(s.codeUnits[2]) << 3;
      s = s.substring(0, 1) +
          s.substring(2); // remove the fromFileChar * fromRankChar  1,2
      nrChars = s.length;
    }
    // now left with Ne4
    int toPos2 = EPD.StringToPosition(s.substring(1, 2));
    // now loop over all the moves
    for (int i = 0; i < nrMoves; i++) {
      if (moves[i].moveType == moveType2 &&
          moves[i].toPosition == toPos2 &&
          (fromFileNr2 < 0 || (moves[i].fromPosition & 7) == fromFileNr2) &&
          (fromRankNr2 < 0 || (moves[i].fromPosition >> 3) == fromRankNr2) &&
          (isCapture == (moves[i].captureInfo != Const.NoCaptureID))) {
        return moves[i];
    }
      }

    // nothing found :
    return MoveDo.NoMove();
  }

  Move FindMoveOnBoard(String s) {
    Move move;
    // moveString is either a SAN or a e2e4 type string;
    if (EPD.StringIsLANMove(s)) {
      move = FindLANMoveOnBoard(s);
    } else if (EPD.StringIsSanMove(s))
      move = FindSANMoveOnBoard(s);
    else
      return MoveDo.NoMove();
    return move;
  }

  //====

  //==== Add, remove, move piece

  AddNewPieceToBoard(int color, int pieceTypeNr, int position) {
    if (SquareContents[position].pieceType != Const.EmptyID) {
      logPrint("Square is not empty");
    }
    int newIndex = NrPieces[color][pieceTypeNr];
    var C = SquareContents[position];
    C.pieceType = pieceTypeNr;
    C.pieceColor = color;
    C.pieceIndex = newIndex;
    //
    TotalNrPieces[color]++;
    NrPieces[color][pieceTypeNr] = newIndex + 1;
    PiecePos[color][pieceTypeNr][newIndex] = position;
    //
    pieceBB[color][pieceTypeNr] |= BitBoard.Identity[position];
    pieces[color] |= BitBoard.Identity[position];
    allPiecesBB |= BitBoard.Identity[position];
    // update the static scores
    StaticMaterialScore[color] += evaluator.PieceValues[pieceTypeNr];
    StaticPositionalScore[color] +=
        evaluator.PieceSquareValues[color][pieceTypeNr][position];
  }

  RemovePieceFromBoard(int position) {
    var C = SquareContents[position];
    int index = C.pieceIndex;
    int pieceTypeNr = C.pieceType;
    int color = C.pieceColor;
    //
    // If a rook is captured, we might want to update the CastlingInfo !
    if (pieceTypeNr == Const.RookID) {
      if (colorToMove == Const.White && color == Const.Black) {
        // check black rooks
        if (index == 56) {
          ResetCanCastleQS(Const.Black);
        } else if (index == 63) ResetCanCastleKS(Const.Black);
      } else if (colorToMove == Const.Black && color == Const.White) {
        // check white rooks
        if (index == 0) {
          ResetCanCastleQS(Const.White);
        } else if (index == 7) ResetCanCastleKS(Const.White);
      }
    }
    //
    C.pieceType = Const.EmptyID;
    C.pieceColor = Const.InvalidID;
    C.pieceIndex = Const.InvalidID;
    //
    TotalNrPieces[color]--;
    int lastIndex = NrPieces[color][pieceTypeNr] - 1;
    NrPieces[color][pieceTypeNr]--;
    // copy the last piece to the removed piece slot
    if (index != lastIndex) {
      int pos = PiecePos[color][pieceTypeNr][lastIndex];
      PiecePos[color][pieceTypeNr][index] = pos;
      SquareContents[pos].pieceIndex = index;
    }
    PiecePos[color][pieceTypeNr][lastIndex] = Const.InvalidID;
    //
    pieceBB[color][pieceTypeNr] &= ~BitBoard.Identity[position];
    pieces[color] &= ~BitBoard.Identity[position];
    allPiecesBB &= ~BitBoard.Identity[position];
    // update the static scores
    StaticMaterialScore[color] -= evaluator.PieceValues[pieceTypeNr];
    StaticPositionalScore[color] -=
        evaluator.PieceSquareValues[color][pieceTypeNr][position];
  }

  MovePieceOnBoard(int oldPosition, int newPosition) {
    var C = SquareContents[oldPosition];
    // Capture must be handled by RemovePieceFromBoard
    int index = C.pieceIndex;
    int pieceTypeNr = C.pieceType;
    int color = C.pieceColor;

    //
    C.pieceType = Const.EmptyID;
    C.pieceColor = Const.InvalidID;
    C.pieceIndex = Const.InvalidID;
    //
    var N = SquareContents[newPosition];
    N.pieceType = pieceTypeNr;
    N.pieceColor = color;
    N.pieceIndex = index;
    //
    PiecePos[color][pieceTypeNr][index] = newPosition;
    //
    pieceBB[color][pieceTypeNr] &= ~BitBoard.Identity[oldPosition];
    pieces[color] &= ~BitBoard.Identity[oldPosition];
    allPiecesBB &= ~BitBoard.Identity[oldPosition];
    //
    pieceBB[color][pieceTypeNr] |= BitBoard.Identity[newPosition];
    pieces[color] |= BitBoard.Identity[newPosition];
    allPiecesBB |= BitBoard.Identity[newPosition];
    // update the static scores
    StaticPositionalScore[color] += evaluator.PieceSquareValues[color]
            [pieceTypeNr][newPosition] -
        evaluator.PieceSquareValues[color][pieceTypeNr][oldPosition];
  }

  //====

  //==== Store BoardState for moving up and down the plies

  StoreBoardState() {
    BoardState Obj = BoardState();
    Obj.enPassantPosition = enPassantPosition;
    Obj.fiftyMoveNr = fiftyMoveNr;
    Obj.canCastleQueenSide_White = canCastleQueenSide[Const.White];
    Obj.canCastleKingSide_White = canCastleKingSide[Const.White];
    Obj.hasCastled_White = hasCastled[Const.White];
    Obj.canCastleQueenSide_Black = canCastleQueenSide[Const.Black];
    Obj.canCastleKingSide_Black = canCastleKingSide[Const.Black];
    Obj.hasCastled_Black = hasCastled[Const.Black];
    Obj.capturedPieceType = capturedPieceType;
    Obj.capturedPiecePosition = capturedPiecePosition;
    Obj.repeatedPosition_SearchOffset = repeatedPosition_SearchOffset;
    storedBoardStates.add(Obj);
  }

  RestoreBoardState() {
    storedBoardStates.removeLast();
    BoardState Obj = storedBoardStates[storedBoardStates.length - 1];
    enPassantPosition = Obj.enPassantPosition;
    fiftyMoveNr = Obj.fiftyMoveNr;
    canCastleQueenSide[Const.White] = Obj.canCastleQueenSide_White;
    canCastleKingSide[Const.White] = Obj.canCastleKingSide_White;
    hasCastled[Const.White] = Obj.hasCastled_White;
    canCastleQueenSide[Const.Black] = Obj.canCastleQueenSide_Black;
    canCastleKingSide[Const.Black] = Obj.canCastleKingSide_Black;
    hasCastled[Const.Black] = Obj.hasCastled_Black;
    capturedPieceType = Obj.capturedPieceType;
    capturedPiecePosition = Obj.capturedPiecePosition;
    repeatedPosition_SearchOffset = Obj.repeatedPosition_SearchOffset;
  }

  //====

  //==== IsInCheck , IsDrawn

  // Check whetter the king of the color to move is under attack

  bool IsInCheck() {
    // Use the attack symmetry:  Pretend our king is all piece types,
    // and see if it can capture the corresponding enemy piece type.
    // This version speeds up the program by 10 %, in comparison to the IsInCheck_old version.
    int attackBB = 0; //U64
    int kingPos = PiecePos[colorToMove][Const.KingID][0];
    // The sliding pieces
    // pretend the king is a bishop. Get all squares it could attack.
    attackBB = magicMoves.Bmagic(kingPos, allPiecesBB);
    // check whetter it includes an enemy Queen or Bishop
    if ((attackBB &
            (pieceBB[enemyColor][Const.QueenID] |
                pieceBB[enemyColor][Const.BishopID])) !=
        0) return true;
    // pretend the king is a rook. Get all squares it could attack.
    attackBB = magicMoves.Rmagic(kingPos, allPiecesBB);
    // check whetter it includes an enemy Queen or Rook
    if ((attackBB &
            (pieceBB[enemyColor][Const.QueenID] |
                pieceBB[enemyColor][Const.RookID])) !=
        0) return true;
    // The non-sliding pieces
    // pretend the king is a Knight. Get all squares it could attack. See if it includes an enemy Knight.
    if ((moveGenerator.EmptyBoardKnightMoves[kingPos] &
            pieceBB[enemyColor][Const.KnightID]) !=
        0) return true;
    // pretend the king is a Pawn. Get all squares it could attack. See if it includes an enemy pawn.
    // (the EmptyBoardPawnCatchMoves does _not_ include en-passant capturing, so ok).
    if ((bitboard.PawnAttackBB1[colorToMove][kingPos] &
            pieceBB[enemyColor][Const.PawnID]) !=
        0) return true;
    // pretend the king is a King. Get all squares it could attack. See if it includes the enemy King.
    if ((moveGenerator.EmptyBoardKingMoves[kingPos] &
            pieceBB[enemyColor][Const.KingID]) !=
        0) return true;
    //
    // Not in check !
    return false;
  }

  bool IsDrawnBy50Moves() {
    return fiftyMoveNr >= 100;
  }

  bool IsDrawnBy3xRepetition() {
    // check for 3x repetition
    int nrSame = 0;
    // repeatedPosition_SearchOffset is the last move a pawn-move was made. This position is irreversible.
    if (movesHist.length > 10) {
      int i = movesHist.length - 1;
      // compare moves, it is not correctly, but anyway
      Move mv = movesHist[i];
      for (--i; i >= repeatedPosition_SearchOffset; i--) {
        if (MoveDo.Eq(mv, movesHist[i])) nrSame++;
      }
    }
    // nrSame : officially it is 2 : 2 times before, so this is the 3rd time
    return nrSame >= 2;
  }

  bool IsDrawnByMaterial() {
    // check for not enough material
    // Material draw, if both sides have no pawns and either 1 bishop, or 1 or 2 knights
    //
    // The fastest test is the TotalNrPieces :
    // nr pieces > 3 is king + 3 other pieces = never a draw
    if (TotalNrPieces[Const.White] > 3 || TotalNrPieces[Const.Black] > 3) {
      return false;
    }
    // if either side has pawns, it is not a draw
    if (NrPieces[Const.White][Const.PawnID] > 0 ||
        NrPieces[Const.Black][Const.PawnID] > 0) return false;
    // if either side has a queen or a rook, it is not a draw
    if (NrPieces[Const.White][Const.QueenID] > 0 ||
        NrPieces[Const.Black][Const.QueenID] > 0) return false;
    if (NrPieces[Const.White][Const.RookID] > 0 ||
        NrPieces[Const.Black][Const.RookID] > 0) return false;
    // both sides have no pawns, no rooks, no queens.
    int nrWhiteBishops = NrPieces[Const.White][Const.BishopID];
    int nrBlackBishops = NrPieces[Const.Black][Const.BishopID];
    // if either side has more then 1 bishop, it is not a draw. (ignores 2 bishops of the same color)
    if (nrWhiteBishops > 1 || nrBlackBishops > 1) return false;
    // both sides have maximal 1 bishop
    int nrWhiteKnights = NrPieces[Const.White][Const.KnightID];
    int nrBlackKnights = NrPieces[Const.Black][Const.KnightID];
    bool whiteCantWin = nrWhiteBishops == 0 && nrWhiteKnights <= 2 ||
        nrWhiteBishops == 1 && nrWhiteKnights == 0;
    bool blackCantWin = nrBlackBishops == 0 && nrBlackKnights <= 2 ||
        nrBlackBishops == 1 && nrBlackKnights == 0;
    return whiteCantWin && blackCantWin;
  }

  bool IsPracticallyDrawn() {
    // check for 50-rule
    if (fiftyMoveNr >= 100) return true;

    // check for 3x repetition
    int nrSame = 0;
    // repeatedPosition_SearchOffset is the last move a pawn-move was made. This position is irreversible.
    if (movesHist.length > 10) {
      int i = movesHist.length - 1;
      // compare moves, it is not correctly, but anyway
      Move mv = movesHist[i];
      for (--i; i >= repeatedPosition_SearchOffset; i--) {
        if (MoveDo.Eq(mv, movesHist[i])) nrSame++;
      }
    }

    // nrSame : officially it is 2 : 2 times before, so this is the 3rd time
    // but >= 1 works better, since if a repeated position could be forced, it can also happen a 2nd time.
    if (nrSame >= 1) return true;

    // check for not enough material
    if (IsDrawnByMaterial()) return true;

    return false;
  }

  bool HasZugZwang() {
    // could introduce pawn mobility
    int nrPawns = NrPieces[colorToMove][Const.PawnID];
    int nrPieces = TotalNrPieces[colorToMove];
    return nrPieces - nrPawns == 1; // zugzwang if no major/minor pieces left
  }

  //====

  //==== Make / Unmake move

  ResetCanCastleQS(int castleColor) {
    // first check, because we want to remove the CanCastle only once
    if (canCastleQueenSide[castleColor]) {
      canCastleQueenSide[castleColor] = false;
    }
  }

  ResetCanCastleKS(int castleColor) {
    // first check, because we want to remove the CanCastle only once
    if (canCastleKingSide[castleColor]) {
      canCastleKingSide[castleColor] = false;
    }
  }

  bool MakeMove(Move move) {
    bool moveIsLegal =
        true; // this will be checked if a castle is done and by the IsInCheck test
    // increment the HalfMoveNr
    halfMoveNr++;
    // increment the fiftyMoveNr. It will be reset later in this method if it was a capture or a pawn-move.
    fiftyMoveNr++;
    //
    capturedPieceType = Const.InvalidID;
    capturedPiecePosition = Const.InvalidID;

    //
    if (move.moveType < Const.SpecialMoveID) {
      // a normal move of a piece
      enPassantPosition =
          Const.InvalidID; // normal move : always reset the enpassant position
      // Handle castling info
      if (canCastleQueenSide[colorToMove] || canCastleKingSide[colorToMove]) {
        // check for a king move
        if (move.moveType == Const.KingID) {
          ResetCanCastleQS(colorToMove);
          ResetCanCastleKS(colorToMove);
        }
        // check for a castle move
        if (move.moveType == Const.RookID) {
          int offset = colorToMove * 56;
          // check if the QS rook will move. Offset points to the queen-side rooks.
          if (move.fromPosition == offset) ResetCanCastleQS(colorToMove);
          // check if the KS rook will move.  Offset+7 points to the king-side rooks.
          if (move.fromPosition == offset + 7) ResetCanCastleKS(colorToMove);
        }
      }
      // update the fiftyMoveNr
      if (move.moveType == Const.PawnID) {
        fiftyMoveNr = 0; // pawn move : reset the fiftyMoveNr
        repeatedPosition_SearchOffset = halfMoveNr - 1;
      }
      // is it a capture ? Yes : remove the captured piece
      if (SquareContents[move.toPosition].pieceType != Const.EmptyID) {
        // save state
        capturedPiecePosition = move.toPosition;
        capturedPieceType = SquareContents[move.toPosition].pieceType;
        //
        RemovePieceFromBoard(move.toPosition);
        fiftyMoveNr = 0; // capture : reset the fiftyMoveNr
      }
      // now make the move
      MovePieceOnBoard(move.fromPosition, move.toPosition);
    } else {
      // Specials
      // it is a Castle, enpassant capture, 2-stap pawn move or pawn promotion
      int castleRankOffset = colorToMove * 56;
      switch (move.moveType) {
        case Const.CastleQSID:
          // Maybe the castle was illegal. Do it anyway.
          // Illegal castle will immediately be undone in SearchMove.
          if (moveIsLegal) {
            moveIsLegal = moveGenerator.CastleIsLegal(Const.CastleQSID);
          }
          MovePieceOnBoard(castleRankOffset + 4, castleRankOffset + 2); // King
          MovePieceOnBoard(castleRankOffset + 0, castleRankOffset + 3); // Rook
          hasCastled[colorToMove] = true;
          ResetCanCastleQS(colorToMove);
          ResetCanCastleKS(colorToMove);
          break;
        case Const.CastleKSID:
          // Maybe the castle was illegal. Do it anyway.
          // Illegal castle will immediately be undone in SearchMove.
          if (moveIsLegal) {
            moveIsLegal = moveGenerator.CastleIsLegal(Const.CastleKSID);
          }
          MovePieceOnBoard(castleRankOffset + 4, castleRankOffset + 6); // King
          MovePieceOnBoard(castleRankOffset + 7, castleRankOffset + 5); // Rook
          hasCastled[colorToMove] = true;
          ResetCanCastleQS(colorToMove);
          ResetCanCastleKS(colorToMove);
          break;
        case Const.EnPassantCaptureID:
          capturedPieceType = Const.PawnID;
          if (colorToMove == Const.White) {
            capturedPiecePosition =
                enPassantPosition - 8; // captured pawn is black
          } else {
            capturedPiecePosition =
                enPassantPosition + 8; // captured pawn is white
          }
          RemovePieceFromBoard(capturedPiecePosition);
          MovePieceOnBoard(move.fromPosition, move.toPosition);
          break;
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          if (SquareContents[move.toPosition].pieceType != Const.EmptyID) {
            // save state
            capturedPiecePosition = move.toPosition;
            capturedPieceType = SquareContents[move.toPosition].pieceType;
            RemovePieceFromBoard(move.toPosition); // it was a capture
          }
          RemovePieceFromBoard(move.fromPosition);
          AddNewPieceToBoard(
              colorToMove,
              Const.QueenID + move.moveType - Const.PawnPromoteQueenID,
              move.toPosition);
          fiftyMoveNr = 0; // pawn move : reset the fiftyMoveNr
          break;
        case Const.Pawn2StepID:
          MovePieceOnBoard(move.fromPosition, move.toPosition);
          // point enPassantPosition to the jumped over square
          enPassantPosition = (move.fromPosition + move.toPosition) >>> 1;
          fiftyMoveNr = 0; // pawn move : reset the fiftyMoveNr
          break;
        case Const.NullMoveID:
          // just do nothing
          break;
        default:
          logPrint("Invalid special move nr");
      }
      // always reset the enPassant pasition, unless it set by the Pawn 2Step move
      if (move.moveType != Const.Pawn2StepID) {
        enPassantPosition = Const.InvalidID;
      }
    }
    // Finally check if this move was legal. If not, it will immediately be undone in SearchMove.
    // Do it with an IF statement, since also castling could have set moveIsLegal to false.
    if (IsInCheck()) moveIsLegal = false;
    //
    ToggleMoveColor();
    // Store the state exactly as it was AFTER this move was made. Also stores HashValue.
    StoreBoardState();

    movesHist.add(move);

    return moveIsLegal;
  }

  UnMakeMove(Move move) {
    int prevColorToMove = colorToMove;
    // This is the color which made the move :
    ToggleMoveColor();
    // decrement the HalfMoveNr
    halfMoveNr--;
    //
    if (move.moveType < Const.SpecialMoveID) {
      // un-make the move
      MovePieceOnBoard(move.toPosition, move.fromPosition);
    } else {
      // Unmake specials
      // it is a Castle, enpassant capture, 2-stap pawn move or pawn promotion
      int castleRankOffset = colorToMove * 56;
      switch (move.moveType) {
        case Const.CastleQSID:
          MovePieceOnBoard(castleRankOffset + 2, castleRankOffset + 4); // King
          MovePieceOnBoard(castleRankOffset + 3, castleRankOffset + 0); // Rook
          break;
        case Const.CastleKSID:
          MovePieceOnBoard(castleRankOffset + 6, castleRankOffset + 4); // King
          MovePieceOnBoard(castleRankOffset + 5, castleRankOffset + 7); // Rook
          break;
        case Const.EnPassantCaptureID:
          MovePieceOnBoard(move.toPosition, move.fromPosition);
          break;
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          RemovePieceFromBoard(move.toPosition); // the promoted piece
          AddNewPieceToBoard(colorToMove, Const.PawnID, move.fromPosition);
          break;
        case Const.Pawn2StepID:
          MovePieceOnBoard(move.toPosition, move.fromPosition);
          //int oldEPPos = (move.toPosition + move.fromPosition) >> 1;
          break;
        case Const.NullMoveID:
          break;
        default:
          logPrint("Invalid special move nr");
      }
    }
    // was it a capture ? Yes : restore the captured piece
    if (capturedPieceType != Const.InvalidID) {
      AddNewPieceToBoard(
          prevColorToMove, capturedPieceType, capturedPiecePosition);
    }
    // Last restore the BoardState as it was just after the move. This also restores the HashValue.
    RestoreBoardState();

    movesHist.removeLast();
  }

  //====
}

//==== Move struct

class Move {
  int fromPosition = 0;
  int toPosition = 0;
  int moveType = 0;

  // bits 0..2  : captured piece type;
  // bits 3..5 : capturing piece type
  int captureInfo = 0; // Constants.NoCaptureID = no capture.
  int seeScore = 0;
}

class MoveDo {
  static Move NoMove() {
    // This returns a Move, which indicates no move has been made.
    Move result = Move();
    result.moveType = Const.NoMoveID;
    return result; // Move
  }

  static Move NullMove() {
    // This returns a Move, which indicates no move has been made.
    Move result = Move();
    result.moveType = Const.NullMoveID;
    result.captureInfo = Const.NoCaptureID;
    return result;
  }

  //====

  //==== operator overrides

  // operator ==
  static bool Eq(Move m1, Move m2) {
    return m2.fromPosition == m1.fromPosition &&
        m2.toPosition == m1.toPosition &&
        m2.moveType == m1.moveType &&
        m2.captureInfo == m1.captureInfo;
  }

  static copy(Move mf, Move mt) {
    mt.fromPosition = mf.fromPosition;
    mt.toPosition = mf.toPosition;
    mt.moveType = mf.moveType;
    mt.captureInfo = mf.captureInfo;
    mt.seeScore = mf.seeScore;
  }

  //====

  //==== Move to String

  static String PositionToString(int pos) {
    int x = pos & 7;
    int y = pos >> 3;
    return String.fromCharCode(97 + x) + String.fromCharCode(49 + y);
  }

  static String PieceTypeToString(int pieceType) {
    return Const.PieceStr[pieceType];
  }

  static String ToString(Move mv, int colorToMove) {
    String s;
    String separator = "-";
    if (mv.captureInfo != Const.NoCaptureID) separator = "x";
    //
    String mo = PositionToString(mv.fromPosition) +
        separator +
        PositionToString(mv.toPosition);

    if (mv.moveType < Const.SpecialMoveID) {
      s = PieceTypeToString(mv.moveType) + mo;
    } else {
      switch (mv.moveType) {
        case Const.CastleQSID:
          s = "0-0-0";
          break;
        case Const.CastleKSID:
          s = "0-0";
          break;
        case Const.EnPassantCaptureID:
          s = "${mo}ep";
          break;
        case Const.PawnPromoteQueenID:
          s = "$mo=Q";
          break;
        case Const.PawnPromoteRookID:
          s = "$mo=R";
          break;
        case Const.PawnPromoteBishopID:
          s = "$mo=B";
          break;
        case Const.PawnPromoteKnightID:
          s = "$mo=N";
          break;
        case Const.Pawn2StepID:
          s = mo;
          break;
        default:
          s = "????";
          break;
      }
    }
    return s;
  }

  static String ToUCIString(Move mv) {
    String result = EPD.PositionToString(mv.fromPosition) +
        EPD.PositionToString(mv.toPosition);
    if (mv.moveType >= Const.PawnPromoteQueenID &&
        mv.moveType <= Const.PawnPromoteKnightID) {
      result += EPD.PromotionPieceToString(mv.moveType);
    }
    return result;
  }

  //====
}

//====

class MoveGenerator {
  // pointers to other classes
  late Board board;
  late MagicMoves magicMoves;
  late BitBoard bitboard;
  late Attack attack;

  bool noNegativeSEECaptures = true;

  //==== data

  List<Move> movelist = []; //Move[]

  // Just a 1 at the position bit, a 0 on all other bits
  // { for normal bitboard : 64 bit : starting from A1..H1, B2..H2 ,,,,,,, A8..H8 ]
  //U64[Const.NrSquares]

  static const KingDirections = [-9, -8, -7, -1, 1, 7, 8, 9];
  static const KingXDirections = [-1, 0, 1, -1, 1, -1, 0, 1];
  static const KingYDirections = [-1, -1, -1, 0, 0, 1, 1, 1];
  static const QueenDirections = [-8, -1, 1, 8, -9, -7, 7, 9];
  static const BishopDirections = [-9, -7, 7, 9];
  static const RookDirections = [-8, -1, 1, 8];
  static const KnightDirections = [-17, -15, -10, -6, 17, 15, 10, 6];
  static const KnightXDirections = [-1, 1, -2, 2, 1, -1, 2, -2];
  static const KnightYDirections = [-2, -2, -1, -1, 2, 2, 1, 1];

  static const PawnDelta = [8, -8]; // 1 pawn-step
  static const PawnFrom2StepRank = [
    1,
    6
  ]; // rank from which a 2-step is possible
  static const PawnPromotionToRank = [7, 0]; // rank on which pawn is promoted
  static const PawnPromotionFromRank = [
    6,
    1
  ]; // rank from which a pawn gets promoted

  //U64[Const.NrSquares]
  var EmptyBoardKingMoves = List.filled(Const.NrSquares, 0);
  var EmptyBoardKnightMoves = List.filled(Const.NrSquares, 0);

  //U64[Const.NrColors, Const.NrSquares]
  var EmptyBoardPawn1StepMoves = [
    List.filled(Const.NrSquares, 0),
    List.filled(Const.NrSquares, 0)
  ];
  var EmptyBoardPawn2StepMoves = [
    List.filled(Const.NrSquares, 0),
    List.filled(Const.NrSquares, 0)
  ];

  // castle stuff
  //U64[Const.NrColors]
  var CastleEmptySquaresQS = [0, 0]; // squares between king & rook
  var CastleEmptySquaresKS = [0, 0];
  var CastleUnattackedSquaresQS = [0, 0]; // king square + 2 squares next to it
  var CastleUnattackedSquaresKS = [0, 0];
  var CastleRookPositionQS = [0, 0];
  var CastleRookPositionKS = [0, 0];

  //====

  MoveGenerator() {
    GenerateEmptyBoardKingMoves();
    GenerateEmptyBoardKnightMoves();
    GenerateEmptyBoardPawn1StepMoves();
    GenerateEmptyBoardPawn2StepMoves();
    //
    GenerateCastleSquares();
  }

  //====  some helper bitboards : Castle

  GenerateCastleSquares() {
    // white
    // these square must be empty
    CastleEmptySquaresQS[Const.White] =
        BitBoard.Identity[1] | BitBoard.Identity[2] | BitBoard.Identity[3];
    CastleEmptySquaresKS[Const.White] =
        BitBoard.Identity[5] | BitBoard.Identity[6];
    // these square may not be under attack
    CastleUnattackedSquaresQS[Const.White] =
        BitBoard.Identity[2] | BitBoard.Identity[3] | BitBoard.Identity[4];
    CastleUnattackedSquaresKS[Const.White] =
        BitBoard.Identity[4] | BitBoard.Identity[5] | BitBoard.Identity[6];
    //
    // black
    // these square must be empty
    CastleEmptySquaresQS[Const.Black] =
        BitBoard.Identity[57] | BitBoard.Identity[58] | BitBoard.Identity[59];
    CastleEmptySquaresKS[Const.Black] =
        BitBoard.Identity[61] | BitBoard.Identity[62];
    // these square may not be under attack
    CastleUnattackedSquaresQS[Const.Black] =
        BitBoard.Identity[58] | BitBoard.Identity[59] | BitBoard.Identity[60];
    CastleUnattackedSquaresKS[Const.Black] =
        BitBoard.Identity[60] | BitBoard.Identity[61] | BitBoard.Identity[62];
    //
    // The squares where a rook of the right color must be present for castling
    CastleRookPositionQS[Const.White] = 0;
    CastleRookPositionKS[Const.White] = 7;
    CastleRookPositionQS[Const.Black] = 56;
    CastleRookPositionKS[Const.Black] = 63;
  }

  //====

  //==== Generate moves for non-sliding pieces on an empty board

  GenerateEmptyBoardKnightMoves() {
    for (int i = 0; i < Const.NrSquares; i++) {
      EmptyBoardKnightMoves[i] = 0;
      for (int j = 0; j < 8; j++) {
        int x = (i & 7) + KnightXDirections[j];
        int y = (i >> 3) + KnightYDirections[j];
        if (x >= 0 && x <= 7 && y >= 0 && y <= 7) {
          int position = x + (y << 3);
          EmptyBoardKnightMoves[i] |= BitBoard.Identity[position];
        }
      }
    }
  }

  GenerateEmptyBoardKingMoves() {
    for (int i = 0; i < Const.NrSquares; i++) {
      EmptyBoardKingMoves[i] = 0;
      for (int j = 0; j < 8; j++) {
        int x = (i & 7) + KingXDirections[j];
        int y = (i >> 3) + KingYDirections[j];
        if (x >= 0 && x <= 7 && y >= 0 && y <= 7) {
          int position = x + (y << 3);
          EmptyBoardKingMoves[i] |= BitBoard.Identity[position];
        }
      }
    }
  }

  GenerateEmptyBoardPawn1StepMoves() {
    // white
    for (int i = 0; i < Const.NrSquares; i++) {
      if (i >= 8 && i <= 55) {
        EmptyBoardPawn1StepMoves[Const.White][i] = BitBoard.Identity[i + 8];
      } else {
        EmptyBoardPawn1StepMoves[Const.White][i] = 0;
      }
    }
    // black
    for (int i = 0; i < Const.NrSquares; i++) {
      if (i >= 8 && i <= 55) {
        EmptyBoardPawn1StepMoves[Const.Black][i] = BitBoard.Identity[i - 8];
      } else {
        EmptyBoardPawn1StepMoves[Const.Black][i] = 0;
      }
    }
  }

  GenerateEmptyBoardPawn2StepMoves() {
    // white
    for (int i = 0; i < Const.NrSquares; i++) {
      if (i >= 8 && i <= 15) {
        EmptyBoardPawn2StepMoves[Const.White][i] = BitBoard.Identity[i + 16];
      } else {
        EmptyBoardPawn2StepMoves[Const.White][i] = 0;
      }
    }
    // black
    for (int i = 0; i < Const.NrSquares; i++) {
      if (i >= 48 && i <= 55) {
        EmptyBoardPawn2StepMoves[Const.Black][i] = BitBoard.Identity[i - 16];
      } else {
        EmptyBoardPawn2StepMoves[Const.Black][i] = 0;
      }
    }
  }

  //====

  //==== Generate ALL moves for each piece type

  AddMove(int moveType, int fromPos, int toPos) {
    Move Obj = Move();

    Obj.moveType = moveType;
    Obj.fromPosition = fromPos;
    Obj.toPosition = toPos;
    // don't know yet how to handle promotions in seeScore
    Obj.seeScore = 0; // will be filled later
    // store the possible captured piece :
    if (moveType < Const.SpecialMoveID) {
      // this can be EmptyID or some PieceType
      int capturedPieceType = board.SquareContents[toPos].pieceType;
      //
      if (capturedPieceType == Const.EmptyID) {
        Obj.captureInfo = Const.NoCaptureID;
      } else {
        // yes, it is a capture.
        // Store the captured piece type in bits 0..2, and the capturing piece type in bits 3..5
        Obj.captureInfo = capturedPieceType +
            (board.SquareContents[fromPos].pieceType << Const.NrPieceTypeBits);
        // also store the SEE score
        Obj.seeScore = attack.SEE(moveType, fromPos, toPos);
      }
    } else {
      switch (moveType) {
        case Const.EnPassantCaptureID:
          Obj.captureInfo =
              Const.PawnID + (Const.PawnID << Const.NrPieceTypeBits);
          Obj.seeScore = attack.SEE(moveType, fromPos, toPos);
          break;
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          // this can be EmptyID or some PieceType
          // this can be EmptyID or some PieceType
          int capturedPieceType = board.SquareContents[toPos].pieceType;
          //
          if (capturedPieceType == Const.EmptyID) {
            Obj.captureInfo = Const.NoCaptureID;
          } else {
            // yes, it is a capture.
            // Store the captured piece type in bits 0..2,  and the capturing piece type in bits 3..5
            Obj.captureInfo = capturedPieceType +
                (board.SquareContents[fromPos].pieceType <<
                    Const.NrPieceTypeBits);
          }
          break;
        default:
          Obj.captureInfo = Const.NoCaptureID;
          break;
      }
    }
    movelist.add(Obj);
  }

  GenerateKingMoves() {
    // local copies :
    //U64
    int myPieces = board.pieces[board.colorToMove]; //U64
    //U64
    int position = board.PiecePos[board.colorToMove][Const.KingID][0];
    int kingMoves = EmptyBoardKingMoves[position] & (~myPieces);
    //
    while (kingMoves != 0) {
      int bitNr = bitboard.LSB(kingMoves);
      kingMoves &= ~BitBoard.Identity[bitNr]; // reset
      AddMove(Const.KingID, position, bitNr);
    }
  }

  bool CastleIsLegal(int castleType) {
    // checks if the squares between the king and rook are empty and
    // the king square and the 2 next to it are not attacked.
    // It is called by MakeMove AFTER the castle is made, to see if it was a legal move.
    //
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyColor = board.enemyColor;
    //U64
    int attackedBitBoard = attack.GetAttackedSquaresBitBoard(enemyColor);
    if (castleType == Const.CastleQSID) {
      // QueenSide
      return (CastleUnattackedSquaresQS[colorToMove] & attackedBitBoard) == 0;
    } else if (castleType == Const.CastleKSID) {
      return (CastleUnattackedSquaresKS[colorToMove] & attackedBitBoard) == 0;
    } else
      logPrint("Invalid CastleType");
    return false;
  }

  GenerateCastleMoves() {
    // The check to see if the castle is legal, i.e. the squares are not under attack
    // is performed in MakeMove.
    // local copies :
    int colorToMove = board.colorToMove;
    int castleRankOffset = colorToMove * 56; // first square-nr of King rank
    //
    if (board.canCastleQueenSide[colorToMove] ||
        board.canCastleKingSide[colorToMove]) {
      // QueenSide
      int rookSquare = CastleRookPositionQS[colorToMove];
      if (board.canCastleQueenSide[colorToMove] &&
          (CastleEmptySquaresQS[colorToMove] & board.allPiecesBB) == 0 &&
          board.SquareContents[rookSquare].pieceType == Const.RookID &&
          board.SquareContents[rookSquare].pieceColor == colorToMove) {
        AddMove(Const.CastleQSID, castleRankOffset + 4,
            castleRankOffset + 2); // King moves
      }
      // KingSide
      rookSquare = CastleRookPositionKS[colorToMove];
      if (board.canCastleKingSide[colorToMove] &&
          (CastleEmptySquaresKS[colorToMove] & board.allPiecesBB) == 0 &&
          board.SquareContents[rookSquare].pieceType == Const.RookID &&
          board.SquareContents[rookSquare].pieceColor == colorToMove) {
        AddMove(Const.CastleKSID, castleRankOffset + 4,
            castleRankOffset + 6); // King moves
      }
    }
  }

  GenerateQueenMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int myPieces = board.pieces[colorToMove]; //U64
    //
    for (int queenNr = 0;
        queenNr < board.NrPieces[colorToMove][Const.QueenID];
        queenNr++) {
      int position = board.PiecePos[colorToMove][Const.QueenID][queenNr];
      int queenMoves =
          magicMoves.Qmagic(position, board.allPiecesBB) & ~myPieces;
      while (queenMoves != 0) {
        int bitNr = bitboard.LSB(queenMoves);
        queenMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddMove(Const.QueenID, position, bitNr);
      }
    }
  }

  GenerateRookMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int myPieces = board.pieces[colorToMove]; //U64
    //
    for (int rookNr = 0;
        rookNr < board.NrPieces[colorToMove][Const.RookID];
        rookNr++) {
      int position = board.PiecePos[colorToMove][Const.RookID][rookNr];
      int rookMoves =
          magicMoves.Rmagic(position, board.allPiecesBB) & ~myPieces;
      //
      while (rookMoves != 0) {
        int bitNr = bitboard.LSB(rookMoves);
        rookMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddMove(Const.RookID, position, bitNr);
      }
    }
  }

  GenerateBishopMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int myPieces = board.pieces[colorToMove]; //U64
    //
    for (int bishopNr = 0;
        bishopNr < board.NrPieces[colorToMove][Const.BishopID];
        bishopNr++) {
      int position = board.PiecePos[colorToMove][Const.BishopID][bishopNr];
      int bishopMoves =
          magicMoves.Bmagic(position, board.allPiecesBB) & ~myPieces;
      //
      while (bishopMoves != 0) {
        int bitNr = bitboard.LSB(bishopMoves);
        bishopMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddMove(Const.BishopID, position, bitNr);
      }
    }
  }

  GenerateKnightMoves() {
    // local copies
    int colorToMove = board.colorToMove;
    int myPieces = board.pieces[colorToMove]; //U64
    //
    for (int knightNr = 0;
        knightNr < board.NrPieces[colorToMove][Const.KnightID];
        knightNr++) {
      int position = board.PiecePos[colorToMove][Const.KnightID][knightNr];
      int knightMoves = EmptyBoardKnightMoves[position] & ~myPieces;
      //
      while (knightMoves != 0) {
        int bitNr = bitboard.LSB(knightMoves);
        knightMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddMove(Const.KnightID, position, bitNr);
      }
    }
  }

  GeneratePawnMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int myPieces = board.pieces[colorToMove]; //U64
    int AllAndEp = board.allPiecesBB |
        (board.enPassantPosition < 0
            ? 0
            : BitBoard.Identity[board.enPassantPosition]);

    //
    for (int pawnNr = 0;
        pawnNr < board.NrPieces[colorToMove][Const.PawnID];
        pawnNr++) {
      int position = board.PiecePos[colorToMove][Const.PawnID][pawnNr];

      int pawnMoves = (colorToMove == Const.White
              ? magicMoves.WhitePawnMove(position, AllAndEp)
              : magicMoves.BlackPawnMove(position, AllAndEp)) &
          ~myPieces;
      //

      while (pawnMoves != 0) {
        int bitNr = bitboard.LSB(pawnMoves);
        pawnMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddPawnMove(position, bitNr);
      }
    }
  }

  AddPawnMove(int fromPos, int ToPos) {
    // local copies :
    int colorToMove = board.colorToMove;

    // add a pawn move, which can both be a normal pawn move, or a pawn promotion
    if ((ToPos >> 3) == PawnPromotionToRank[colorToMove]) {
      AddMove(Const.PawnPromoteQueenID, fromPos, ToPos);
      AddMove(Const.PawnPromoteRookID, fromPos, ToPos);
      AddMove(Const.PawnPromoteBishopID, fromPos, ToPos);
      AddMove(Const.PawnPromoteKnightID, fromPos, ToPos);
    } else {
      // enpassant capture ?
      if (board.enPassantPosition == ToPos) {
        AddMove(Const.EnPassantCaptureID, fromPos, board.enPassantPosition);
      } else {
        AddMove(Const.PawnID, fromPos, ToPos);
      }
    }
  }

  // movelist should be defined
  GenerateMoves(List<Move> initMoveList) {
    movelist = initMoveList;
    // Now generate pseudo legal moves. No check for getting into Check !

    GenerateKingMoves();
    GenerateCastleMoves();
    GenerateQueenMoves();
    GenerateRookMoves();
    GenerateBishopMoves();
    GenerateKnightMoves();
    GeneratePawnMoves();
  }

  //====

  //==== Generate Quiescence moves : captures, pawn promotions

  AddQuiescenceMove(int moveType, int fromPos, int toPos) {
    Move Obj = Move();

    Obj.moveType = moveType;
    Obj.fromPosition = fromPos;
    Obj.toPosition = toPos;
    Obj.seeScore = 0; // filled in later
    //
    // store the possible captured piece :
    if (moveType < Const.SpecialMoveID) {
      // this can be EmptyID or some PieceType
      int capturedPieceType = board.SquareContents[toPos].pieceType;
      //
      if (capturedPieceType == Const.EmptyID) {
        Obj.captureInfo = Const.NoCaptureID;
      } else {
        // yes, it is a capture.
        // Store the captured piece type in bits 0..2, and the capturing piece type in bits 3..5
        Obj.captureInfo = capturedPieceType +
            (board.SquareContents[fromPos].pieceType << Const.NrPieceTypeBits);
        // also store the SEE-score
        Obj.seeScore = attack.SEE(moveType, fromPos, toPos);
      }
    } else {
      switch (moveType) {
        case Const.EnPassantCaptureID:
          Obj.captureInfo =
              Const.PawnID + (Const.PawnID << Const.NrPieceTypeBits);
          Obj.seeScore = attack.SEE(moveType, fromPos, toPos);
          break;
        case Const.PawnPromoteQueenID:
        case Const.PawnPromoteRookID:
        case Const.PawnPromoteBishopID:
        case Const.PawnPromoteKnightID:
          // this can be EmptyID or some PieceType
          // this can be EmptyID or some PieceType
          int capturedPieceType = board.SquareContents[toPos].pieceType;
          //
          if (capturedPieceType == Const.EmptyID) {
            Obj.captureInfo = Const.NoCaptureID;
          } else {
            // yes, it is a capture.
            // Store the captured piece type in bits 0..2,  and the capturing piece type in bits 3..5
            Obj.captureInfo = capturedPieceType +
                (board.SquareContents[fromPos].pieceType <<
                    Const.NrPieceTypeBits);
          }
          break;
        default:
          Obj.captureInfo = Const.NoCaptureID;
          break;
      }
    }
    // maybe abort here, if captures with negative SEE is excluded
    if (noNegativeSEECaptures && !(moveType >= Const.SpecialMoveID)) {
      // moveType>=Const.SpecialMoveID : always do special stuff.
      // This also means that en-passant captures are never filtered out !
      // Also : SEE has problems with promotions or so
      if (Obj.seeScore < 0) return;
    }

    movelist.add(Obj);
  }

  GenerateCapturingKingMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    int position = board.PiecePos[colorToMove][Const.KingID][0];
    int kingMoves = EmptyBoardKingMoves[position] & enemyPieces;
    //
    while (kingMoves != 0) {
      int bitNr = bitboard.LSB(kingMoves);
      kingMoves &= ~BitBoard.Identity[bitNr]; // reset
      AddQuiescenceMove(Const.KingID, position, bitNr);
    }
  }

  GenerateCapturingQueenMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    for (int queenNr = 0;
        queenNr < board.NrPieces[colorToMove][Const.QueenID];
        queenNr++) {
      int position = board.PiecePos[colorToMove][Const.QueenID][queenNr];
      int queenMoves =
          magicMoves.Qmagic(position, board.allPiecesBB) & enemyPieces;
      while (queenMoves != 0) {
        int bitNr = bitboard.LSB(queenMoves);
        queenMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddQuiescenceMove(Const.QueenID, position, bitNr);
      }
    }
  }

  GenerateCapturingRookMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    for (int rookNr = 0;
        rookNr < board.NrPieces[colorToMove][Const.RookID];
        rookNr++) {
      int position = board.PiecePos[colorToMove][Const.RookID][rookNr];
      int rookMoves =
          magicMoves.Rmagic(position, board.allPiecesBB) & enemyPieces;
      //
      while (rookMoves != 0) {
        int bitNr = bitboard.LSB(rookMoves);
        rookMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddQuiescenceMove(Const.RookID, position, bitNr);
      }
    }
  }

  GenerateCapturingBishopMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    for (int bishopNr = 0;
        bishopNr < board.NrPieces[colorToMove][Const.BishopID];
        bishopNr++) {
      int position = board.PiecePos[colorToMove][Const.BishopID][bishopNr];
      int bishopMoves =
          magicMoves.Bmagic(position, board.allPiecesBB) & enemyPieces;
      //
      while (bishopMoves != 0) {
        int bitNr = bitboard.LSB(bishopMoves);
        bishopMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddQuiescenceMove(Const.BishopID, position, bitNr);
      }
    }
  }

  GenerateCapturingKnightMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    for (int knightNr = 0;
        knightNr < board.NrPieces[colorToMove][Const.KnightID];
        knightNr++) {
      int position = board.PiecePos[colorToMove][Const.KnightID][knightNr];
      int knightMoves = EmptyBoardKnightMoves[position] & enemyPieces;
      //
      while (knightMoves != 0) {
        int bitNr = bitboard.LSB(knightMoves);
        knightMoves &= ~BitBoard.Identity[bitNr]; // reset
        AddQuiescenceMove(Const.KnightID, position, bitNr);
      }
    }
  }

  GenerateCapturingPawnMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int enemyPieces = board.pieces[board.enemyColor]; //U64
    //
    for (int pawnNr = 0;
        pawnNr < board.NrPieces[colorToMove][Const.PawnID];
        pawnNr++) {
      int position = board.PiecePos[colorToMove][Const.PawnID][pawnNr];
      //
      // Capture ?
      if ((bitboard.PawnAttackBB1[colorToMove][position] & enemyPieces) != 0) {
        // left and/or right
        int x = position & 7;
        if (colorToMove == 0) {
          // white , capture left
          if (x > 0 && (BitBoard.Identity[position + 7] & enemyPieces) != 0) {
            AddQuiescenceMove(Const.PawnID, position, position + 7);
          }
          // capture right
          if (x < 7 && (BitBoard.Identity[position + 9] & enemyPieces) != 0) {
            AddQuiescenceMove(Const.PawnID, position, position + 9);
          }
        } else {
          // black , capture left
          if (x > 0 && (BitBoard.Identity[position - 9] & enemyPieces) != 0) {
            AddQuiescenceMove(Const.PawnID, position, position - 9);
          }
          // capture right
          if (x < 7 && (BitBoard.Identity[position - 7] & enemyPieces) != 0) {
            AddQuiescenceMove(Const.PawnID, position, position - 7);
          }
        }
      }
      // enpassant capture ?
      if (board.enPassantPosition >= 0) {
        if ((bitboard.PawnAttackBB1[colorToMove][position] &
                BitBoard.Identity[board.enPassantPosition]) !=
            0) {
          AddQuiescenceMove(
              Const.EnPassantCaptureID, position, board.enPassantPosition);
        }
      }
    }
  }

  GeneratePromotingPawnMoves() {
    // local copies :
    int colorToMove = board.colorToMove;
    int allPieces = board.allPiecesBB; //U64
    //
    for (int pawnNr = 0;
        pawnNr < board.NrPieces[colorToMove][Const.PawnID];
        pawnNr++) {
      int position = board.PiecePos[colorToMove][Const.PawnID][pawnNr];
      int fromRank = position >> 3;
      if (fromRank == PawnPromotionFromRank[colorToMove]) {
        int Pawn1StepMove =
            EmptyBoardPawn1StepMoves[colorToMove][position]; //U64
        // Pawn1StepMove has only 1 bit set if it is on a legal rank, and 0 bits otherwise
        // Check if a 1 step move is possible (rank != 0 && 7)
        // and check if the new fields is not blocked
        if (Pawn1StepMove != 0 && (Pawn1StepMove & allPieces) == 0) {
          // pawn promotion
          int ToPos = position + PawnDelta[colorToMove];
          // Use only promotion to queen.
          // The other onces are only extremely seldom useful (like avoiding a stalemate).
          AddQuiescenceMove(Const.PawnPromoteQueenID, position, ToPos);
          //       AddQuiescenceMove(Const.PawnPromoteRookID, position, ToPos);
          //       AddQuiescenceMove(Const.PawnPromoteBishopID, position, ToPos);
          //       AddQuiescenceMove(Const.PawnPromoteKnightID, position, ToPos);
        }
      }
    }
  }

  GenerateQuiescenceMoves(List<Move> initMoveList) {
    // This generates only captures and pawn promotions
    movelist = initMoveList;

    // Now generate pseudo legal moves. No check for getting into Check !

    GenerateCapturingKingMoves();
    GenerateCapturingQueenMoves();
    GenerateCapturingRookMoves();
    GenerateCapturingBishopMoves();
    GenerateCapturingKnightMoves();
    GenerateCapturingPawnMoves();
    GeneratePromotingPawnMoves();
  }

  //====
}

class MagicMoves {
// MoveGen arrays

  static const B2G7 = 0x007E7E7E7E7E7E00;

  var BishopMask = List.filled(64, 0); //U64
  var RookMask = List.filled(64, 0); //U64

  List<List<int>> BishopLegalsTable = []; //[64][1<<10]
  List<List<int>> RookLegalsTable = []; //[64][1<<15]

  var PawnMaskWhite = List.filled(64, 0); //U64
  var PawnMaskBlack = List.filled(64, 0); //U64

  List<List<int>> PawnWhiteLegalsTable = []; //[64][1<<4]
  List<List<int>> PawnBlackLegalsTable = []; //[64][1<<4]

  List<int> Magic_wp_mult = []; //[64]
  List<int> Magic_bp_mult = []; //[64]

// Square attacked by opposite pawns
  var PawnWhiteAtck = List.filled(64, 0); //U64
  var PawnBlackAtck = List.filled(64, 0); //U64

// ---------------------- prepares arrays
//
// variables one-time, but needed

  int Bo1 = 0, Bo2 = 0; // U64 boards
  int SqI = 0; //U8 square to prepare
  int b_r = 0; //U8 1-bishops, 0-rooks
  int b_w = 0; //U8 1-black, 0-white (for pawns)

  bool legalck = false; //U8 Calculate: 0-allmoves-rays, 1-legalmoves

// -------

  MagicMoves() {
    int mult;
    for (int i = 0; i < 64; i++) {
      BishopLegalsTable.add(List.filled(1 << Magics.Shift_bishops[i], 0));
      RookLegalsTable.add(List.filled(1 << Magics.Shift_rooks[i], 0));
      PawnWhiteLegalsTable.add(List.filled(1 << 4, 0));
      PawnBlackLegalsTable.add(List.filled(1 << 4, 0));
      mult = Magics.Magic_wp[i];
      Magic_wp_mult.add((mult << 32) | mult);
      mult = Magics.Magic_bp[i];
      Magic_bp_mult.add((mult << 32) | mult);
    }
    prepare_tables();
  }

  gdir(int dv, int dh, bool loop) {
    int V = (SqI >> 3), H = (SqI & 7);
    V += dv;
    H += dh;
    while ((V >= 0 && V < 8) && (H >= 0 && H < 8)) {
      int sq = (V << 3) | H;
      int B = (1 << sq); //U64
      if (legalck) {
        Bo2 |= B;
        if ((Bo1 & B) != 0) return;
      } else {
        Bo1 |= B;
      }
      if (!loop) return;
      V += dv;
      H += dh;
    }
  }

  gen2dir() {
    if (b_r != 0) {
      //bishops
      gdir(-1, -1, true);
      gdir(1, -1, true);
      gdir(-1, 1, true);
      gdir(1, 1, true);
    } else {
      // rooks
      gdir(-1, 0, true);
      gdir(1, 0, true);
      gdir(0, 1, true);
      gdir(0, -1, true);
    }
  }

  bool BoSet(int sq, bool capt) {
    bool b = false;
    int B = (1 << sq); //U64
    if (legalck) {
      if ((Bo1 & B) != 0) b = true;
      if (capt == b) Bo2 |= B;
    } else {
      Bo1 |= B;
    }
    return b;
  }

  gen_pawnmoves() {
    int V = (SqI >> 3), H = (SqI & 7);
    if (V > 0 && V < 7) {
      if (b_w != 0) {
        V--;
      } else {
        V++;
      }

      int sq = (V << 3) | H;
      bool f = BoSet(sq, false);
      if (H > 0) BoSet(sq - 1, true);
      if (H < 7) BoSet(sq + 1, true);
      if (!f) {
        if (b_w != 0) {
          if (V == 5) BoSet(sq - 8, false);
        } else {
          if (V == 2) BoSet(sq + 8, false);
        }
      }
    }
  }

  gen_pawn_atck() {
    int V = (SqI >> 3), H = (SqI & 7);
    if (b_w != 0) {
      V++;
    } else {
      V--;
    }
    if (V > 0 && V < 7) {
      int sq = (V << 3) | H;
      if (H > 0) BoSet(sq - 1, true);
      if (H < 7) BoSet(sq + 1, true);
    }
  }

// Scan occupancy cases
  Permutate(bool pawncase) {
    int mult = 0; //U64
    int idx_16 = 0; //U16
    int idx_8 = 0; //U8

    var bits = List.filled(64, 0);
    int n = 0, sq = 0;
    for (; sq < 64; sq++) {
      if ((Bo1 & (1 << sq)) != 0) bits[n++] = sq;
    }

    int LEN = (1 << n); //U16
    for (int i = 0; i < LEN; i++) {
      Bo1 = 0;
      for (int j = 0; j < n; j++) // scan as bits
      {
        if ((i & (1 << j)) != 0) Bo1 |= (1 << bits[j]);
      }

      Bo2 = 0; // find legal moves for square, put in Bo2

      if (pawncase) {
        if (b_w != 0) {
          mult = Bo1 * Magic_bp_mult[SqI];
          idx_8 = mult >>> 60;
          gen_pawnmoves();
          PawnBlackLegalsTable[SqI][idx_8] = Bo2;
        } else {
          mult = Bo1 * Magic_wp_mult[SqI];
          idx_8 = mult >>> 60;
          gen_pawnmoves();
          PawnWhiteLegalsTable[SqI][idx_8] = Bo2;
        }
      } else {
        if (b_r != 0) {
          mult = Bo1 * Magics.Magic_bishops[SqI];
          idx_16 = mult >>> (64 - Magics.Shift_bishops[SqI]);
          gen2dir();
          BishopLegalsTable[SqI][idx_16] = Bo2;
        } else {
          mult = Bo1 * Magics.Magic_rooks[SqI];
          idx_16 = mult >>> (64 - Magics.Shift_rooks[SqI]);
          gen2dir();
          RookLegalsTable[SqI][idx_16] = Bo2;
        }
      }
    }
  }

  prepare_tables() {
    for (SqI = 0; SqI < 64; SqI++) {
      for (b_r = 0; b_r < 2; b_r++) {
        legalck = false;
        Bo1 = 0;
        gen2dir();
        if (((1 << SqI) & B2G7) != 0) Bo1 &= B2G7;
        if (b_r != 0) {
          BishopMask[SqI] = Bo1;
        } else {
          RookMask[SqI] = Bo1;
        }
        legalck = true;
        Permutate(false);
      }

      for (b_w = 0; b_w < 2; b_w++) {
        legalck = false;
        Bo1 = 0;
        gen_pawnmoves();
        if (b_w != 0) {
          PawnMaskBlack[SqI] = Bo1;
        } else {
          PawnMaskWhite[SqI] = Bo1;
        }
        legalck = true;
        Permutate(true);

        legalck = false;
        Bo1 = 0;
        gen_pawn_atck();
        if (b_w != 0) {
          PawnBlackAtck[SqI] = Bo1;
        } else {
          PawnWhiteAtck[SqI] = Bo1;
        }
      }
    }
  }

  //U64
  int Bmagic(int square, int occupancy) {
    return BishopLegalsTable[square][
        ((occupancy & BishopMask[square]) * Magics.Magic_bishops[square]) >>>
            (64 - Magics.Shift_bishops[square])];
  }

  //U64
  int Rmagic(int square, int occupancy) {
    return RookLegalsTable[square][
        ((occupancy & RookMask[square]) * Magics.Magic_rooks[square]) >>>
            (64 - Magics.Shift_rooks[square])];
  }

  //U64
  int Qmagic(int square, int occupancy) {
    return Bmagic(square, occupancy) | Rmagic(square, occupancy);
  }

  //U64   (shift 60=64-4)
  int WhitePawnMove(int square, int occupancy) {
    return PawnWhiteLegalsTable[square]
        [((occupancy & PawnMaskWhite[square]) * Magic_wp_mult[square]) >>> 60];
  }

  int BlackPawnMove(int square, int occupancy) {
    return PawnBlackLegalsTable[square]
        [((occupancy & PawnMaskBlack[square]) * Magic_bp_mult[square]) >>> 60];
  }
}

class Attack {
  late Board board;
  late BitBoard bitBoard;
  late MagicMoves magicMoves;
  late Evaluator evaluator;
  late MoveGenerator moveGenerator;

  Attack();

  // Returns a bitboard with all squares which are attacked by the specified color.
  // These squares include empty squares, own pieces and enemy pieces.

  // movingColor is the color which attacks.
  int GetAttackedSquaresBitBoard(int movingColor) //U64
  {
    // Returns a bitboard with all squares which can be attacked by the movingColor
    int result = 0; //U64
    // local copies
    int allPieces = board.allPiecesBB; //U64
    // by king
    result |= moveGenerator
        .EmptyBoardKingMoves[board.PiecePos[movingColor][Const.KingID][0]];
    // by queens
    for (int queenNr = 0;
        queenNr < board.NrPieces[movingColor][Const.QueenID];
        queenNr++) {
      int position = board.PiecePos[movingColor][Const.QueenID][queenNr];
      result |= magicMoves.Qmagic(position, allPieces);
    }
    // by rooks
    for (int rookNr = 0;
        rookNr < board.NrPieces[movingColor][Const.RookID];
        rookNr++) {
      int position = board.PiecePos[movingColor][Const.RookID][rookNr];
      result |= magicMoves.Rmagic(position, allPieces);
    }
    // by bishops
    for (int bishopNr = 0;
        bishopNr < board.NrPieces[movingColor][Const.BishopID];
        bishopNr++) {
      int position = board.PiecePos[movingColor][Const.BishopID][bishopNr];
      result |= magicMoves.Bmagic(position, allPieces);
    }
    // by knights
    for (int knightNr = 0;
        knightNr < board.NrPieces[movingColor][Const.KnightID];
        knightNr++) {
      result |= moveGenerator.EmptyBoardKnightMoves[board.PiecePos[movingColor]
          [Const.KnightID][knightNr]];
    }
    // by pawns : excluding en-passant
    for (int pawnNr = 0;
        pawnNr < board.NrPieces[movingColor][Const.PawnID];
        pawnNr++) {
      result |= bitBoard.PawnAttackBB1[movingColor]
          [board.PiecePos[movingColor][Const.PawnID][pawnNr]];
    }
    //
    return result;
  }

  // Gets a bitboard with the position of all pieces of the specified color,
  // which attack/defends the specified square.

  // Param1:The square which should be attacked/defended.
  // Param2:The color which attacks/defends the square
  // Returns a bitboard with all the attacking/defending pieces.
  int GetAttackingDefendingPiecesBitBoard(int color, int squareNr) //U64
  {
    // Use the attack symmetry:  Pretend square is all piece types,
    // and see if it can capture the corresponding enemy piece type.
    int result = 0; //U64
    // The sliding pieces
    // pretend the square is a bishop. Get all squares it could attack.
    int attackBB = magicMoves.Bmagic(squareNr, board.allPiecesBB);
    // check whetter it includes an enemy Queen or Bishop
    result |= attackBB &
        (board.pieceBB[color][Const.QueenID] |
            board.pieceBB[color][Const.BishopID]);
    // pretend the square is a rook. Get all squares it could attack.
    attackBB = magicMoves.Rmagic(squareNr, board.allPiecesBB);
    // check whetter it includes an enemy Queen or Rook
    result |= attackBB &
        (board.pieceBB[color][Const.QueenID] |
            board.pieceBB[color][Const.RookID]);
    // The non-sliding pieces
    // pretend the square is a Knight. Get all squares it could attack. See if it includes an enemy Knight.
    result |= moveGenerator.EmptyBoardKnightMoves[squareNr] &
        board.pieceBB[color][Const.KnightID];
    // pretend the square is a Pawn. Get all squares it could attack. See if it includes an enemy pawn.
    // (the EmptyBoardPawnCatchMoves does _not_ include en-passant capturing, so ok).
    result |= bitBoard.PawnAttackBB1[color ^ 1][squareNr] &
        board.pieceBB[color][Const.PawnID];
    // pretend the square is a King. Get all squares it could attack. See if it includes the enemy King.
    result |= moveGenerator.EmptyBoardKingMoves[squareNr] &
        board.pieceBB[color][Const.KingID];
    //
    return result;
  }

  // Gets a bitboard with the position of all pieces of both colors, which attack/defends the specified square.

  int GetAttackingDefendingPiecesBitBoard2(int squareNr) //U64
  {
    // Use the attack symmetry:  Pretend square is all piece types,
    // and see if it can capture the corresponding enemy piece type.
    int result = 0; //U64
    // The sliding pieces
    // pretend the square is a bishop. Get all squares it could attack.
    int attackBB = magicMoves.Bmagic(squareNr, board.allPiecesBB);
    // check whetter it includes an enemy Queen or Bishop
    result |= attackBB &
        (board.pieceBB[Const.White][Const.QueenID] |
            board.pieceBB[Const.White][Const.BishopID] |
            board.pieceBB[Const.Black][Const.QueenID] |
            board.pieceBB[Const.Black][Const.BishopID]);
    // pretend the square is a rook. Get all squares it could attack.
    attackBB = magicMoves.Rmagic(squareNr, board.allPiecesBB);
    // check whetter it includes an enemy Queen or Rook
    result |= attackBB &
        (board.pieceBB[Const.White][Const.QueenID] |
            board.pieceBB[Const.White][Const.RookID] |
            board.pieceBB[Const.Black][Const.QueenID] |
            board.pieceBB[Const.Black][Const.RookID]);
    // The non-sliding pieces
    // pretend the square is a Knight. Get all squares it could attack. See if it includes an enemy Knight.
    result |= moveGenerator.EmptyBoardKnightMoves[squareNr] &
        (board.pieceBB[Const.White][Const.KnightID] |
            board.pieceBB[Const.Black][Const.KnightID]);
    // pretend the square is a Pawn. Get all squares it could attack. See if it includes an enemy pawn.
    // (the EmptyBoardPawnCatchMoves does _not_ include en-passant capturing, so ok).
    result |= bitBoard.PawnAttackBB1[Const.White][squareNr] &
        board.pieceBB[Const.Black][Const.PawnID];
    result |= bitBoard.PawnAttackBB1[Const.Black][squareNr] &
        board.pieceBB[Const.White][Const.PawnID];
    // pretend the square is a King. Get all squares it could attack. See if it includes the enemy King.
    result |= moveGenerator.EmptyBoardKingMoves[squareNr] &
        (board.pieceBB[Const.White][Const.KingID] |
            board.pieceBB[Const.Black][Const.KingID]);
    //
    return result;
  }

  int XRay(int attackerSquare, int attackedSquare) {
    // Returns the position (or -1, if none) of the next sliding attacker,
    // hiding behind the attackerSquare, aiming at the attackedSquare.
    int color = board.SquareContents[attackerSquare]
        .pieceColor; // the currently attacking color
    // find the direction from the attackedSquare to previous attacker
    int direction = bitBoard.Direction[attackedSquare][attackerSquare];
    if (direction == -1) return -1; // this should not happen
    // Find the ray (file, rank or diagonal) , which stretches beyond the attackerSquare
    // to the edge of the board in the direction of attackedSquare to the attacker.
    int ray = bitBoard.Ray[attackerSquare][direction]; //U64
    int pieceType; // the PieceType, next to the Queen, which can make this move.
    if (direction < 4) {
      pieceType = Const.RookID; // 0,1,2,3 : the rank and file directions
    } else {
      pieceType = Const.BishopID; // 4,5,6,7 : the diagonal directions
    }
    // Find the bitboard with possible attackers of the correct type on the ray.
    int sliderBB = ray &
        (board.pieceBB[color][Const.QueenID] |
            board.pieceBB[color][pieceType]); //U64
    if (sliderBB == 0) {
      return -1; // no slider behind attackerSquare
    } else if (attackerSquare < attackedSquare)
      return bitBoard.MSB(
          sliderBB); // ray is below the attacked square. The first is at the MSB.
    else
      return bitBoard.LSB(
          sliderBB); // ray is beyond the attacked square. The first is at the LSB.
  }

  int SEE(int moveType, int fromSquare, int toSquare) {
    // Based on (=copied from) Crafty, swap.c
    //int[] swap_list = new int[32];
    var swapList = List.filled(32, 0);

    // The attackers bitboard contains the pieces of both white and black which can capture
    // on the attacked square
    int attackersBB = GetAttackingDefendingPiecesBitBoard2(toSquare); //U64
    // Add the value of the piece on the attacked square
    if (moveType == Const.EnPassantCaptureID) {
      swapList[0] = evaluator.PieceValues[Const.PawnID];
    } else {
      swapList[0] =
          evaluator.PieceValues[board.SquareContents[toSquare].pieceType];
    }
    // the type & value of the primary attacker
    int attackerPieceType = board.SquareContents[fromSquare].pieceType;
    int lastAttackerValue = evaluator.PieceValues[attackerPieceType];
    // remove the original attacker from the attackersBB
    attackersBB &= ~BitBoard.Identity[fromSquare];
    // if a sliding piece is hiding behind the original attacker, add it to the attackers bitboard
    if (attackerPieceType != Const.KingID &&
        attackerPieceType != Const.KnightID) {
      int sq = XRay(fromSquare, toSquare);
      if (sq >= 0) attackersBB |= BitBoard.Identity[sq]; // add the hiding piece
    }

    // Repeatedly pick out the least valuable type of each color, add it's value to the swap_list
    // and remove it from the attackersBB. Do this until one color has no more attacks.

    // NB : if en-passant, the toSquare is empty, so get the defending color from the attacking color.
    int color = board.SquareContents[fromSquare].pieceColor ^
        1; // start with the defenders
    int temp = 0; //U64
    int n = 1; // the index in the swap_list
    while (true) {
      bool foundAttacker = false;
      for (int pieceType = Const.PawnID;
          pieceType >= Const.KingID;
          pieceType--) {
        if ((temp = board.pieceBB[color][pieceType] & attackersBB) != 0) {
          foundAttacker =
              true; // found the least valuable piece of the current color which can attack
          int square = bitBoard.LSB(temp);
          temp &= ~BitBoard.Identity[square]; // reset
          // if a sliding piece is hiding behind the original attacker, add it to the attackers bitboard
          if (pieceType != Const.KingID && pieceType != Const.KnightID) {
            int sq = XRay(square, toSquare);
            if (sq >= 0) {
              attackersBB |= BitBoard.Identity[sq]; // add the hiding piece
            }
          }
          // remove this attacker from the attackersBB
          attackersBB &= ~BitBoard.Identity[square];
          // append the differential score to the swap_list
          swapList[n] = -swapList[n - 1] + lastAttackerValue;
          lastAttackerValue = evaluator
              .PieceValues[pieceType]; // the value of the last attacker
          n++;
          color ^= 1; // flip the color
          break;
        }
      }
      if (!foundAttacker) break;
    }
    // so, now all possible captures, ranked from least valuable to most valuable is ready
    // 'Bubble' the best outcome to the front of the array
    n--;
    while (n > 0) {
      //Math.Max(-swap_list[n - 1], swap_list[n])
      var m = -swapList[n - 1];
      var m1 = swapList[n];
      swapList[n - 1] = -((m1 > m) ? m1 : m);
      n--;
    }
    return swapList[0];
  }
}

//#define MeasureLazyEvalDelta
//#define KingBox1_MethodB          // Seems worse. defined : count only nr attacking pieces, not total nr of attacks.

class EvScope {
  int resultStart = 0;
  int resultEnd = 0;
  EvScope(int start, int end) {
    resultStart = start;
    resultEnd = end;
  }
}

class Evaluator {
  // pointers to other classes
  late Board board;
  late MoveGenerator moveGenerator;
  late MagicMoves magicMoves;
  late BitBoard bitboard;

  static const int MateValue = 1000000;
  static const int FutureMate =
      MateValue - 10000; // assuming no more then 10000 plies

  // king, queen, rook, bishop, knight, pawn
  // The King and Pawn values are fixed
  //int[]
  var PieceValues = [50000, 0, 0, 0, 0, 100];

  // Holds scores for each color, PieceType and position
  // first index = color. second index is piece-type, 3rd index is square-nr
  //int[NrPieceTypes][NrPieceTypes][NrSquares]
  List<List<List<int>>> PieceSquareValues = [[], []];

  /* The flip array is used to calculate the piece/square
         values for WHITE pieces. The piece/square value of a
         Black pawn is pawn_pcsq[sq] and the value of a WHITE
         pawn is pawn_pcsq[flip[sq]] */

  //==== setup material and positional score values. MUST be called by descending class.

  SetStaticMaterialScore(
      int queenValue, int rookValue, int bishopValue, int knightValue) {
    // Setup the positional scores, which hold for every stage of the game.
    // This MUST be called (once) by the descending class.
    //
    // The king value is fixed at 50000
    PieceValues[Const.QueenID] = queenValue;
    PieceValues[Const.RookID] = rookValue;
    PieceValues[Const.BishopID] = bishopValue;
    PieceValues[Const.KnightID] = knightValue;
    // The pawn value is fixed at 100
  }

  // parms int[]
  SetStaticPositionalScore(var kingPcsq, var queenPcsq, var rookPcsq,
      var bishopPcsq, var knightPcsq, var pawnPcsq) {
    // Setup the positional scores, which hold for every stage of the game.
    // This MUST be called (once) by the descending class.
    //[Const.NrColors]
    for (var k = 0; k < Const.NrColors; k++) {
      for (var j = 0; j < Const.NrPieceTypes; j++) {
        PieceSquareValues[k].add(List.filled(Const.NrSquares, 0));
      }
    }
    // the original tables are for black
    var Q = PieceSquareValues[Const.Black];
    Q[Const.KingID] = kingPcsq;
    Q[Const.QueenID] = queenPcsq;
    Q[Const.RookID] = rookPcsq;
    Q[Const.BishopID] = bishopPcsq;
    Q[Const.KnightID] = knightPcsq;
    Q[Const.PawnID] = pawnPcsq;
    // now generate the flipped tables for white;
    for (int i = 0; i < Const.NrPieceTypes; i++) {
      for (int j = 0; j < Const.NrSquares; j++) {
        PieceSquareValues[Const.White][i][j] =
            PieceSquareValues[Const.Black][i][BitBoard.flip[j]];
      }
    }
  }

  //====

  int GetScoreNoise(int max) {
    //-max, max+1
    return BitBoard.rnd.nextInt((max << 1) + 1) - max;
  }

  //==== Piece values and piece-square values and outposts

  // These are from : https://www.chessprogramming.org/CPW-Engine_eval_init
  //(from crafty)

  // king, queen, rook, bishop, knight, pawn
  static const int queenValue = 975,
      rookValue = 500,
      bishopValue = 335,
      knightValue = 325;

  // int[64] arrays
  static List<int> pawn_pcsq = [],
      knight_pcsq = [],
      bishop_pcsq = [],
      rook_pcsq = [],
      queen_pcsq = [],
      king_pcsq = [],
      king_midgame_pcsq = [],
      king_endgame_pcsq = [],
      KnightOutpostBonus = [],
      BishopOutpostBonus = [];

  //====

  int globalScoreStart = 0, globalScoreEnd = 0;

  // MeasureLazyEvalDelta must be defined for this to be effective

  bool MeasureLazyEvalDelta = false;

  int maxNegLazyTrueScoreDifference = 0;
  int maxPosLazyTrueScoreDifference = 0;

  bool UsePawnStructure = true;
  bool UsePawnShieldStructure = true;
  bool UseCastleInfo = true;
  bool UseMobilityBonus = true; // true : 57% in 237 games 5sec+0.2
  bool UseKingBox1AttackBonus = true;

  bool UseKingBox1DefendBonus = false;

  bool UseKnightOutpostBonus = false;
  bool UseBishopOutpostBonus = false;

  // add a random number from -X to +X to the score.
  bool UseScoreNoise = true;
  int ScoreNoise = 10;

  // the LazyEvalDelta MUST be less the any additional score, which could be added after the
  // lazy evaluation. Otherwise an inaccurate score is returned.
  // Still a bit shaky, since inaccurate values are stored in the TT.
  bool UseLazyEvaluation = false;
  int LazyEvalDelta = 250;

  // Some constants come from
  // http://www.tckerrigan.com/Chess/TSCP

  //int[]
  static const LostCastlingRightPenalty = [
    10,
    0
  ]; // once for QS and once for KS. This also handles blocked rook ?
  static const HasCastledBonus = [30, 0]; // 30,0

  static const DoubledPawnPenalty = [10, 10]; // was 10,10
  static const IsolatedPawnPenalty = [20, 20]; // was 20,20
  static const BackwardsPawnPenalty = [8, 8]; // was 8,8
  static const PassedPawnBonus = [
    10,
    20
  ]; // *** 10,20  was 20,20        // * RankNr

  static const PawnShield1Bonus = [10, 0];
  static const PawnShield2Bonus = [5, 0];
  static const NoPawnShieldPenalty = [10, 0]; // only for AB & GH files

  static const RookOnSemiOpenFileBonus = [10, 10];
  static const RookOnOpenFileBonus = [15, 10]; // *** 15,10  was 15,15
  static const RookOnSeventhRankBonus = [20, 20]; // *** 15,25  was 20,20
  static const DoubledRookBonus = [15, 15]; // two rooks on the same file
  static const ConnectedRooksBonus = [5, 10]; // two rooks on the same rank

  static const TwoBishopBonus = [50, 50]; // ****   was 15,15

  // development :  consider only the first 16 half-moves
  static const int nrOpeningMoves = 16; // = sum of white and blacks moves
  static const int QueenEarlyMovePenalty =
      15; // penalty if moved before 16th halfmove-nr
  static const DevelopedKnights = [
    -15,
    0,
    15
  ]; // int[]  0,1 or 2 developed knights
  static const DevelopedBishops = [-10, 0, 10]; // int[]
  static const int BlockedCentralPawnPenalty = 15;

  // If the calculated score is above TradePiecesScoreThreshold, award an extra
  // TradePiecesIfWinningBonus * (difference in nr of pieces).
  static const int TradePiecesScoreThreshold = 200;
  static const int TradePiecesIfWinningBonus =
      2; // * difference in total nr pieces

  // mobility.
  // The constants are from Kiwi , position_evaluate.cxx
  // these constants center the mobility around 0 (if nrMoves=offset, mobilityBonus=0)
  static const int QueenMobilityOffset = 12; // max nr moves = 21..27
  static const int RookMobilityOffset = 8; // max nr moves = 14
  static const int BishopMobilityOffset = 5; // max nr moves = 7..13
  static const int KnightMobilityOffset = 5; // max nr moves = 2..8

  static const int MobilityMultiplier =
      80; // the base value = 100, 80% seems best
  // the bonus per possible move (-offset)

  // these are from toga
  //int[]
  static const QueenMobilityBonus = [1, 2];
  static const RookMobilityBonus = [2, 4];
  static const BishopMobilityBonus = [5, 5];
  static const KnightMobilityBonus = [4, 4];

  // Box around King safety : copied (more or less) from Kiwi
  static var nrKingBox1Attacks = [
    0,
    0
  ]; // holds the number of attacks on the other KingBox1
  static var nrKingBox1Defends = [
    0,
    0
  ]; // holds the number of defends on my KingBox1
  static var totalKingBox1Attack = [
    0,
    0
  ]; // holds the sum of the KingBox1Attack
  static var totalKingBox1Defend = [
    0,
    0
  ]; // holds the sum of the KingBox1Defend

  // the importance of the KingBox1 attack/defend :
  // scale the attack/defence on the KingBox1 : few attacks : don't care. Many attacks : Bad.
  static const int MaxNrKingBox1AttacksScale = 100;

  static const int KingBox1AttackMultiplier = 125; // base value = 100. Best=125
  static const int KingBox1DefendMultiplier = 50; // base value = 100. Best=??
  static const NrKingBox1AttacksScale = [
    0,
    15,
    50,
    75,
    90,
    95,
    100,
    100
  ]; //int[] the higher entries are also 100

  // the relative weight of the attack/defence of the piece on the KingBox1
  static const int QueenKingBox1Attack = 16;
  static const int RookKingBox1Attack = 8;
  static const int BishopKingBox1Attack = 4;
  static const int KnightKingBox1Attack = 4;
  static const int PawnKingBox1Attack = 2;

  //==== stuff needed for pawn structure evaluation

  // The value of rankNrFromStartOfLeastAdvancedPawnOnFile[,]
  // if no pawn of the specified color is present.
  static const int absRankOfNoPawnOnFile = 100;

  // For each file : the rank-nr  of the least advanced pawn
  // This is calculated from the color's start position : white from 0, black from 7
  //int[2, 8]
  var absRankNrOfLeastAdvancedPawnOnFile = [
    List.filled(8, 0),
    List.filled(8, 0)
  ];

  // The bitboards with all squares attacked by the pawns (not e.p.!)
  var PawnAttackBB = [0, 0]; //U64[2]

  //====

  // ************************************************************************************
  // *****   These 3 are used to gradually change scores from opening to endgame   ******

  // The summed material score for both sides at the initial position, excluding the kings
  int initialMaterialScores = 0;

  // Roughly the summed material score of both sides at the start of the end-game (excluding kings)
  int endGameMaterialScores = 2 * 1300;

  // This number runs from 0.0 (start of opening) to 1.0 (start of endgame).
  // It is is based on the MaterialScore
  double gameStage = 0;

  // ************************************************************************************

  List<int> decode_Evs(String coded) {
    var a = List.filled(Const.NrSquares, 0);
    var s = coded.split(" ");
    int j = 0, p = 0;
    for (int i = 0; i < s.length; i++) {
      var z = s[i].split("^");
      if (z.length == 2) {
        j = int.parse(z[1]);
        int q = 0, P = p;
        if (z[0] == "y") {
          while ((--j) > 0) {
            for (q = 0; q < P;) {
              a[p++] = a[P - (++q)];
            }
          }
        } else {
          while ((--j) > 0) {
            for (q = 0; q < P;) {
              a[p++] = a[q++];
            }
          }
        }
        break;
      }

      z = s[i].split("*");
      j = (z.length == 2 ? int.parse(z[1]) : 1);
      while ((j--) > 0) {
        a[p++] = int.parse(z[0]);
      }
    }
    return a;
  }

  CreateArrays() {
    pawn_pcsq = decode_Evs(
        "0*8 -6 -4 1*4 -4 -6*2 -4 1 2*2 1 -4 -6*2 -4 2 8*2 2 -4 -6*2 " "-4 5 10*2 5 -4 -6 -4*2 1 5*2 1 -4*2 -6 -4 1 -24*2 1 -4 -6 0*8");
    knight_pcsq = decode_Evs(
        "-15*2 -8*4 -15*3 -10 0*4 -10 -15 -8 0 4*4 0 -8*2 0 4 8*2 4 0 -8*2 " "0 4 8*2 4 0 -8*2 0 4*4 0 -8 -15 -10 1 2*2 1 -10 -15*3 -8*4 -15*2");

    bishop_pcsq = decode_Evs(
        "-15 -10 -4*4 -10 -15 -10 0*6 -10 -4 0 2 4*2 2 0 -4*2 0 4 6*2 4 0 -4*2 0 4 6*2 4 0 -4*2 1 2 4*2 2 1 -4 -10 2 1*4 2 -10 -15 -10 -12 -4*2 -12 -10 -15");

    rook_pcsq = decode_Evs("0*2 2 4*2 2 0*2 x^8");
    queen_pcsq = decode_Evs("0*10 1*4 0*4 1 2*2 1 0*4 2 3*2 2 0*4 " "2 3*2 2 0*4 1 2*2 1 0*4 1*4 0*2 -5*8");

    king_pcsq = decode_Evs("0");

    king_midgame_pcsq =
        decode_Evs("-40*48 -15*2 -20*4 -15*2 0 20 30 -30 0 -20 30 20");

    king_endgame_pcsq = decode_Evs(
        "0 10 20 30*2 20 10 0 10 20 30 40*2 30 20 10 " "20 30 40 50*2 40 30 20 30 40 50 60*2 50 40 30 y^2");

    KnightOutpostBonus = decode_Evs("0*17 1 4*4 1 0*2 2 6 8 y^2");
    BishopOutpostBonus =
        decode_Evs("0*18 1*4 0*3 1 3*4 1 0*2 3 5*4 3 0*2 1 2*4 1 0*17");
  }

  Evaluator() {
    CreateArrays();

    // setup the score
    SetStaticMaterialScore(queenValue, rookValue, bishopValue, knightValue);
    // NB : the king_pcsq contains only 0's. The evaluation is done in Evaluator
    SetStaticPositionalScore(
        king_pcsq, queen_pcsq, rook_pcsq, bishop_pcsq, knight_pcsq, pawn_pcsq);

    int initialSingleSideMaterialScore = PieceValues[Const.QueenID] +
        2 * PieceValues[Const.RookID] +
        2 * PieceValues[Const.BishopID] +
        2 * PieceValues[Const.KnightID] +
        8 * PieceValues[Const.PawnID];

    initialMaterialScores = 2 * initialSingleSideMaterialScore;
  }

  CalculateGameStage() {
    // See how far we are in the mid-game = how near to the end-game.
    // The midGameStageProgress[] runs from 0 (Start of Opening) to 1.0 (start of EndGame).
    int m = board.StaticMaterialScore[Const.White] +
        board.StaticMaterialScore[Const.Black] -
        2 * PieceValues[Const.KingID];
    double materialScoresWithoutKings = m.toDouble();
    if (materialScoresWithoutKings >= endGameMaterialScores) {
      gameStage = 1.0 -
          (materialScoresWithoutKings - endGameMaterialScores) /
              (initialMaterialScores - endGameMaterialScores);
    } else {
      gameStage = 1.0;
    }
  }

  int CalcStagedScore(int scoreStart, int scoreEnd) {
    return ((1.0 - gameStage) * scoreStart + gameStage * scoreEnd).round();
  }

  int GetFastEvaluation() {
    EvScope Ew = EvScope(0, 0);
    EvScope Eb = EvScope(0, 0);

    if (board.IsPracticallyDrawn()) {
      return 0; // check for 50-move rule ,3x repetition & not enough material
    }

    // initialize the scores
    globalScoreStart = 0;
    globalScoreEnd = 0;

    // sets gameStage : runs from 0.0 at start of game , 1.0 at start of endgame
    CalculateGameStage();

    // Material scores
    globalScoreStart += board.StaticMaterialScore[Const.White] -
        board.StaticMaterialScore[Const.Black];
    globalScoreEnd += board.StaticMaterialScore[Const.White] -
        board.StaticMaterialScore[Const.Black];
    // The king positional score is not includes in Board.StaticPositionalScore.
    // It depends on the game stage
    int whiteKingPos =
        BitBoard.flip[board.PiecePos[Const.White][Const.KingID][0]];
    int blackKingPos = board.PiecePos[Const.Black][Const.KingID][0];
    globalScoreStart +=
        king_midgame_pcsq[whiteKingPos] - king_midgame_pcsq[blackKingPos];
    globalScoreEnd +=
        king_endgame_pcsq[whiteKingPos] - king_endgame_pcsq[blackKingPos];

    // piece-square values
    globalScoreStart += board.StaticPositionalScore[Const.White] -
        board.StaticPositionalScore[Const.Black];
    globalScoreEnd += board.StaticPositionalScore[Const.White] -
        board.StaticPositionalScore[Const.Black];

    // pawn evaluation
    int pawnScoreStart = 0;
    int pawnScoreEnd = 0;

    InitPawnEvaluation(); // calculate least advanced pawns & PawnAttackBB's
    if (UsePawnStructure) {
      EvaluatePawns(Const.White, Ew);
      EvaluatePawns(Const.Black, Eb);
      pawnScoreStart += Ew.resultStart - Eb.resultStart;
      pawnScoreEnd += Ew.resultEnd - Eb.resultEnd;
    }

    // pawn shield before a king, when it's on rank 0,1 & on file ABC or FGH
    if (UsePawnShieldStructure) {
      EvaluatePawnShield(Const.White, Ew);
      EvaluatePawnShield(Const.Black, Eb);
      pawnScoreStart += Ew.resultStart - Eb.resultStart;
      pawnScoreEnd += Ew.resultEnd - Eb.resultEnd;
    }

    globalScoreStart += pawnScoreStart;
    globalScoreEnd += pawnScoreEnd;

    // queens
    EvaluateQueen(Const.White, Ew);
    EvaluateQueen(Const.Black, Eb);
    globalScoreStart += Ew.resultStart - Eb.resultStart;
    globalScoreEnd += Ew.resultEnd - Eb.resultEnd;
    // rooks
    EvaluateRook(Const.White, Ew);
    EvaluateRook(Const.Black, Eb);
    globalScoreStart += Ew.resultStart - Eb.resultStart;
    globalScoreEnd += Ew.resultEnd - Eb.resultEnd;
    // bishops
    EvaluateBishop(Const.White, Ew);
    EvaluateBishop(Const.Black, Eb);
    globalScoreStart += Ew.resultStart - Eb.resultStart;
    globalScoreEnd += Ew.resultEnd - Eb.resultEnd;
    // knights
    EvaluateKnight(Const.White, Ew);
    EvaluateKnight(Const.Black, Eb);
    globalScoreStart += Ew.resultStart - Eb.resultStart;
    globalScoreEnd += Ew.resultEnd - Eb.resultEnd;

    int score = CalcStagedScore(globalScoreStart, globalScoreEnd);
    if (score == 0) score = 1; // reserve 0 for true fraws

    // Return always : higher is better.
    if (board.colorToMove == Const.White) {
      return score;
    } else {
      return -score;
    }
  }

  int GetEvaluation(int alpha, int beta) {
    int score;
    EvScope Ew = EvScope(0, 0);
    EvScope Eb = EvScope(0, 0);

    // First a quick evaluation.
    // This calculates game stage, material, positional score, pawn stuff, pawn shield.
    // Excludes Mobility, KingBox1 attack, castling info, development

    score = GetFastEvaluation();

    if (score == 0) return 0; // draw detected in GetFastEvaluation

    if (UseLazyEvaluation) {
      // the returned score is not accurate, but is far outside the alpa-beta window,
      // so it is either ignored (<alpha) or produces a cutoff anyway (>beta)

      if (board.colorToMove == Const.Black) {
        score = -score; // undo the fast eval side switch
      }
      if (score < alpha - LazyEvalDelta || score > beta + LazyEvalDelta) {
        if (UseScoreNoise) score += GetScoreNoise(ScoreNoise);

        if (board.colorToMove == Const.White) {
          return score;
        } else {
          return -score;
        }
      }
    }

    // Full evaluation
    // scoreStart and scoreEnd have been initialized in LazyEval

    // Mobility
    if (UseMobilityBonus) {
      EvaluateMobility(Const.White, Ew);
      EvaluateMobility(Const.Black, Eb);
      globalScoreStart += Ew.resultStart - Eb.resultStart;
      globalScoreEnd += Ew.resultEnd - Eb.resultEnd;
      if (UseKingBox1DefendBonus) {
        globalScoreStart +=
            totalKingBox1Defend[Const.White] - totalKingBox1Defend[Const.Black];
        globalScoreEnd +=
            totalKingBox1Defend[Const.White] - totalKingBox1Defend[Const.Black];
      }
    }

    // the rest is stuff which is not found in EvalTT

    EvaluateNotInEvalTT(Const.White, Ew);
    EvaluateNotInEvalTT(Const.Black, Eb);
    globalScoreStart += Ew.resultStart - Eb.resultStart;
    globalScoreEnd += Ew.resultEnd - Eb.resultEnd;

    score = CalcStagedScore(globalScoreStart, globalScoreEnd);

    if (UseScoreNoise) score += GetScoreNoise(ScoreNoise);

    if (score == 0) score = 1; // return 0 for a true draw

    // Return always : higher is better.
    if (board.colorToMove == Const.White) {
      return score;
    } else {
      return -score;
    }
  }

  //==== pawns

  InitPawnEvaluation() {
    // Generate an array for each color with the rank of the least advanced pawn on each file.
    // This number starts from the original colors side (white 0, black 7).
    for (int color = 0; color < Const.NrColors; color++) {
      for (int i = 0; i < 8; i++) {
        absRankNrOfLeastAdvancedPawnOnFile[color][i] = absRankOfNoPawnOnFile;
      }
      for (int i = 0; i < board.NrPieces[color][Const.PawnID]; i++) {
        int position = board.PiecePos[color][Const.PawnID][i];
        int file = position & 7;
        int rankNrFromStart;
        if (color == Const.White) {
          rankNrFromStart = position >> 3;
        } else {
          rankNrFromStart = 7 - (position >> 3);
        }
        if (rankNrFromStart < absRankNrOfLeastAdvancedPawnOnFile[color][file]) {
          absRankNrOfLeastAdvancedPawnOnFile[color][file] = rankNrFromStart;
        }
      }
    }
    // calculate the pawn attack BB's
    int pawnBB = board.pieceBB[Const.White][Const.PawnID]; //U64
    PawnAttackBB[Const.White] = ((pawnBB & bitboard.FileBB0[0]) << 7) |
        ((pawnBB & bitboard.FileBB0[7]) << 9);
    pawnBB = board.pieceBB[Const.Black][Const.PawnID];
    PawnAttackBB[Const.Black] = ((pawnBB & bitboard.FileBB0[0]) >> 9) |
        ((pawnBB & bitboard.FileBB0[7]) >> 7);
  }

  EvaluatePawns(int thisColor, EvScope E) {
    // pawn structure evaluation (doubled, isolated, backwards, passed);
    E.resultStart = 0;
    E.resultEnd = 0;
    int otherColor;
    if (thisColor == Const.White) {
      otherColor = Const.Black;
    } else {
      otherColor = Const.White;
    }

    for (int i = 0; i < board.NrPieces[thisColor][Const.PawnID]; i++) {
      int position = board.PiecePos[thisColor][Const.PawnID][i];
      int file = position & 7;
      int rankNrFromStart = position >> 3;
      if (thisColor == Const.Black) rankNrFromStart = 7 - rankNrFromStart;
      int rankNrFromEnd = 7 - rankNrFromStart; // used for passed pawns

      // check for doubled pawns. nb : 3 pawns on a file just generates 2*Doubled_Pawn_Penalty
      if (rankNrFromStart >
          absRankNrOfLeastAdvancedPawnOnFile[thisColor][file]) {
        E.resultStart -= DoubledPawnPenalty[0];
        E.resultEnd -= DoubledPawnPenalty[1];
      }

      // Checks for  Isolated, Backward and passed pawns
      if (file == 0) {
        // check for isolated pawns ( no pawn on either sides file)
        if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][1] ==
            absRankOfNoPawnOnFile) {
          E.resultStart -= IsolatedPawnPenalty[0];
          E.resultEnd -= IsolatedPawnPenalty[1];
        }
        // check for backward pawns (pawns on either sides file are more advanced)
        else if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][1] >
            rankNrFromStart) {
          E.resultStart -= BackwardsPawnPenalty[0];
          E.resultEnd -= BackwardsPawnPenalty[1];
        }
        // check for passed pawn
        if (rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][0] &&
            rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][1]) {
          E.resultStart += rankNrFromStart * PassedPawnBonus[0];
          E.resultEnd += rankNrFromStart * PassedPawnBonus[1];
        }
      } else if (file == 7) {
        // check for isolated pawns ( no pawn on either sides file)
        if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][6] ==
            absRankOfNoPawnOnFile) {
          E.resultStart -= IsolatedPawnPenalty[0];
          E.resultEnd -= IsolatedPawnPenalty[1];
        }
        // check for backward pawns (pawns on either sides file are more advanced)
        else if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][6] >
            rankNrFromStart) {
          E.resultStart -= BackwardsPawnPenalty[0];
          E.resultEnd -= BackwardsPawnPenalty[1];
        }
        // check for passed pawn
        if (rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][7] &&
            rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][6]) {
          E.resultStart += rankNrFromStart * PassedPawnBonus[0];
          E.resultEnd += rankNrFromStart * PassedPawnBonus[1];
        }
      } else {
        // check for isolated pawns ( no pawn on either sides file)
        if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][file - 1] ==
                absRankOfNoPawnOnFile &&
            absRankNrOfLeastAdvancedPawnOnFile[thisColor][file + 1] ==
                absRankOfNoPawnOnFile) {
          E.resultStart -= IsolatedPawnPenalty[0];
          E.resultEnd -= IsolatedPawnPenalty[1];
        }
        // check for backward pawns (pawns on either sides file are more advanced)
        else if (absRankNrOfLeastAdvancedPawnOnFile[thisColor][file - 1] >
                rankNrFromStart &&
            absRankNrOfLeastAdvancedPawnOnFile[thisColor][file + 1] >
                rankNrFromStart) {
          E.resultStart -= BackwardsPawnPenalty[0];
          E.resultEnd -= BackwardsPawnPenalty[1];
        }
        // check for passed pawn
        if (rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][file - 1] &&
            rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][file] &&
            rankNrFromEnd <=
                absRankNrOfLeastAdvancedPawnOnFile[otherColor][file + 1]) {
          E.resultStart += rankNrFromStart * PassedPawnBonus[0];
          E.resultEnd += rankNrFromStart * PassedPawnBonus[1];
        }
      }
    }
  }

  EvaluatePawnShield(int color, EvScope E) {
    // The maximum score = 30. the minimum = -10.
    // if the king is on rank 0 or 1 and at file ABC or FGH, evaluate the pawns right before the king
    E.resultStart = 0;
    E.resultEnd = 0;
    int position = board.PiecePos[color][Const.KingID][0];
    //
    int rankNrFromStart = position >> 3;
    if (color == Const.Black) rankNrFromStart = 7 - rankNrFromStart;
    int file = position & 7;
    // only score if king is at rank 0,1 and file ABC or FGH
    if (rankNrFromStart > 1 || file == 3 || file == 4) return;
    int rankPlus1 = rankNrFromStart + 1;
    if (file <= 2) {
      // A-file
      int leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][0];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      } else {
        E.resultStart -= NoPawnShieldPenalty[0];
        E.resultEnd -= NoPawnShieldPenalty[1];
      }
      // B-file
      leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][1];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      } else {
        E.resultStart -= NoPawnShieldPenalty[0];
        E.resultEnd -= NoPawnShieldPenalty[1];
      }
      // C-file
      leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][2];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      }
    } else if (file >= 5) {
      // F-file
      int leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][5];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      }
      // G-file
      leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][6];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      } else {
        E.resultStart -= NoPawnShieldPenalty[0];
        E.resultEnd -= NoPawnShieldPenalty[1];
      }
      // H-file
      leastAdvPawnRank = absRankNrOfLeastAdvancedPawnOnFile[color][7];
      if (leastAdvPawnRank == rankPlus1) {
        E.resultStart += PawnShield1Bonus[0];
        E.resultEnd += PawnShield1Bonus[1];
      } else if (leastAdvPawnRank == rankPlus1 + 1) {
        E.resultStart += PawnShield2Bonus[0];
        E.resultEnd += PawnShield2Bonus[1];
      } else {
        E.resultStart -= NoPawnShieldPenalty[0];
        E.resultEnd -= NoPawnShieldPenalty[1];
      }
    }
  }

  //====

  //==== evaluate Queen, Rook, Bishop, Knight

  EvaluateQueen(int color, EvScope E) {
    // sofar, nothing yet
    E.resultStart = 0;
    E.resultEnd = 0;
  }

  EvaluateRook(int color, EvScope E) {
    // rook evaluation ( open file, semi open file, on 7th rank);
    E.resultStart = 0;
    E.resultEnd = 0;
    int otherColor;
    if (color == Const.White) {
      otherColor = Const.Black;
    } else {
      otherColor = Const.White;
    }
    int nrRooks = board.NrPieces[color][Const.RookID];
    for (int i = 0; i < nrRooks; i++) {
      int position = board.PiecePos[color][Const.RookID][i];
      int file = position & 7;
      int rankNrFromStart = position >> 3;
      if (color == Const.Black) rankNrFromStart = 7 - rankNrFromStart;
      // open & semi-open file
      if (absRankNrOfLeastAdvancedPawnOnFile[color][file] ==
          absRankOfNoPawnOnFile) {
        // the colors own pawn is not present. So open or semi-open
        if (absRankNrOfLeastAdvancedPawnOnFile[otherColor][file] ==
            absRankOfNoPawnOnFile) {
          E.resultStart += RookOnOpenFileBonus[0];
          E.resultEnd += RookOnOpenFileBonus[1];
        } else {
          E.resultStart += RookOnSemiOpenFileBonus[0];
          E.resultEnd += RookOnSemiOpenFileBonus[1];
        }
      }
      if (rankNrFromStart == 6) {
        E.resultStart += RookOnSeventhRankBonus[0];
        E.resultEnd += RookOnSeventhRankBonus[1];
      }
    }
    // 2 rooks on the same file (for speed : if >2 rooks are present (unlikely), only consider first 2 )
    if (nrRooks >= 2) {
      // 2 rooks on the same file
      if (board.PiecePos[color][Const.RookID][0] & 7 ==
          board.PiecePos[color][Const.RookID][1] & 7) {
        E.resultStart += DoubledRookBonus[0];
        E.resultEnd += DoubledRookBonus[1];
      }
      // 2 rooks on the same rank (mostly middle,end game)
      if (board.PiecePos[color][Const.RookID][0] >> 3 ==
          board.PiecePos[color][Const.RookID][1] >> 3) {
        E.resultStart += ConnectedRooksBonus[0];
        E.resultEnd += ConnectedRooksBonus[1];
      }
    }
  }

  EvaluateBishop(int color, EvScope E) {
    E.resultStart = 0;
    E.resultEnd = 0;
    if (board.NrPieces[color][Const.BishopID] >= 2) {
      E.resultStart += TwoBishopBonus[0];
      E.resultEnd += TwoBishopBonus[1];
    }
    if (UseBishopOutpostBonus) {
      int nrBishops = board.NrPieces[color][Const.BishopID];
      for (int i = 0; i < nrBishops; i++) {
        int position = board.PiecePos[color][Const.BishopID][i];
        int outpostScore;
        if (color == Const.White) {
          outpostScore = BishopOutpostBonus[BitBoard.flip[position]];
        } else {
          outpostScore = BishopOutpostBonus[position];
        }
        if (outpostScore > 0) {
          int outpostResult = 0;
          int otherColor = color ^ 1;
          // can it be driven away by an enemy pawn :
          bool isOutpost = (bitboard.FilesLeftRightInFrontBB1[color][position] &
                  board.pieceBB[otherColor][Const.PawnID]) ==
              0;
          if (isOutpost) {
            // so, it's a true outpost
            outpostResult += outpostScore;
            // is it defended by 1 of my pawns ?
            if ((bitboard.PawnAttackBB1[otherColor][position] &
                    board.pieceBB[color][Const.PawnID]) !=
                0) {
              outpostResult += outpostScore >> 1;
              // can it be driven away by a minor enemy piece ?
              if (board.NrPieces[otherColor][Const.KnightID] == 0) {
                int nrEnemyBishops = board.NrPieces[otherColor][Const.BishopID];
                if (nrEnemyBishops == 0) {
                  outpostResult += outpostScore;
                } else if (nrEnemyBishops == 1) {
                  if (BitBoard.ColorOfSquare[position] !=
                      BitBoard.ColorOfSquare[board.PiecePos[otherColor]
                          [Const.BishopID][0]]) outpostResult += outpostScore;
                }
              }
            }
            E.resultStart += outpostResult;
            E.resultEnd += outpostResult;
          }
        }
      }
    }
  }

  EvaluateKnight(int color, EvScope E) {
    E.resultStart = 0;
    E.resultEnd = 0;
    if (UseKnightOutpostBonus) {
      int nrKnights = board.NrPieces[color][Const.KnightID];
      for (int i = 0; i < nrKnights; i++) {
        int position = board.PiecePos[color][Const.KnightID][i];
        int outpostScore;
        if (color == Const.White) {
          outpostScore = KnightOutpostBonus[BitBoard.flip[position]];
        } else {
          outpostScore = KnightOutpostBonus[position];
        }
        if (outpostScore > 0) {
          int outpostResult = 0;
          int otherColor = color ^ 1;
          // can it be driven away by an enemy pawn :
          bool isOutpost = (bitboard.FilesLeftRightInFrontBB1[color][position] &
                  board.pieceBB[otherColor][Const.PawnID]) ==
              0;
          if (isOutpost) {
            // so, it's a true outpost
            outpostResult += outpostScore;
            // is it defended by 1 of my pawns ?
            if ((bitboard.PawnAttackBB1[otherColor][position] &
                    board.pieceBB[color][Const.PawnID]) !=
                0) {
              outpostResult += outpostScore >> 1;
              // can it be driven away by a minor enemy piece ?
              if (board.NrPieces[otherColor][Const.KnightID] == 0) {
                int nrEnemyBishops = board.NrPieces[otherColor][Const.BishopID];
                if (nrEnemyBishops == 0) {
                  outpostResult += outpostScore;
                } else if (nrEnemyBishops == 1) {
                  if (BitBoard.ColorOfSquare[position] !=
                      BitBoard.ColorOfSquare[board.PiecePos[otherColor]
                          [Const.BishopID][0]]) outpostResult += outpostScore;
                }
              }
            }
            E.resultStart += outpostResult;
            E.resultEnd += outpostResult;
          }
        }
      }
    }
  }

  //====

  //==== evaluation of stuff  which do not depended solely on the board hash

  EvaluateNotInEvalTT(int color, EvScope E) {
    // evaluation of things which do not depended solely on the board hash,
    // and so can not be gotten from the EvalTT.
    E.resultStart = 0;
    E.resultEnd = 0;

    EvScope Eo = EvScope(0, 0);

    // castling
    EvaluateCastling(color, Eo);
    E.resultStart += Eo.resultStart;
    E.resultEnd += Eo.resultEnd;

    // development
    EvaluateDevelopment(color, Eo);
    E.resultStart += Eo.resultStart;
    E.resultEnd += Eo.resultEnd;
  }

  EvaluateCastling(int color, EvScope E) {
    E.resultStart = 0;
    E.resultEnd = 0;
    // castling : give bonus if done so. give penealty if no longer possible
    if (UseCastleInfo) {
      if (board.hasCastled[color]) {
        E.resultStart += HasCastledBonus[0];
        E.resultEnd += HasCastledBonus[1];
      } else {
        if (!board.canCastleKingSide[color]) {
          E.resultStart -= LostCastlingRightPenalty[0];
          E.resultEnd -= LostCastlingRightPenalty[1];
        }
        if (!board.canCastleQueenSide[color]) {
          E.resultStart -= LostCastlingRightPenalty[0];
          E.resultEnd -= LostCastlingRightPenalty[1];
        }
      }
    }
  }

  EvaluateDevelopment(int color, EvScope E) {
    E.resultStart = 0;
    E.resultEnd = 0;
    // scale runs from 1.0 to 0.0 in the first 16 half-moves
    double scale = (nrOpeningMoves - board.halfMoveNr) / nrOpeningMoves;
    if (scale <= 0) return;

    // penalyze early queen movement
    // stimulate development of knight and bishops (knights a bit more then bishops)
    // penalyze blocking central pawns

    int result = 0;
    if (color == Const.White) {
      // the queen should not yet have moved
      if (board.SquareContents[3].pieceType != Const.QueenID) {
        result -= QueenEarlyMovePenalty; // ignore the color of the queen
      }
      // count the number of developed knights
      int nrDevelopedKnights = 0;
      if (board.SquareContents[1].pieceType != Const.KnightID) {
        nrDevelopedKnights++;
      }
      if (board.SquareContents[6].pieceType != Const.KnightID) {
        nrDevelopedKnights++;
      }
      result += DevelopedKnights[nrDevelopedKnights];
      // count the number of developed bishops
      int nrDevelopedBishops = 0;
      if (board.SquareContents[2].pieceType != Const.BishopID) {
        nrDevelopedBishops++;
      }
      if (board.SquareContents[5].pieceType != Const.BishopID) {
        nrDevelopedBishops++;
      }
      result += DevelopedBishops[nrDevelopedBishops];
      // check the 2 squares directly before the 2 central pawns.
      // If the pawn has not moved and something is present ont that square, penalyze.
      if (board.SquareContents[11].pieceType == Const.PawnID &&
          board.SquareContents[19].pieceType != Const.EmptyID) {
        result -= BlockedCentralPawnPenalty;
      }
      if (board.SquareContents[12].pieceType == Const.PawnID &&
          board.SquareContents[20].pieceType != Const.EmptyID) {
        result -= BlockedCentralPawnPenalty;
      }
    } else {
      // the queen should not yet have moved
      if (board.SquareContents[59].pieceType != Const.QueenID) {
        result -= QueenEarlyMovePenalty; // ignore the color of the queen
      }
      // count the number of developed knights
      int nrDevelopedKnights = 0;
      if (board.SquareContents[57].pieceType != Const.KnightID) {
        nrDevelopedKnights++;
      }
      if (board.SquareContents[62].pieceType != Const.KnightID) {
        nrDevelopedKnights++;
      }
      result += DevelopedKnights[nrDevelopedKnights];
      // count the number of developed bishops
      int nrDevelopedBishops = 0;
      if (board.SquareContents[58].pieceType != Const.BishopID) {
        nrDevelopedBishops++;
      }
      if (board.SquareContents[61].pieceType != Const.BishopID) {
        nrDevelopedBishops++;
      }
      result += DevelopedBishops[nrDevelopedBishops];
      // check the 2 squares directly before the 2 central pawns.
      // If the pawn has not moved and something is present ont that square, penalyze.
      if (board.SquareContents[51].pieceType == Const.PawnID &&
          board.SquareContents[43].pieceType != Const.EmptyID) {
        result -= BlockedCentralPawnPenalty;
      }
      if (board.SquareContents[52].pieceType == Const.PawnID &&
          board.SquareContents[44].pieceType != Const.EmptyID) {
        result -= BlockedCentralPawnPenalty;
      }
    }
    // scale these values gradually, to be 0 at the end of the opening
    E.resultStart = (scale * result).toInt();
  }

  //====

  //==== Mobility and KingBox1 attack

  EvaluateMobility(int color, EvScope E) {
    E.resultStart = 0;
    E.resultEnd = 0;
    int otherColor = 0;
    if (color == Const.White) {
      otherColor = Const.Black;
    } else {
      otherColor = Const.White;
    }
    // local copies
    //U64
    int myPieces = board.pieces[color];
    //int otherPieces = board.pieces[otherColor];
    int allPieces = board.allPiecesBB;

    // KingBox attacks
    int kingBox1AttackSum = 0;
    //kingBox1AttackSum[otherColor] = 0;
    nrKingBox1Attacks[otherColor] = 0;
    totalKingBox1Attack[otherColor] = 0;
    int otherKingBox1 =
        bitboard.Box1[board.PiecePos[otherColor][Const.KingID][0]];

    // KingBox defends
    int kingBox1DefendSum = 0;
    //kingBox1DefendSum[color] = 0;
    nrKingBox1Defends[color] = 0;
    totalKingBox1Defend[color] = 0;
    int thisKingBox1 = bitboard.Box1[board.PiecePos[color][Const.KingID][0]];

    // First : handle only major pieces
    int allMovesBB = 0; //U64
    int nrMoves = 0;
    for (int i = Const.QueenID; i <= Const.KnightID; i++) {
      for (int j = 0; j < board.NrPieces[color][i]; j++) {
        int position = board.PiecePos[color][i][j];
        switch (i) {
          case Const.QueenID:
            allMovesBB = magicMoves.Qmagic(position, allPieces);
            nrMoves =
                BitBoard.PopCount(allMovesBB & ~myPieces) - QueenMobilityOffset;
            E.resultStart +=
                nrMoves * QueenMobilityBonus[0] * MobilityMultiplier ~/ 100;
            E.resultEnd +=
                nrMoves * QueenMobilityBonus[1] * MobilityMultiplier ~/ 100;
            // KingBox attack & defends
            if (UseKingBox1AttackBonus) {
              int n = BitBoard.PopCount(allMovesBB & otherKingBox1);
              nrKingBox1Attacks[otherColor] += n;
              kingBox1AttackSum += n * QueenKingBox1Attack;
            }
            if (UseKingBox1DefendBonus) {
              int n = BitBoard.PopCount(allMovesBB & thisKingBox1);

              nrKingBox1Defends[color] += n;
              kingBox1DefendSum += n * QueenKingBox1Attack;
            }
            break;
          case Const.RookID:
            allMovesBB = magicMoves.Rmagic(position, allPieces);
            nrMoves =
                BitBoard.PopCount(allMovesBB & ~myPieces) - RookMobilityOffset;
            E.resultStart +=
                nrMoves * RookMobilityBonus[0] * MobilityMultiplier ~/ 100;
            E.resultEnd +=
                nrMoves * RookMobilityBonus[1] * MobilityMultiplier ~/ 100;
            // KingBox attack & defends
            if (UseKingBox1AttackBonus) {
              int n = BitBoard.PopCount(allMovesBB & otherKingBox1);
              nrKingBox1Attacks[otherColor] += n;
              kingBox1AttackSum += n * RookKingBox1Attack;
            }
            if (UseKingBox1DefendBonus) {
              int n = BitBoard.PopCount(allMovesBB & thisKingBox1);

              nrKingBox1Defends[color] += n;
              kingBox1DefendSum += n * RookKingBox1Attack;
            }
            break;
          case Const.BishopID:
            allMovesBB = magicMoves.Bmagic(position, allPieces);
            nrMoves = BitBoard.PopCount(allMovesBB & ~myPieces) -
                BishopMobilityOffset;
            E.resultStart +=
                nrMoves * BishopMobilityBonus[0] * MobilityMultiplier ~/ 100;
            E.resultEnd +=
                nrMoves * BishopMobilityBonus[1] * MobilityMultiplier ~/ 100;
            // KingBox attack & defends
            if (UseKingBox1AttackBonus) {
              int n = BitBoard.PopCount(allMovesBB & otherKingBox1);
              nrKingBox1Attacks[otherColor] += n;
              kingBox1AttackSum += n * BishopKingBox1Attack;
            }
            if (UseKingBox1DefendBonus) {
              int n = BitBoard.PopCount(allMovesBB & thisKingBox1);

              nrKingBox1Defends[color] += n;
              kingBox1DefendSum += n * BishopKingBox1Attack;
            }
            break;
          case Const.KnightID:
            allMovesBB = moveGenerator.EmptyBoardKnightMoves[position];
            nrMoves = BitBoard.PopCount(allMovesBB & ~myPieces) -
                KnightMobilityOffset;
            E.resultStart +=
                nrMoves * KnightMobilityBonus[0] * MobilityMultiplier ~/ 100;
            E.resultEnd +=
                nrMoves * KnightMobilityBonus[1] * MobilityMultiplier ~/ 100;
            // KingBox attack & defends
            if (UseKingBox1AttackBonus) {
              int n = BitBoard.PopCount(allMovesBB & otherKingBox1);
              nrKingBox1Attacks[otherColor] += n;
              kingBox1AttackSum += n * KnightKingBox1Attack;
            }
            if (UseKingBox1DefendBonus) {
              int n = BitBoard.PopCount(allMovesBB & thisKingBox1);

              nrKingBox1Defends[color] += n;
              kingBox1DefendSum += n * KnightKingBox1Attack;
            }
            break;
        }
      }
    }
    if (UseKingBox1AttackBonus) {
      // first calculate the pawn attacks on the KingBox1
      int nn = BitBoard.PopCount(PawnAttackBB[color] & otherKingBox1);
      nrKingBox1Attacks[otherColor] += nn;
      kingBox1AttackSum += nn * PawnKingBox1Attack;
      // calculate the entire bonus
      int n = nrKingBox1Attacks[otherColor];
      if (n >= NrKingBox1AttacksScale.length) {
        totalKingBox1Attack[otherColor] =
            kingBox1AttackSum * KingBox1AttackMultiplier ~/ 100;
      } else {
        totalKingBox1Attack[otherColor] = kingBox1AttackSum *
            NrKingBox1AttacksScale[n] *
            KingBox1AttackMultiplier /
            MaxNrKingBox1AttacksScale ~/
            100;
      }
      E.resultStart += totalKingBox1Attack[otherColor];
      E.resultEnd += totalKingBox1Attack[otherColor];
    }
    if (UseKingBox1DefendBonus) {
      // calculate the entire bonus
      int n = nrKingBox1Defends[color];

      if (n >= NrKingBox1AttacksScale.length) {
        totalKingBox1Defend[color] = kingBox1DefendSum;
      } else {
        totalKingBox1Defend[color] = kingBox1DefendSum *
            NrKingBox1AttacksScale[n] ~/
            MaxNrKingBox1AttacksScale;
      }
      if (color == Const.Black) {
        // if color = black, it means both white and blacks attack & defends have been calculated.
        // now scale the totalKingBox1Defend, depending on how much the KingBox is attacked
        // the 50 is something like the maximum possible attack score
        totalKingBox1Defend[Const.White] = totalKingBox1Defend[Const.White] *
            KingBox1DefendMultiplier *
            totalKingBox1Attack[Const.White] ~/
            5000;
        totalKingBox1Defend[Const.Black] = totalKingBox1Defend[Const.Black] *
            KingBox1DefendMultiplier *
            totalKingBox1Attack[Const.Black] ~/
            5000;
        // don't add it to the score yet. do this later
        //  E.resultStart += totalKingBox1Defend[color];
        //   E.resultEnd += totalKingBox1Defend[color];
      }
    }
  }

  //====
}

class SearchResults {
  int SearchTime = 0;
  int NodeCount = 0;
  int QNodeCount = 0;
  int Depth = 0;
  int Score = 0;
  int DepthFinishedTime = 0;
  String bestmovestring = "";
}

class SearchMove {
  // pointers to other classes
  late Board board;
  late MoveGenerator moveGenerator;
  late Evaluator evaluator;
  late Attack attack;

  SearchResults EngineResults = SearchResults();

  // options
  bool useTTable = true;
  bool moveOrdering_SearchPV = true;
  bool moveOrdering_StaticPositionValue = true;
  bool moveOrdering_UseSEE = true;
  bool useMoveOrdering_History = true;
  bool use2HistoryTables = true;
  bool useKillerMoves = true;
  bool useNullMove = true;
  bool dontUseNullMoveAtRoot = true;
  bool useFutilityPruning = true;
  bool dontStoreNullMoveInPV =
      true; // don't store moves in null-move ply in PV (?)
  bool UsePVSearch = true;
  bool UseExtensions = true;

  bool useLateMoveReduction = true;
  bool useOnly1LateMoveReduction = false;

  // **** Extended time ****
  // finish a ply if the first couple of root-moves have been searched already.
  // or quit, if the maxNrSecondsForThisMove is met.
  bool UseExtendedTime = true;
  // the extra time will be nrSearchTimeExtensions * nrSecondsForThisMove
  int nrSearchTimeExtensions = 2;
  // To go into extended time, a couple of root moves must already have been finished
  int MinNrRootMovesFinishedForExtendedTime = 3;
  // Use this as an estimate how much time the next move will take, based on the time of the previous move
  int MoveTimeMultiplier = 3;

  // results
  int currentScore = 0;
  int currentDepth = 0;
  int currentDepthFinishedTime = 0;
  int currentNrNodes = 0;
  int currentNrQNodes = 0;

  // the time in seconds, searched so far
  int currentSearchTime = 0;
  // the amount the deep slots of the TT are filled
  int currentTTFullPerMill = 0;

  int currentRootMoveNr = 0;

  // operation
  bool abortSearch = false;

  // statistics
  int nodeCount = 0;
  int qsNodeCount = 0;

  // scales down (shifts down) the history between moves. Must be between 1 & 32
  int HistoryShiftDownBetweenMoves = 4;

  // limits and storage spaces
  int MaximumAllowedSearchDepth = SEARCH_DEPTH;
  int maxQuiescenceDepth = SEARCH_DEPTH;
  int maxMovegenMoves = 99;
  int maxNrThinkMoves = 50; // under 99
  int maxNrPlies = 50;

  // stuff for time checking
  int nrSecondsForThisMove = SEARCH_SECONDS;

  // the absolute maximum allowed time. Used for InExtendedTime.
  int maxNrSecondsForThisMove = SEARCH_SECONDS;

  //Move[][]  Holds the generated moves for each ply. [plyNr, moveNr]
  List<List<Move>> moveMatrix = [];

  //int[][]
  // Used for move ordering : the 'score' of each move in a ply.  [plyNr, moveNr]
  List<List<int>> scoreMatrix = [];

  //int[] the nr of generated moves in a ply.  [plyNr]
  List<int> nrGeneratedMovesInPly = [];

  List<Move> PrincipalVariation = []; //Move[]

  //Move[][]
  List<List<Move>> PV_Matrix = []; // Temp storage for the best found moves

  //int[] The number of moves in each PV_Matrix[] array
  List<int> nrMovesInPVLine = [];

  int plyNr = 0; // the current PlyNr to investigate
  bool isFollowingThePV = false;
  int rootColorToMove = 0;

  //Move[]
  List<Move> KillerMoves1 = [];
  List<Move> KillerMoves2 = [];

  // store from->to positions which cause a beta cut-off
  //int[][,]
  var History = [[], []];

  //int[Const.NrColors]
  //int[] the maximum value of any History element. Needed for down-scaling.
  var maxHistoryValue = [0, 0];

  // is in between nrSecondsForThisMove and maxNrSecondsForThisMove
  bool isInExtendedTime = false;
  bool isThinking = false;

  DateTime startedThinkingTime = DateTime.now();
  DateTime abortThinkingTime = DateTime.now();
  int nrNodesSearchedAfterLastTimeCheck = 0;

  static const int maxNrNodeSearchesBeforeTimeCheck = 10000;

  // reporting
  // the lat time the current results was reported to the program
  DateTime lastTimeReportWasSent = DateTime.now();

  int nullMoveCounter = 0;

  SearchMove() {
    CreateStorage();
  }

  //==== Create and optionally extend storage

  CreateStorage() {
    // Creates the initial storage.

    nrGeneratedMovesInPly = List.filled(maxNrPlies, 0);
    nrMovesInPVLine = List.filled(maxNrPlies, 0);

    for (int i = 0; i <= maxNrPlies; i++) {
      // Move[maxNrPlies][]
      moveMatrix.add([]);
      PV_Matrix.add([]);
      scoreMatrix.add(List.filled(maxMovegenMoves, 0));
      for (int j = 0; j <= maxMovegenMoves; j++) {
        PV_Matrix[i].add(Move());
      }
    }

    for (int g = 0; g <= maxMovegenMoves; g++) {
      KillerMoves1.add(Move());
      KillerMoves2.add(Move());
    }

    // create history for both colors

    for (int j = 0; j < 2; j++) {
      for (int w = 0; w < Const.NrSquares; w++) {
        History[j].add(List.filled(Const.NrSquares, 0));
      }
    }
  }

  //====

  //==== Store current thinking

  StoreCurrentThinking(int score) {
    // stores the best found moves, so far and the score
    currentScore = score;

    int nrPVMoves = PrincipalVariation.length;
    if (nrPVMoves > maxNrThinkMoves) nrPVMoves = maxNrThinkMoves;

    //Move[]
    List<Move> thinkMoves = [];

    // First store everything in a clone, since making captures reorders the indices of pieces in PiecePos.
    // This reorders future moves. Somehow, this gives problems
    Board clone = Board();
    clone.LoadFrom(board);
    //
    for (int i = 0; i < nrPVMoves; i++) {
      //Move O = new Move();
      //MoveDo.copy(PrincipalVariation[i], O);
      var O = PrincipalVariation[i];
      thinkMoves.add(O);
      board.MakeMove(O);
    }

    // now rewind the board by undoing the moves made
    while (thinkMoves.isNotEmpty) {
      board.UnMakeMove(thinkMoves.removeLast());
    }

    // switch back to the original board
    board.LoadFrom(clone);
  }

  //====

  //==== timing

  StartThinkingTimer() {
    if (isThinking) {
      logPrint("SetAbortThinkingTime : the engine is already thinking");
    }
    startedThinkingTime = DateTime.now();
    abortThinkingTime =
        startedThinkingTime.add(Duration(seconds: nrSecondsForThisMove));

    isThinking = true;
  }

  int NrSecondsLeft() {
    return abortThinkingTime.difference(DateTime.now()).inSeconds;
  }

  bool IsSearchTimeFinished() {
    if (NrSecondsLeft() > 0) return false;
    // The time has past the AbortThinkingTime.
    // Maybe we can extend it a bit
    if (!UseExtendedTime ||
        isInExtendedTime ||
        currentRootMoveNr < MinNrRootMovesFinishedForExtendedTime) {
      return true;
    } else {
      // Extend the search time : allow this ply to be finished, until maxTimeForThisMove
      isInExtendedTime = true;
      int newTime = nrSecondsForThisMove +
          (nrSearchTimeExtensions * nrSecondsForThisMove);
      if (newTime > maxNrSecondsForThisMove) newTime = maxNrSecondsForThisMove;

      abortThinkingTime = startedThinkingTime.add(Duration(seconds: newTime));

      // maybe this doesn't even help ?
      if (NrSecondsLeft() < 0) {
        return true;
      } else {
        return false;
      }
    }
  }

  //====

  //==== FindBestMove

  FindBestMove() {
    if (!isInt64ok) {
      logPrint("Error! Chess moves wrong. Seems it is 32-bit javascript.");
      return;
    }

    bool reportIsSent = false;
    isThinking = false;
    isInExtendedTime = false;
    StartThinkingTimer();
    nrNodesSearchedAfterLastTimeCheck = 0;
    nodeCount = 0;
    qsNodeCount = 0;
    DateTime prevDepthFinishedTime = DateTime.now();
    lastTimeReportWasSent = prevDepthFinishedTime;
    //
    abortSearch = false;
    //
    // maxDepth must be >= 1
    rootColorToMove = board.colorToMove;
    PrincipalVariation = []; //Move[0] otherwise OrderMove crashes
    int startDepth = 1;
    if (useKillerMoves) ClearKillerMoves();

    if (useMoveOrdering_History) {
      ScaleDownHistory(Const.White, HistoryShiftDownBetweenMoves);
      if (use2HistoryTables) {
        ScaleDownHistory(Const.Black, HistoryShiftDownBetweenMoves);
      }
    }
    for (int depth = startDepth; depth <= MaximumAllowedSearchDepth; depth++) {
      nullMoveCounter = 0;
      plyNr = 0;
      currentRootMoveNr = -1;
      isFollowingThePV = true;
      // don't use int.MaxValue : gives problems with lazy eval
      int score;
      if (dontUseNullMoveAtRoot) {
        score = AlphaBeta(depth, -1000000000, 1000000000, false, true);
      } else {
        score = AlphaBeta(depth, -1000000000, 1000000000, true, true);
      }

      if (rootColorToMove == Const.Black) {
        score = -score; // since NegaMax always returns : larger is better
      }
      // maybe the maximum time got exceeded :
      if (abortSearch) break; // yes, just use the results of the previous depth
      //
      // This depth was completed in time. Store the results.

      PrincipalVariation = [];
      for (int t = 0; t < nrMovesInPVLine[0]; t++) {
        //var O = Move();
        //MoveDo.copy(PV_Matrix[0][t], O);
        var O = PV_Matrix[0][t];
        PrincipalVariation.add(O);
      }

      // save current results : this must be done thread safe !!!
      StoreCurrentThinking(score);
      currentDepth = depth;
      currentNrNodes = nodeCount;
      currentNrQNodes = qsNodeCount;
      currentScore = score;
      currentSearchTime =
          DateTime.now().difference(startedThinkingTime).inSeconds;
      currentDepthFinishedTime = currentSearchTime;

      //  give the calling function opportunity to show results. Only for depth > 3
      if (depth > 3) {
        reportIsSent = true;
        StoreCurrentEngineResults(true);
      }
      // see if it results in mate (-1, since depth starts at 1 , and PlyNr at 0) :
      //          if (Math.Abs(currentScore) >= Evaluator.MateValue - depth -1)
      //            break;
      if (currentScore.abs() > Evaluator.FutureMate) break;
      if (currentScore == 0) break; // 0 is reserved for draws.
      if (UseExtendedTime) {
        // see if there is enough time left to do a next depth-level

        int nrSecondsUsedForThisMove =
            DateTime.now().difference(prevDepthFinishedTime).inSeconds;

        prevDepthFinishedTime = DateTime.now();
        if (UseExtendedTime &&
            (isInExtendedTime ||
                NrSecondsLeft() <
                    MoveTimeMultiplier * nrSecondsUsedForThisMove)) break;
      }
    }
    // If nothing has been reported yet, pass the current results back to the engine, if finished.
    // (the previous was only called, if depth > 3)
    if (!reportIsSent) StoreCurrentEngineResults(true);
    //
    isThinking = false;
  }

  //====

  //==== AlphaBeta

  int AlphaBeta(
      int depth, int alpha, int beta, bool canDoNullMove, bool canDoLMR) {
    // Alpha = the current best score that can be forced by some means.
    // Beta  = the worst-case scenario for the opponent.
    //       = upper bound of what the opponent can achieve
    // Score >= Beta, the opponent won't let you get into this position : he has a better previous move.
    //

    nrNodesSearchedAfterLastTimeCheck++;
    // Check the time.
    if (nrNodesSearchedAfterLastTimeCheck >= maxNrNodeSearchesBeforeTimeCheck) {
      nrNodesSearchedAfterLastTimeCheck = 0;
      abortSearch = IsSearchTimeFinished(); // check the time

      if (DateTime.now().difference(lastTimeReportWasSent).inSeconds > 1) {
        // send a report, once a second

        currentNrNodes = nodeCount;
        currentSearchTime =
            DateTime.now().difference(startedThinkingTime).inSeconds;
        StoreCurrentEngineResults(false);

        lastTimeReportWasSent = DateTime.now();
      }
    }
    //
    // If we are out of time, quit. Don't care about the score, since this entire depth will be discarded.
    if (abortSearch) return 0;
    //
    nodeCount++;

    //
    nrMovesInPVLine[plyNr] = 0;
    //
    if (plyNr > 0 && board.IsPracticallyDrawn()) {
      return 0; // check for 50-move rule ,3x repetition & not enough material
    }

    bool isInCheck = board.IsInCheck();

    // maybe extend the remaining depth in certain circumstances
    bool haveExtended = false;
    if (UseExtensions) {
      if (isInCheck) {
        depth++;
        haveExtended = true;
      }
    }

    // due to the extensions, we do not enter QSearch while in check.
    if (depth <= 0) return QSearch(maxQuiescenceDepth, alpha, beta);

    if (useNullMove) {
      // If making no move at all would produce a beta cut-off, it is reasonable to assume
      // that _do_ making a move would _definitely_ produce a cut-off.
      // (assuming that making a move always improves the position).
      // Test it (= make no move) quickly, with a reduced depth (-2).
      // alpha == beta - 1 : only try null moves when not in the PV
      if (canDoNullMove &&
          alpha == beta - 1 &&
          depth >= 2 &&
          !isInCheck &&
          !board.HasZugZwang()) {
        Move nullMove = MoveDo.NullMove();
        board.MakeMove(nullMove);
        // This might screw up the PV !!
        nullMoveCounter++;
        plyNr++;
        int nullMoveScore;
        // adaptive null-move pruning
        if (depth > 6) {
          nullMoveScore = -AlphaBeta(depth - 1 - 3, -beta, -beta + 1, false,
              canDoLMR); // 3-depth reduction
        } else {
          nullMoveScore = -AlphaBeta(depth - 1 - 2, -beta, -beta + 1, false,
              canDoLMR); // 2-depth reduction
        }
        plyNr--;
        nullMoveCounter--;
        board.UnMakeMove(nullMove);
        if (nullMoveScore >= beta) return nullMoveScore; // was beta
      }
    }

    // extended futility pruning
    // not sure is this is done in the right way, but it seems to work very well.
    bool doPruneFutilities = false;
    if (useFutilityPruning) {
      if ((depth == 2 || depth == 3) &&
          alpha.abs() < Evaluator.FutureMate &&
          !isInCheck &&
          !haveExtended) {
        //int fastEval = evaluator.GetFastEvaluation();
        // do full evaluation (?)
        int fastEval = evaluator.GetEvaluation(alpha, beta);
        // nb : depth=0 is unused, since it already went to QSearch
        // nb : depth=1 makes just 1 move and then goes to QSearch. Pruning this does not work very well.
        const margin = [0, 0, 125, 300];
        if (fastEval + margin[depth] < alpha) doPruneFutilities = true;
      }
    }

    moveMatrix[plyNr] = []; //clear

    // generate moves
    moveGenerator.GenerateMoves(moveMatrix[plyNr]);
    nrGeneratedMovesInPly[plyNr] = moveMatrix[plyNr].length;

    // statically order the moves, so the (hopefully) best are tried first : Good for AlphaBeta
    ScoreMoves(plyNr);

    // singular move extension
    //   if (nrGeneratedMovesInPly[plyNr] == 1)
    //      depth++;

    // loop over all generated moves
    bool legalMoveIsMade = false;

    int bestScore = -10 * Evaluator.MateValue;

    for (int i = 0; i < nrGeneratedMovesInPly[plyNr]; i++) {
      // If we are out of time, quit. Don't care about the score, since this entire depth is not used.
      if (abortSearch) return 0;

      Move currentMove = moveMatrix[plyNr][FindBestMoveNr(plyNr)];

      // check if this move is legal
      if (!board.MakeMove(currentMove)) {
        // the move is illegal, e.g. by illegal castle or leaving king in check.
        board.UnMakeMove(currentMove);
        continue;
      }

      bool moveGivesCheck = board.IsInCheck();

      if (doPruneFutilities) {
        // don't futility prune : captures, 'special'-moves && putting king in check, no legal move was made
        if (legalMoveIsMade &&
            !moveGivesCheck &&
            currentMove.seeScore <= 0 &&
            currentMove.moveType < Const.EnPassantCaptureID) {
          board.UnMakeMove(currentMove);
          continue;
        }
      }

      legalMoveIsMade = true;
      //
      if (plyNr == 0) {
        currentRootMoveNr = i; // keep track of which root-move we are trying
      }
      //
      int score;
      plyNr++;

      if (UsePVSearch) {
        if (i == 0) {
          // assume the first move is the best (&legal). Search it with the normal window.
          score = -AlphaBeta(depth - 1, -beta, -alpha, true, canDoLMR);
        } else {
          // The next moves are considered to be worse.
          // Check this with a 'very' narrow window

          // try reduction on the 'not' so important moves
          // But : not for captures, pawn-moves, special moves, checks, root-moves
          if (useLateMoveReduction &&
              canDoLMR &&
              i >= 4 &&
              depth >= 3 // depth 3 & 5 gave identical results after 43 games
              &&
              !haveExtended &&
              currentMove.captureInfo == Const.NoCaptureID &&
              currentMove.moveType <
                  Const.PawnID // dont reduces pawn- & special-moves
              //      && currentMove.moveType < Const.CastleQSID     // dont reduces pawn- & special-moves
              &&
              plyNr > 1 // 1=root : don't reduce the root
              &&
              !isInCheck &&
              !moveGivesCheck) {
            // a reduced PV search
            bool canDoMoreRecuctions = useOnly1LateMoveReduction ? false : true;
            score = -AlphaBeta(
                depth - 2, -alpha - 1, -alpha, true, canDoMoreRecuctions);
            // If it was not worse but better, research it with a normal & unreduced window.
            if (score > alpha) {
              score = -AlphaBeta(depth - 1, -beta, -alpha, true, canDoLMR);
            }
          } else {
            // a normal PV search
            score = -AlphaBeta(depth - 1, -alpha - 1, -alpha, true, canDoLMR);
            // If it was not worse but better, research it with a normal window.
            // If it's >= beta, don't worry, it will be cut-off.
            if (score > alpha && score < beta) {
              score = -AlphaBeta(depth - 1, -beta, -score, true, canDoLMR);
            }
          }
        }
      } else {
        score = -AlphaBeta(depth - 1, -beta, -alpha, true, canDoLMR);
      }

      plyNr--;
      board.UnMakeMove(currentMove);

      // If we are out of time, quit. Don't care about the score, since this entire depth will be discarded.
      if (abortSearch) return 0;

      if (score > bestScore) {
        // The score is better then was attained before. Store it and compare it to alpha and beta.
        bestScore = score;

        if (bestScore > alpha) {
          if (bestScore >= beta) {
            // To good to be true. The opponent will never let us get in this position.
            // Store the move which caused the cut-off, and quit.
            StoreKillerAndHistory(currentMove, depth);

            return bestScore;
          }

          alpha = bestScore;
          // update the PV_Matrix;
          if (!dontStoreNullMoveInPV || nullMoveCounter == 0) {
            int nrPVMovesToCopy = nrMovesInPVLine[plyNr + 1];

            // store the current move, since it was better
            PV_Matrix[plyNr][0] = currentMove;
            // Append the current moves of the searched tree, since the current move is better.

            for (int k = 0; k < nrPVMovesToCopy; k++) {
              PV_Matrix[plyNr][1 + k] = PV_Matrix[plyNr + 1][k];
            }
            nrMovesInPVLine[plyNr] = nrPVMovesToCopy + 1;
          }
        }
      }
    }

    if (legalMoveIsMade) {
      return bestScore; // the current best possible score.
    } else {
      // no legal move could be made : either CheckMate or StaleMate
      if (board.IsInCheck()) {
        return -Evaluator.MateValue +
            plyNr; // CheckMate.    +PlyNr : promote fastest checkmates
      } else {
        return 0; // StaleMate : this must be done better !!
      }
    }
  }

  //====

  //==== QuiescenceSearch

  int QSearch(int Qdepth, int alpha, int beta) {
    // Check the time
    nrNodesSearchedAfterLastTimeCheck++;
    if (nrNodesSearchedAfterLastTimeCheck >= maxNrNodeSearchesBeforeTimeCheck) {
      nrNodesSearchedAfterLastTimeCheck = 0;
      abortSearch = IsSearchTimeFinished();
    }
    // If we are out of time, quit. Don't care about the score, since this entire depth will be discarded.
    if (abortSearch) return 0;
    //
    qsNodeCount++;
    //
    // a draw ?
    if (board.IsPracticallyDrawn()) {
      return 0; // check for 50-move rule ,3x repetition & not enough material
    }
    // bestScore is the score, if it's better not to make any (more) captures
    int bestScore = evaluator.GetEvaluation(alpha, beta);
    // if the maximum Quiescence depth is reached, return it always
    if (Qdepth == 0) return beta;
    // pruning
    if (bestScore >= beta) return bestScore;
    if (bestScore > alpha) {
      alpha = bestScore; // the evaluation is better then alpha, so update it.
    }
    //

    // generate quiescence moves

    moveMatrix[plyNr] = []; //clear

    moveGenerator.GenerateQuiescenceMoves(moveMatrix[plyNr]);
    nrGeneratedMovesInPly[plyNr] = moveMatrix[plyNr].length;
    // loop over all generated moves
    if (nrGeneratedMovesInPly[plyNr] == 0) {
      // there are no capturing moves, return the current score
      return bestScore; // score
    }

    // statically order the moves, so the (hopefully) best are tried first : Good for AlphaBeta
    ScoreQMoves(plyNr);

    for (int i = 0; i < nrGeneratedMovesInPly[plyNr]; i++) {
      Move currentMove = moveMatrix[plyNr][FindBestMoveNr(plyNr)];
      // check if this move is legal
      if (!board.MakeMove(currentMove)) {
        // the move is illegal, e.g. by illegal castle or leaving king in check.
        // This also quickly removes the InCheck non-evasions, if useCheckEvasionsInQSearch=true.
        board.UnMakeMove(currentMove);
        continue;
      }
      //
      plyNr++;
      int score =
          -QSearch(Qdepth - 1, -beta, -alpha); // recursive call to deeper plies
      plyNr--;
      //
      board.UnMakeMove(currentMove);
      //
      // If we are out of time, quit. Don't care about the score, since this entire depth will be discarded.
      if (abortSearch) return 0;
      //
      if (score > bestScore) {
        bestScore = score;
        if (bestScore >= beta) {
          break; // To worse for the opponent. He won't let you get into this position.
        }
        if (bestScore > alpha) alpha = bestScore;
      }
    }
    //
    return bestScore; // return the current best possible score.
  }

  //====

  //==== move ordering

  ScoreMoves(int plyNr) {
    const int followPVScore = 1 << 29;
    const int pawnPromotionOffset = 1 << 27;
    const int winningCaptureScoreOffset = 1 << 25;
    const int equalCaptureScoreOffset = 1 << 24;
    const int killerMove1Score = 1 << 21;
    const int killerMove2Score =
        killerMove1Score + 100; // this seems to speed it up by a very little
    const int losingCaptureScoreOffset = 1 << 20;
    const int historyMoveScore = 1 << 14; // 16384
    //

    int colorToMove = board.colorToMove;
    int historyTableNr;
    if (use2HistoryTables) {
      historyTableNr = colorToMove;
    } else {
      historyTableNr = Const.White; // use the same table for both colors
    }
    bool haveFoundPVMove = false;
    // assign some score to each move and order them
    if (moveOrdering_SearchPV) {
      if (plyNr >= PrincipalVariation.length) {
        isFollowingThePV =
            false; // Searching beyond the PrincipalVariation length.
      }
    }
    //

    //
    int nrMoves = nrGeneratedMovesInPly[plyNr];

    scoreMatrix[plyNr] = List.filled(maxMovegenMoves, 0);

    List<Move> moves = moveMatrix[plyNr]; // Move[] just a pointer
    List<int> scores = scoreMatrix[plyNr]; // int[] just a pointer
    //

    // History : find the min and max for this set of moves
    int maxHistoryValue = 0;
    if (useMoveOrdering_History) {
      // find the highest history value
      for (int i = 0; i < nrMoves; i++) {
        int from = moves[i].fromPosition;
        int to = moves[i].toPosition;
        if (History[historyTableNr][from][to] > maxHistoryValue) {
          maxHistoryValue = History[historyTableNr][from][to];
        }
      }
    }

    //
    for (int i = 0; i < nrMoves; i++) {
      // first set the score to 0
      scores[i] = 0;

      // check for the PV
      if (moveOrdering_SearchPV) {
        // is this move in the correct place in the principal variation ?
        if (isFollowingThePV && !haveFoundPVMove) {
          if (moves[i].fromPosition == PrincipalVariation[plyNr].fromPosition &&
              moves[i].toPosition == PrincipalVariation[plyNr].toPosition &&
              moves[i].moveType == PrincipalVariation[plyNr].moveType) {
            haveFoundPVMove = true;
            scores[i] += followPVScore;
          }
        }
      }
      // is this a capture ?
      if (moves[i].captureInfo != Const.NoCaptureID) {
        if (moveOrdering_UseSEE) {
          int seeScore = moves[i].seeScore;
          // multiply by (historyMoveScore+1), to not let HistoryMoveScore interfere with SeeScore's
          if (seeScore > 0) {
            scores[i] +=
                winningCaptureScoreOffset + seeScore * (historyMoveScore + 1);
          } else if (seeScore < 0)
            scores[i] += losingCaptureScoreOffset +
                seeScore * (historyMoveScore + 1); // seeScore is negative
          else
            scores[i] += equalCaptureScoreOffset;
        } else {
          // NB : pawn = 5, queen = 0
          int capturedPieceType = moves[i].captureInfo & Const.PieceTypeBitMask;
          int capturingPieceType =
              (moves[i].captureInfo >>> Const.NrPieceTypeBits) &
                  Const.PieceTypeBitMask;
          // positive=winning , negative=losing
          int captureScore = capturingPieceType - capturedPieceType;
          if (captureScore > 0) {
            scores[i] += winningCaptureScoreOffset +
                captureScore * (historyMoveScore + 1);
          } else if (captureScore == 0)
            scores[i] += equalCaptureScoreOffset;
          else
            scores[i] += losingCaptureScoreOffset +
                captureScore * (historyMoveScore + 1);
        }
      } else {
        // Not a capture : is it a Killer move ?
        if (useKillerMoves) {
          if (MoveDo.Eq(moves[i], KillerMoves1[plyNr])) {
            scores[i] += killerMove1Score;
          } else if (MoveDo.Eq(moves[i], KillerMoves2[plyNr]))
            scores[i] += killerMove2Score;
        }
      }
      // is it a pawn promotion ? Only score the Queen promotion. Let the minor promotions get score = 0;
      if (moves[i].moveType == Const.PawnPromoteQueenID) {
        scores[i] += pawnPromotionOffset;
      }

      if (useMoveOrdering_History && maxHistoryValue != 0) {
        // if maxHistoryValue == 0, History is empty. Dividing by it yields Int.MinValue !!
        int moveFromPos = moves[i].fromPosition;
        int moveToPos = moves[i].toPosition;
        // history now scores from historyMoveScore to 2*historyMoveScore
        scores[i] += historyMoveScore +
            (historyMoveScore *
                History[historyTableNr][moveFromPos][moveToPos] ~/
                maxHistoryValue);
      }
      if (moveOrdering_StaticPositionValue) {
        // trick from Rebel : sort moves by their position evaluation.
        // This might help a little for otherwise unsorted moves.
        // this probably only works for a very simple evaluation !!!
        // A better approach might be internal deepening
        int moveFromPos = moves[i].fromPosition;
        int moveToPos = moves[i].toPosition;
        int moveType = moves[i].moveType;
        switch (moves[i].moveType) {
          case Const.KingID:
          case Const.QueenID:
          case Const.RookID:
          case Const.BishopID:
          case Const.KnightID:
            scores[i] += evaluator.PieceSquareValues[colorToMove][moveType]
                    [moveToPos] -
                evaluator.PieceSquareValues[colorToMove][moveType][moveFromPos];
            break;
          case Const.PawnID:
          case Const.Pawn2StepID:
          case Const.EnPassantCaptureID:
            scores[i] += evaluator.PieceSquareValues[colorToMove][Const.PawnID]
                    [moveToPos] -
                evaluator.PieceSquareValues[colorToMove][Const.PawnID]
                    [moveFromPos];
            break;
          case Const.CastleKSID:
          case Const.CastleQSID:
            // the from/to pos is that of the king
            scores[i] += evaluator.PieceSquareValues[colorToMove][Const.KingID]
                    [moveToPos] -
                evaluator.PieceSquareValues[colorToMove][Const.KingID]
                    [moveFromPos];
            break;
        }
      }
    }
    //
    if (moveOrdering_SearchPV && !haveFoundPVMove) {
      isFollowingThePV = false; // lost the PV track
    }
  }

  ScoreQMoves(int plyNr) {
    const int pawnPromotionOffset = 1 << 27;
    const int winningCaptureScoreOffset = 1 << 25;
    const int equalCaptureScoreOffset = 1 << 24;
    const int losingCaptureScoreOffset = 1 << 20;
    //
    // assign some score to each move
    //

    int nrMoves = nrGeneratedMovesInPly[plyNr];

    List<Move> moves = moveMatrix[plyNr]; //Move[] just a pointer
    List<int> scores = scoreMatrix[plyNr]; //int[] just a pointer

    for (int i = 0; i < nrMoves; i++) {
      // first set the score to 0
      scores[i] = 0;

      // is this a capture ?
      if (moves[i].captureInfo != Const.NoCaptureID) {
        if (moveOrdering_UseSEE) {
          int seeScore = moves[i].seeScore;
          if (seeScore > 0) {
            scores[i] += winningCaptureScoreOffset + seeScore;
          } else if (seeScore < 0)
            scores[i] +=
                losingCaptureScoreOffset + seeScore; // seeScore is negative
          else
            scores[i] += equalCaptureScoreOffset;
        } else {
          // NB : pawn = 5, queen = 0
          int capturedPieceType = moves[i].captureInfo & Const.PieceTypeBitMask;
          int capturingPieceType =
              (moves[i].captureInfo >>> Const.NrPieceTypeBits) &
                  Const.PieceTypeBitMask;
          // positive=winning , negative=losing
          int captureScore = capturingPieceType - capturedPieceType;
          if (captureScore > 0) {
            scores[i] += winningCaptureScoreOffset + captureScore;
          } else if (captureScore == 0)
            scores[i] += equalCaptureScoreOffset;
          else
            scores[i] += losingCaptureScoreOffset + captureScore;
        }
      }

      // is it a pawn promotion ? Only score the Queen promotion. Let the minor promotions get score = 0;
      if (moves[i].moveType == Const.PawnPromoteQueenID) {
        scores[i] = pawnPromotionOffset;
      }
    }
  }

  StoreKillerAndHistory(Move currentMove, int currentDepth) {
    if (useKillerMoves && currentMove.captureInfo == Const.NoCaptureID) {
      // It gives a cut-off. Remember if for move-ordening
      // Don't store capturing moves (they already get high move-order priority)
      // And make sure KillerMove2 does not becomes equal to KillerMove1
      if (!MoveDo.Eq(currentMove, KillerMoves1[plyNr])) {
        KillerMoves2[plyNr] = KillerMoves1[plyNr];
        KillerMoves1[plyNr] = currentMove;
      } else {
        // KillerMove1 is already set to CurrentMove. Try KillerMove2
        if (!MoveDo.Eq(currentMove, KillerMoves2[plyNr])) {
          KillerMoves2[plyNr] = currentMove;
        }
      }
    }
    if (useMoveOrdering_History) {
      int color;
      if (use2HistoryTables) {
        color = board.colorToMove;
      } else {
        color = Const.White; // use the same table for both colors
      }

      var history = History[color]; //int[,]
      history[currentMove.fromPosition][currentMove.toPosition] +=
          2 << currentDepth;
      if (history[currentMove.fromPosition][currentMove.toPosition] >
          maxHistoryValue[color]) {
        maxHistoryValue[color] =
            history[currentMove.fromPosition][currentMove.toPosition];
        if (maxHistoryValue[color] > (1 << 30)) ScaleDownHistory(color, 2);
      }
    }
  }

  ClearKillerMoves() {
    for (int i = 0; i < KillerMoves1.length; i++) {
      KillerMoves1[i] = MoveDo.NoMove();
      KillerMoves2[i] = MoveDo.NoMove();
    }
  }

  ClearHistory() {
    for (int i = 0; i < Const.NrSquares; i++) {
      for (int c = 0; c < Const.NrColors; c++) {
        History[c][i] = List.filled(Const.NrSquares, 0);
      }
    }
    maxHistoryValue = [0, 0];
  }

  ScaleDownHistory(int colorToMove, int shift) {
    // reduce all history values to prevent overflow, or scale between moves
    for (int i = 0; i < Const.NrSquares; i++)
      for (int j = 0; j < Const.NrSquares; j++) {
        History[colorToMove][i][j] = History[colorToMove][i][j] >>> shift;
      }
    maxHistoryValue[colorToMove] = maxHistoryValue[colorToMove] >>> shift;
  }

  int FindBestMoveNr(int plyNr) {
    // moves = moveMatrix[plyNr]   just a pointer
    List<int> scores = scoreMatrix[plyNr]; //int[] just a pointer
    int nrMoves = nrGeneratedMovesInPly[plyNr];

    int maxScore = -2147483648; //int.MinValue;
    int bestMoveNr = -1;

    for (int i = 0; i < nrMoves; i++) {
      if (scores[i] >= maxScore) {
        maxScore = scores[i];
        bestMoveNr = i;
      }
    }
    scores[bestMoveNr] = -2147483648; // don't pick this one again
    return bestMoveNr;
  }

  //====

  String bestmovesString() {
    String s = "";
    int N = nrMovesInPVLine[0]; //PV_Matrix[0].length
    if (N < 1) N = 1;
    for (int i = 0; i < N; i++) {
      Move mv = PV_Matrix[0][i];
      if (mv.moveType == Const.NoMoveID || mv.fromPosition == mv.toPosition) {
        break;
      }

      s += "${EPD.PositionToString(mv.fromPosition)}${EPD.PositionToString(mv.toPosition)} ";
    }
    return s;
  }

  StoreCurrentEngineResults(bool alsoNewPV) {
    EngineResults.SearchTime = currentSearchTime;
    EngineResults.NodeCount = currentNrNodes;
    EngineResults.QNodeCount = currentNrQNodes;
    EngineResults.Depth = currentDepth;
    if (alsoNewPV) {
      EngineResults.Score = currentScore;
      EngineResults.bestmovestring = bestmovesString();
      EngineResults.DepthFinishedTime = currentDepthFinishedTime;
    }
  }
}

class Engine {
  // The main storage of ALL classes.
  BitBoard bitboard = BitBoard();
  MagicMoves magicMoves = MagicMoves();
  Board board = Board();
  MoveGenerator moveGenerator = MoveGenerator();
  Evaluator evaluator = Evaluator();
  SearchMove searchMove = SearchMove();
  Attack attack = Attack();

  Engine() {
    // Setup dependency : assign pointers to classes
    SetupClassDependency();

    SetupInitialBoard(true);

    VerifyMagics();
  }

  // Assign pointers to classes. Always use this if a class is redeclared.

  SetupClassDependency() {
    // board
    board.magicMoves = magicMoves;
    board.moveGenerator = moveGenerator;
    board.evaluator = evaluator;
    board.bitboard = bitboard;

    // evaluator
    evaluator.board = board;
    evaluator.moveGenerator = moveGenerator;
    evaluator.magicMoves = magicMoves;
    evaluator.bitboard = bitboard;

    // MoveGenerator
    moveGenerator.board = board;
    moveGenerator.magicMoves = magicMoves;
    moveGenerator.bitboard = bitboard;
    moveGenerator.attack = attack;

    // searchMove
    searchMove.board = board;
    searchMove.moveGenerator = moveGenerator;
    searchMove.evaluator = evaluator;
    searchMove.attack = attack;

    // attack
    attack.board = board;
    attack.magicMoves = magicMoves;
    attack.bitBoard = bitboard;
    attack.evaluator = evaluator;
    attack.moveGenerator = moveGenerator;
  }

  SetupInitialBoard(bool clearPlayHistory) {
    SetupBoard("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        clearPlayHistory);
  }

  SetupBoard(String fenString, bool clearPlayHistory) {
    board.FEN_To_Board(fenString);

    if (clearPlayHistory) {
      searchMove.ClearKillerMoves();
      searchMove.ClearHistory();
    }
  }

  // returns:
  // 0 - moves available
  //  or can't move
  // 1 - stallmate
  // 2 - checkmate

  int IsCheckMateOrStallMate() {
    // Use this only in between moves, since it's quite 'slow';

    bool isStallMate = false;

    Board clone = Board();
    clone.LoadFrom(board);

    moveGenerator.GenerateMoves([]);
    var moves = moveGenerator.movelist;

    // try all moves. If no one is valid. It's checkmate.
    bool hasValidMove = false;
    for (int i = 0; i < moves.length; i++) {
      if (board.MakeMove(moves[i])) {
        hasValidMove = true;
      }
      board.UnMakeMove(moves[i]);
      if (hasValidMove) break;
    }
    board.LoadFrom(clone);
    if (!hasValidMove) {
      // maybe it's a stall-mate : in this case, the king is not in check
      isStallMate = !board.IsInCheck();
      return (isStallMate ? 1 : 2);
    } else {
      isStallMate = false;
    }
    return 0;
  }

//
// Verifies magics, are ok or not. Does 1<<32 work or not.
//
  VerifyMagics() {
    int a = (1 << 31), b = ((1 << 33) >>> 2);
    moveGenerator.GenerateMoves([]);
    var moves = moveGenerator.movelist;
    if (a != b || moves.length != 20 || moves[19].toPosition != 31) {
      logPrint("Uint64 error! 64-bit bitops here, sorry.");
      isInt64ok = false;
    }
  }
}

logPrint(String S) {
  // or simply do nothing
  print(S);
}

//
//  Sample to see it playing...
//

String c0_getOpnMv(String s) {
  var a = s.split(" ");
  int R = 0, k = 0, i = 0, r = 0;

  String bm = a[0];

  while (k < 2) {
    for (i = 0; i < a.length; i += 2) {
      if (a[i].length >= 4) {
        R += a[i + 1].codeUnits[1] - 48;
        if (k == 1 && R <= r) bm = a[i];
      }
    }
    if (k == 0) {
      r = BitBoard.rnd.nextInt(R);
      R = 0;
    }
    k++;
  }
  return bm;
}

playSampleAIvsAI() {
  Engine engine = Engine();
  var ss = engine.searchMove;

  c0_openings Opn = c0_openings();

  // randomize more
  int rollRnd = DateTime.now().second << 2;
  while ((rollRnd--) > 0) {
    BitBoard.rnd.nextInt(1);
  }

  int mc = 0;
  String mlist = "", pgn = "";
  bool book = true; // to use a small 15Kb opening book

  while (true) {
    ss.board.logPrintboard();

    // To let know what is going on.
    if (!isInt64ok) {
      logPrint("Can not work properly on 32-bit. Wrong moves.");
    }

    int kg = engine.IsCheckMateOrStallMate();
    if (kg == 1) {
      String draw = "1/2-1/2";
      logPrint("Stalemate $draw");
      pgn += " $draw";
    }
    if (kg == 2) {
      String win = (engine.board.colorToMove == Const.White ? "0-1" : "1-0");
      logPrint("Checkmate# $win");
      pgn += "# $win";
    }

    if (kg == 0 && engine.board.IsInCheck()) {
      logPrint("Check+");
      pgn += "+";
    }
    if (kg > 0) break;
    pgn += " ";

    String bm = "";

    if (book) {
      String op = Opn.c0_Opening(mlist);
      if (op.isNotEmpty) {
        bm = c0_getOpnMv(op); //Take randomized opening move
        logPrint("$bm opening move ");
        // wait a second
        DateTime pauseS = DateTime.now();
        while (pauseS.second == DateTime.now().second) {}
      } else {
        book = false;
      }
    }

    if (!book) {
      ss.FindBestMove();
      bm = ss.EngineResults.bestmovestring;
      logPrint("$bm score= ${ss.EngineResults.Score} nodes=${ss.EngineResults.NodeCount}");
    }

    mc++;
    if (mc > 400) {
      logPrint("Aborted...ups");
      break;
    }

    // the same as ss.PV_Matrix[0][0]
    String ucimove = bm.split(' ')[0];
    Move mv = engine.board.FindMoveOnBoard(ucimove);
    mlist += ucimove;

    if ((mc & 1) != 0) pgn += "${(mc >> 1) + 1}.";
    pgn += MoveDo.ToString(mv, engine.board.colorToMove);

    ss.board.moveGenerator.GenerateMoves([]);
    ss.board.MakeMove(mv);
  }

  logPrint(pgn);

  logPrint("Ok");
}
