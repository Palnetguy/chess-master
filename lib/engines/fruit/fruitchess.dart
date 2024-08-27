//
// Fruit 2.1 chess engine by Fabien Letouzey, 2004-2005.
// At http://www.fruitchess.com,  http://wbec-ridderkerk.nl/
//
// Port to Lua,AS3,JS, 2011
// Port to Dart 2024, modified version.
//
// It is good 32 bit platform chess AI. There is no Uint64 variables.
//
// Samples and all the usage is obvious down at the end.
// Free usage and much thanks to Fabien!
//
// for AI vs AI autogame
//
// Notes:
//  Forced moves on timeouts may give strange results, it is dart.
//  Memory space should be allocated. So, hashing takes long time.
//  Maybe it is reasonable to turn off all hashing tables (trans,pawn,material).
//  Dart is an interpreted language and has garbage collector inside.
//
//  Dart randomizer may give same results, so an ackward
//    n-seconds-loop solves it.

import 'dart:math';
import 'consts.dart'; // large chunk of constants

class alist_t {
  int size = 0;
  List<int> square = List.filled(16, 0); // int[15]
}

class alists_t {
  List<alist_t> alist = [new alist_t(), new alist_t()]; //alist_t [ColourNb][1]
}

class attack_t {
  int dn = 0;
  List<int> ds = List.filled(5, 0); // int[2+1]
  List<int> di = List.filled(5, 0); // int[2+1]
}

class board_t {
  List<int> square = List.filled(SquareNb, 0); // int[SquareNb]
  List<int> pos = List.filled(SquareNb, 0); // int[SquareNb]
  List<List<int>> piece = [
    List.filled(17, 0),
    List.filled(17, 0)
  ]; // int[ColourNb][32] only 17 are needed
  List<int> piece_size = [0, 0]; // int[ColourNb]
  List<List<int>> pawn = [
    List.filled(9, 0),
    List.filled(9, 0)
  ]; // int[ColourNb][16] only 9 are needed
  List<int> pawn_size = [0, 0]; // int[ColourNb]
  int piece_nb = 0; // int
  List<int> number = List.filled(12, 0); // int[16] only 12 are needed
  List<List<int>> pawn_file = [
    List.filled(FileNb, 0),
    List.filled(FileNb, 0)
  ]; // int[ColourNb][FileNb];
  int turn = 0; // int
  int flags = 0; // int
  int ep_square = 0; // int
  int ply_nb = 0; // int
  int sp = 0; // int
  int cap_sq = 0; // int
  int opening = 0; // int
  int endgame = 0; // int
  int key = 0; // uint64
  int pawn_key = 0; // uint64
  int material_key = 0; // uint64
  List<int> stack = List.filled(StackSize, 0); // uint64[StackSize];
  int movenumb = 0; // int
}

class endgame_t {
  int v = 0;
}

class entry_t {
  int lock = 0; // uint32
  int move = 0; // uint16
  int depth = 0; // sint8
  int date = 0; // uint8
  int move_depth = 0; // sint8
  int flags = 0; // uint8
  int min_depth = 0; // sint8
  int max_depth = 0; // sint8
  int min_value = 0; // sint16
  int max_value = 0; // sint16
}

class int_t {
  int v = 0;
}

class list_t {
  int size = 0; // int
  List<int> move = List.filled(ListSize, 0); // int[ListSize]
  List<int> value = List.filled(ListSize, 0); // short int[ListSize]
}

class material_info_t {
  int lock = 0; // uint32
  int recog = 0; // uint8
  int flags = 0; // uint8
  List<int> cflags = [0, 0]; // uint8[ColourNb]
  List<int> Array = [0, 0]; // uint8[ColourNb]
  int phase = 0; // sint16
  int opening = 0; // sint16
  int endgame = 0; // sint16
  List<int> mul = [0, 0];
}

class material_t {
  List<material_info_t> table = []; // entry_t*
  int size = 0; // uint32
  int mask = 0; // uint32
  int used = 0; // uint32

  int read_nb = 0; // sint64
  int read_hit = 0; // sint64
  int write_nb = 0; // sint64
  int write_collision = 0; // sint64
}

class my_timer_t {
  DateTime started = DateTime.now();
  double elapsed = 0.0; // double
  bool running = false; // bool
}

class opening_t {
  int v = 0;
}

class opt_t_def {
  String vary = ""; // string
  bool decl = false; // bool
  String init = ""; // string
  String type = ""; // string
  String extra = ""; // string
  String val = ""; // string
}

class pawn_info_t {
  int lock = 0; // uint32
  int opening = 0; // sint16
  int endgame = 0; // sint16
  List<int> flags = [0, 0]; // uint8[ColourNb]
  List<int> passed_bits = [0, 0]; // uint8[ColourNb]
  List<int> single_file = [0, 0]; // uint8[ColourNb]
  int pad = 0; // uint16
}

class pawn_t {
  List<pawn_info_t> table = []; // entry_t*
  int size = 0; // uint32
  int mask = 0; // uint32
  int used = 0; // uint32

  int read_nb = 0; // sint64
  int read_hit = 0; // sint64
  int write_nb = 0; // sint64
  int write_collision = 0; // sint64
}

class search_best_t {
  int move = 0; // int
  int value = 0; // int
  int flags = 0; // int
  int depth = 0; // int
  List<int> pv = List.filled(HeightMax, 0); // int[HeightMax]
}

class search_current_t {
  board_t board = new board_t(); // board_t[1]
  my_timer_t timer = new my_timer_t(); // my_timer_t[1]
  int mate = 0; // int
  int depth = 0; // int
  int max_depth = 0; // int
  int node_nb = 0; // sint64
  double time = 0.0; // double
  double speed = 0.0; // double
}

class search_info_t {
  bool can_stop = false; // bool
  bool stop = false; // bool
  int check_nb = 0; // int
  int check_inc = 0; // int
  double last_time = 0.0; // double
}

class search_input_t {
  board_t board = new board_t(); // board_t[1]
  list_t list = new list_t(); // list_t[1]
  bool infinite = false; // bool
  bool depth_is_limited = false; // bool
  int depth_limit = 0; // int
  bool time_is_limited = false; // bool
  double time_limit_1 = 0.0; // double
  double time_limit_2 = 0.0; // double
}

class search_root_t {
  list_t list = new list_t(); // list_t[1]
  int depth = 0; // int
  int move = 0; // int
  int move_pos = 0; // int
  int move_nb = 0; // int
  int last_value = 0; // int
  bool bad_1 = false; // bool
  bool bad_2 = false; // bool
  bool change = false; // bool
  bool easy = false; // bool
  bool flag = false; // bool
}

class sort_t {
  int depth = 0; // int
  int height = 0; // int
  int trans_killer = 0; // int
  int killer_1 = 0; // int
  int killer_2 = 0; // int
  int gen = 0; // int
  int test = 0; // int
  int pos = 0; // int
  int value = 0; // int
  late board_t board; // board_t *
  late attack_t attack; // attack_t *
  list_t list = new list_t(); // list_t[1]
  list_t bad = new list_t(); // list_t[1]
}

class string_t {
  String v = "";
}

class trans_rtrv {
  int trans_move = 0; // int
  int trans_min_depth = 0; // int
  int trans_max_depth = 0; // int
  int trans_min_value = 0; // int
  int trans_max_value = 0; // int
}

class trans_t {
  List<entry_t> table = []; // entry_t*
  int size = 0; // uint32
  int mask = 0; // uint32
  int date = 0; // int
  List<int> age = []; // int[DateSize]
  int used = 0; // uint32
  int read_nb = 0; // sint64
  int read_hit = 0; // sint64
  int write_nb = 0; // sint64
  int write_hit = 0; // sint64
  int write_collision = 0; // sint64
}

class undo_t {
  bool capture = false; // bool

  int capture_square = 0; // int
  int capture_piece = 0; // int
  int capture_pos = 0; // int

  int pawn_pos = 0; // int

  int turn = 0; // int
  int flags = 0; // int
  int ep_square = 0; // int
  int ply_nb = 0; // int

  int cap_sq = 0; // int

  int opening = 0; // int
  int endgame = 0; // int

  int key = 0; // uint64
  int pawn_key = 0; // uint64
  int material_key = 0; // uint64
}

//-----------------------------

class FruitChess {
  Random rnd = Random();

  String bestmv = ""; // string contains best move
  String bestmv2 = ""; // string contains pgn-format of the move

  bool ShowInfo = false; // set true to show thinking!

  List<opt_t_def> Option = []; // 20 options

  List<int> PieceTo12 = List.filled(PieceNb, -1); // int[PieceNb]
  List<int> PieceOrder = List.filled(PieceNb, -1); // int[PieceNb]
  List<List<int>> PieceInc = []; // int[PieceNb][9]  sq->sq

  List<int> SquareTo64 = List.filled(SquareNb, -1); // int[SquareNb]
  List<bool> SquareIsPromote = List.filled(SquareNb, false); // bool[SquareNb]

  List<int> DeltaIncLine = List.filled(DeltaNb, 0); // int[DeltaNb]
  List<int> DeltaIncAll = List.filled(DeltaNb, 0); // int[DeltaNb]

  List<int> DeltaMask = List.filled(DeltaNb, 0); // int[DeltaNb]
  List<int> IncMask = List.filled(IncNb, 0); // int[IncNb]

  List<int> PieceCode = List.filled(PieceNb, -1); // int[PieceNb]
  List<List<int>> PieceDeltaSize = []; // int[4][256]      4kB
  List<List<List<int>>> PieceDeltaDelta = []; // int[4][256][4]  16kB

  trans_t Trans = new trans_t(); // trans_t [1]
  trans_rtrv TransRv = new trans_rtrv(); // retriever

  int MaterialWeight = 256; // 100% int
  material_t Material = new material_t(); // material_t[1]

  List<int> CastleMask = List.filled(SquareNb, 0xF); // int[SquareNb]

  pawn_t Pawn = new pawn_t(); // pawn_t[1]

  List<int> Bonus = List.filled(RankNb, 0); // int[RankNb]

  List<int> BitEQ = List.filled(16, 0); // int[16]
  List<int> BitLT = List.filled(16, 0); // int[16]
  List<int> BitLE = List.filled(16, 0); // int[16]
  List<int> BitGT = List.filled(16, 0); // int[16]
  List<int> BitGE = List.filled(16, 0); // int[16]

  List<int> BitFirst = List.filled(0x100, 0); // int[0x100]
  List<int> BitLast = List.filled(0x100, 0); // int[0x100]
  List<int> BitCount = List.filled(0x100, 0); // int[0x100]
  List<int> BitRev = List.filled(0x100, 0); // int[0x100]

  List<int> BitRank1 = List.filled(RankNb, 0); // int[RankNb]
  List<int> BitRank2 = List.filled(RankNb, 0); // int[RankNb]
  List<int> BitRank3 = List.filled(RankNb, 0); // int[RankNb]

  int PieceActivityWeight = 256; // 100%   int
  int KingSafetyWeight = 256; // 100%  int
  int PassedPawnWeight = 256; // 100%  int
  int PawnStructureWeight = 256; // 100%  int

  List<List<List<int>>> Pst = []; // sint16 [12][64][StageNb]

  List<int> Random64 =
      List.filled(RandomNb, 0); // uint64[RandomNb]  array of fixed randoms

  bool setjmp = false; // c++ has setjmp-longjmp feature

  bool Usenull = true; // bool
  bool UsenullEval = true; // bool
  int nullDepth = 2; // int
  int nullReduction = 3; // int

  bool UseVer = true; // bool
  bool UseVerEndgame = true; // bool
  int VerReduction = 5; // int   was 3

  bool UseHistory = true; // bool
  int HistoryValue = 9830; // int 60%

  bool UseFutility = false; // bool
  int FutilityMargin = 100; // int

  bool UseDelta = false; // bool
  int DeltaMargin = 50; // int

  int CheckNb = 1; // int
  int CheckDepth = 0; // int   1 - CheckNb

  double NormalRatio = 1.0; // double
  double PonderRatio = 1.25; // double

  bool Init = false; // bool

  int PosLegalEvasion = 0; // int
  int PosSEE = 0; // int

  int PosEvasionQS = 0; // int
  int PosCheckQS = 0; // int
  int PosCaptureQS = 0; // int

  List<int> Code = List.filled(CODE_SIZE, 0); // int[CODE_SIZE]

  List<List<int>> Killer = []; // uint16[HeightMax][KillerNb]

  List<int> History = List.filled(HistorySize, 0); // uint16[HistorySize]
  List<int> HistHit = List.filled(HistorySize, 0); // uint16[HistorySize]
  List<int> HistTot = List.filled(HistorySize, 0); // uint16[HistorySize]

  List<int> ValuePiece = List.filled(PieceNb, 0); // int[PieceNb]

  List<List<int>> MobUnit = [[], []]; // int[ColourNb][PieceNb]

  List<int> KingAttackUnit = List.filled(PieceNb, 0); // int[PieceNb]

  List<int> Castle64 = List.filled(16, 0); // int[16]

  List<int> Distance = List.filled(DeltaNb, -1); // int[DeltaNb]

  search_input_t SearchInput = new search_input_t(); // search_input_t[1]
  search_info_t SearchInfo = new search_info_t(); // search_info_t[1]
  search_root_t SearchRoot = new search_root_t(); // search_root_t[1]
  search_current_t SearchCurrent =
      new search_current_t(); // search_current_t[1]
  search_best_t SearchBest = new search_best_t(); // search_best_t[1]

  FruitChess() {
    int roll_rnd = DateTime.now().second << 2;
    while ((roll_rnd--) > 0) rnd.nextInt(1); // roll random little

    main_init(); // prepare arrays
  }

  int random_32bit() {
    return rnd.nextInt(0xFFFFFFFF);
  }

  String substr(String s, int from, int len) {
    return s.substring(from, from + len);
  }

  bool string_equal(String s1, String s2) {
    return (s1 == s2);
  }

  bool string_start_with(String s1, String s2) {
    return (s1.length >= s2.length) && (s1.substring(0, s2.length) == s2);
  }

  String str_before_ok(String str1, String c) {
    int i = str1.indexOf(c);
    if (i >= 0) return str1.substring(0, i);
    return "";
  }

  String str_after_ok(String str1, String c) {
    int i = str1.indexOf(c);
    if (i >= 0) return str1.substring(i + (c.length));
    return "";
  }

// display to console or else
  print_out(String s) {
    print(s);
  }

// should be true, or error otherwise
  ASSERT(int id, bool logic) {
    if (!logic) {
      print_out("//ASSERT FAIL on id=" + id.toString());
    }
  }

// for error case
  my_fatal(String errmess) {
    print_out("my-error: " + errmess);
  }

  send(String str1) {
    if (!ShowInfo && string_start_with(str1, "info ")) return;

    print_out(str1);
  }

  bool COLOUR_IS_OK(int colour) {
    return ((colour & bnot1) == 0);
  }

  bool COLOUR_IS_WHITE(int colour) {
    return (colour == White);
  }

  bool COLOUR_IS_BLACK(int colour) {
    return (colour != White);
  }

  int COLOUR_FLAG(int colour) {
    return (colour + 1);
  }

  bool COLOUR_IS(int piece, int colour) {
    return (FLAG_IS(piece, colour + 1));
  }

  bool FLAG_IS(int piece, int flag) {
    return ((piece & flag) != 0);
  }

  int COLOUR_OPP(int colour) {
    return (colour ^ WxorB);
  }

  int PAWN_OPP(int pawn) {
    return (pawn ^ (WhitePawn256 ^ BlackPawn256));
  }

  int PIECE_COLOUR(int piece) {
    return ((piece & 3) - 1);
  }

  int PIECE_TYPE(int piece) {
    return (piece & bnot3);
  }

  bool PIECE_IS_PAWN(int piece) {
    return ((piece & PawnFlags) != 0);
  }

  bool PIECE_IS_KNIGHT(int piece) {
    return ((piece & KnightFlag) != 0);
  }

  bool PIECE_IS_BISHOP(int piece) {
    return ((piece & QueenFlags) == BishopFlag);
  }

  bool PIECE_IS_ROOK(int piece) {
    return ((piece & QueenFlags) == RookFlag);
  }

  bool PIECE_IS_QUEEN(int piece) {
    return ((piece & QueenFlags) == QueenFlags);
  }

  bool PIECE_IS_KING(int piece) {
    return ((piece & KingFlag) != 0);
  }

  bool PIECE_IS_SLIDER(int piece) {
    return ((piece & QueenFlags) != 0);
  }

  bool SQUARE_IS_OK(int square) {
    return ((square - 0x44 & bnotx77) == 0);
  }

  int SQUARE_MAKE(int file, int rank) {
    return ((rank << 4) | file);
  }

  int SQUARE_FILE(int square) {
    return (square & 0xF);
  }

  int SQUARE_RANK(int square) {
    return (square >>> 4);
  }

  int SQUARE_EP_DUAL(int square) {
    return (square ^ 16);
  }

  int SQUARE_COLOUR(int square) {
    return ((square ^ (square >>> 4)) & 1);
  }

  int SQUARE_FILE_MIRROR(int square) {
    return (square ^ 0x0F);
  }

  int SQUARE_RANK_MIRROR(int square) {
    return (square ^ 0xF0);
  }

  int FILE_OPP(int file) {
    return (file ^ 0xF);
  }

  int RANK_OPP(int rank) {
    return (rank ^ 0xF);
  }

  int PAWN_RANK(int square, int colour) {
    return (SQUARE_RANK(square) ^ RankMask[colour]);
  }

  int PAWN_PROMOTE(int square, int colour) {
    return (PromoteRank[colour] | (square & 0xF));
  }

  int KING_POS(board_t board, int colour) {
    return board.piece[colour][0];
  }

  int MOVE_MAKE(int from, int to) {
    return ((SquareTo64[from] << 6) | SquareTo64[to]);
  }

  int MOVE_MAKE_FLAGS(int from, int to, int flags) {
    return ((SquareTo64[from] << 6) | (SquareTo64[to] | flags));
  }

  int MOVE_FROM(int move) {
    return SquareFrom64[((move >>> 6) & 63)];
  }

  int MOVE_TO(int move) {
    return SquareFrom64[(move & 63)];
  }

  bool MOVE_IS_SPECIAL(int move) {
    return ((move & MoveFlags) != MoveNormal);
  }

  bool MOVE_IS_PROMOTE(int move) {
    return ((move & MoveFlags) == MovePromote);
  }

  bool MOVE_IS_EN_PASSANT(int move) {
    return ((move & MoveFlags) == MoveEnPassant);
  }

  bool MOVE_IS_CASTLE(int move) {
    return ((move & MoveFlags) == MoveCastle);
  }

  int MOVE_PIECE(int move, board_t board) {
    return (board.square[MOVE_FROM(move)]);
  }

  int DELTA_INC_LINE(int delta) {
    return DeltaIncLine[DeltaOffset + delta];
  }

  int DELTA_INC_ALL(int delta) {
    return DeltaIncAll[DeltaOffset + delta];
  }

  int DELTA_MASK(int delta) {
    return DeltaMask[DeltaOffset + delta];
  }

  int DISTANCE(int square_1, int square_2) {
    return Distance[DeltaOffset + (square_2 - square_1)];
  }

  INC_MASK(int inc) {
    return IncMask[IncOffset + inc];
  }

  bool PSEUDO_ATTACK(int piece, int delta) {
    return ((piece & DELTA_MASK(delta)) != 0);
  }

  bool PIECE_ATTACK(board_t board, int piece, int from, int to) {
    return PSEUDO_ATTACK(piece, to - from) && line_is_empty(board, from, to);
  }

  bool SLIDER_ATTACK(int piece, int inc) {
    return ((piece & INC_MASK(inc)) != 0);
  }

  bool ATTACK_IN_CHECK(attack_t attack) {
    return (attack.dn != 0);
  }

  KEY_INDEX(key) {
    return (key & 0xFFFFFFFF); // uint32(key))
  }

// no 64 bits maybe, so, we use the original key
  KEY_LOCK(key) {
    return key; // instead of uint32((key >> 32));
  }

  int Pget(int piece_12, int square_64, int stage) {
    return Pst[piece_12][square_64][stage];
  }

  Pset(int piece_12, int square_64, int stage, int value) {
    Pst[piece_12][square_64][stage] = value;
  }

  Padd(int piece_12, int square_64, int stage, int value) {
    Pst[piece_12][square_64][stage] += value;
  }

  Pmul(int piece_12, int square_64, int stage, int value) {
    Pst[piece_12][square_64][stage] *= value;
  }

  int square_make(int file, int rank) {
    //ASSERT(610, file >= 0 && file < 8);
    //ASSERT(611, rank >= 0 && rank < 8);
    return ((rank << 3) | file);
  }

  int square_file(int square) {
    //ASSERT(612, square >= 0 && square < 64);
    return (square & 7);
  }

  int square_rank(int square) {
    //ASSERT(613, square >= 0 && square < 64);
    return (square >>> 3);
  }

  int square_opp(int square) {
    //ASSERT(614, square >= 0 && square < 64);
    return (square ^ 56);
  }

  bool depth_is_ok(int depth) {
    return (depth > -128) && (depth < DepthMax);
  }

  bool height_is_ok(int height) {
    return (height >= 0) && (height < HeightMax);
  }

//--------------------------
  square_init() {
    int sq; // int

    for (sq = 0; sq <= 63; sq++) SquareTo64[SquareFrom64[sq]] = sq;
    for (sq = 0; sq < SquareNb; sq++) {
      SquareIsPromote[sq] = SQUARE_IS_OK(sq) &&
          (SQUARE_RANK(sq) == Rank1 || SQUARE_RANK(sq) == Rank8);
    }
  }

  int file_from_char(String c) {
    //ASSERT(886, ("abcdefgh").indexOf(c) >= 0);
    return FileA + (c.codeUnitAt(0) - 97);
  }

  int rank_from_char(String c) {
    //ASSERT(887, ("12345678").indexOf(c) >= 0);
    return Rank1 + (c.codeUnitAt(0) - 49);
  }

  String file_to_char(int file) {
    //ASSERT(888, file >= FileA && file <= FileH);
    return String.fromCharCode(97 + (file - FileA));
  }

  String rank_to_char(int rank) {
    //ASSERT(889, rank >= Rank1 && rank <= Rank8);
    return String.fromCharCode(49 + (rank - Rank1));
  }

  square_to_string(int square, string_t str1) {
    //ASSERT(890, SQUARE_IS_OK(square));
    str1.v =
        file_to_char(SQUARE_FILE(square)) + rank_to_char(SQUARE_RANK(square));
  }

  int square_from_string(string_t str1) {
    int file = 0; // int
    int rank = 0; // int
    String c1 = " "; // char
    String c2 = " "; // char

    c1 = str1.v[0];
    if (("abcdefgh").indexOf(c1) < 0) return SquareNone;

    c2 = str1.v[1];
    if (("12345678").indexOf(c2) < 0) return SquareNone;

    file = file_from_char(c1);
    rank = rank_from_char(c2);

    return SQUARE_MAKE(file, rank);
  }

  if_fen_err(bool logic, String fenstr, int pos) {
    if (logic) {
      my_fatal(
          "board_from_fen: bad FEN " + fenstr + " at pos=" + pos.toString());
    }
  }

  board_from_fen(board_t board, String fen) {
    int pos; // int
    int file; // int
    int rank; // int
    int sq; // int
    String c = " "; // char
    String nb = ""; // string
    int i; // int
    int len; // int
    int piece; // int
    int pawn; // int
    bool gotoupdate = false;

    board_clear(board);

    pos = 0;
    c = fen[pos];

// piece placement
    for (rank = Rank8; rank >= Rank1; rank--) {
      file = FileA;
      while (file <= FileH) {
        if (("12345678").indexOf(c) >= 0) {
          // empty square(s)

          len = (c.codeUnitAt(0) - 48);

          for (i = 0; i < len; i++) {
            if_fen_err(file > FileH, fen, pos);

            board.square[SQUARE_MAKE(file, rank)] = Empty;
            file++;
          }
        } else {
          // piece

          piece = piece_from_char(c);
          if_fen_err(piece == PieceNone256, fen, pos);

          board.square[SQUARE_MAKE(file, rank)] = piece;
          file++;
        }

        pos++;
        c = fen[pos];
      }

      if (rank > Rank1) {
        if_fen_err(c != "/", fen, pos);
        pos++;
        c = fen[pos];
      }
    }

// active colour
    if_fen_err(c != " ", fen, pos);

    pos++;
    c = fen[pos];

    if (c == "w") {
      board.turn = White;
    } else {
      if (c == "b") {
        board.turn = Black;
      } else {
        if_fen_err(true, fen, pos);
      }
    }

    pos++;
    c = fen[pos];

// castling
    if_fen_err(c != " ", fen, pos);

    pos++;
    c = fen[pos];

    board.flags = FlagsNone;

    if (c == "-") {
      // no castling rights

      pos++;
      c = fen[pos];
    } else {
      if (c == "K") {
        if (board.square[E1] == WK && board.square[H1] == WR) {
          board.flags = (board.flags | FlagsWhiteKingCastle);
        }
        pos++;
        c = fen[pos];
      }

      if (c == "Q") {
        if (board.square[E1] == WK && board.square[A1] == WR) {
          board.flags = (board.flags | FlagsWhiteQueenCastle);
        }
        pos++;
        c = fen[pos];
      }

      if (c == "k") {
        if (board.square[E8] == BK && board.square[H8] == BR) {
          board.flags = (board.flags | FlagsBlackKingCastle);
        }
        pos++;
        c = fen[pos];
      }

      if (c == "q") {
        if (board.square[E8] == BK && board.square[A8] == BR) {
          board.flags = (board.flags | FlagsBlackQueenCastle);
        }
        pos++;
        c = fen[pos];
      }
    }

// en-passant
    if_fen_err(c != " ", fen, pos);

    pos++;
    c = fen[pos];

    if (c == "-") {
      // no en-passant

      sq = SquareNone;
      pos++;
      c = fen[pos];
    } else {
      if_fen_err((("abcdefgh").indexOf(c) < 0), fen, pos);
      file = file_from_char(c);
      pos++;
      c = fen[pos];

      if_fen_err(c != (COLOUR_IS_WHITE(board.turn) ? "6" : "3"), fen, pos);

      rank = rank_from_char(c);
      pos++;
      c = fen[pos];

      sq = SQUARE_MAKE(file, rank);
      pawn = SQUARE_EP_DUAL(sq);

      if (board.square[sq] != Empty ||
          board.square[pawn] != PawnMake[COLOUR_OPP(board.turn)] ||
          (board.square[pawn - 1] != PawnMake[board.turn] &&
              board.square[pawn + 1] != PawnMake[board.turn])) {
        sq = SquareNone;
      }
    }

    board.ep_square = sq;

// halfmove clock
    board.ply_nb = 0;
    board.movenumb = 0;

    if (c != " ") {
      if (!Strict) {
        gotoupdate = true;
      } else {
        if_fen_err(true, fen, pos);
      }
    }

    if (!gotoupdate) {
      pos++;
      c = fen[pos];

      if (("0123456789").indexOf(c) < 0) {
        if (!Strict) {
          gotoupdate = true;
        } else {
          if_fen_err(true, fen, pos);
        }
      }
    }

    if (!gotoupdate) {
      nb = str_after_ok(fen.substring(pos), " "); // ignore halfmove clock
      board.ply_nb = int.parse(nb);
      board.movenumb = board.ply_nb; // just save it
    }

// board update
    board_init_list(board);
  }

  board_to_fen(board_t board, string_t strfen) {
    int file; // int
    int rank; // int
    int sq; // int
    int piece; // int
    String c = " "; // string
    int len; // int
    String fen = ""; // string
    string_t str1 = new string_t();

// piece placement
    for (rank = Rank8; rank >= Rank1; rank--) {
      file = FileA;
      while (file <= FileH) {
        sq = SQUARE_MAKE(file, rank);
        piece = board.square[sq];
        //ASSERT(248, piece == Empty || piece_is_ok(piece));

        if (piece == Empty) {
          len = 0;
          while (
              file <= FileH && board.square[SQUARE_MAKE(file, rank)] == Empty) {
            file++;
            len++;
          }

          //ASSERT(249, len >= 1 && len <= 8);
          c = String.fromCharCode(48 + len);
        } else {
          c = piece_to_char(piece);
          file++;
        }

        fen += c;
      }

      if (rank != Rank1) fen = fen + "/";
    }

// active colour
    fen += " " + (COLOUR_IS_WHITE(board.turn) ? "w" : "b") + " ";

// castling
    if (board.flags == FlagsNone)
      fen += "-";
    else {
      if ((board.flags & FlagsWhiteKingCastle) != 0) fen += "K";
      if ((board.flags & FlagsWhiteQueenCastle) != 0) fen += "Q";
      if ((board.flags & FlagsBlackKingCastle) != 0) fen += "k";
      if ((board.flags & FlagsBlackQueenCastle) != 0) fen += "q";
    }

    fen += " ";

// en-passant
    if (board.ep_square == SquareNone)
      fen += "-";
    else {
      square_to_string(board.ep_square, str1);
      fen += str1.v;
    }

    fen += " ";

// ignoring halfmove clock
    fen += "0 " + board.movenumb.toString();

    strfen.v = fen;
  }

// to see chessboard on screen
  printboard() {
    int file; // int
    int rank; // int
    int sq; // int
    int piece; // int
    string_t str1 = new string_t();
    String s = ""; //  string
    board_t board = SearchInput.board;

// piece placement

    for (rank = Rank8; rank >= Rank1; rank--) {
      file = FileA;
      while (file <= FileH) {
        sq = SQUARE_MAKE(file, rank);
        piece = board.square[sq];
        //ASSERT(248, piece == Empty || piece_is_ok(piece));

        s += ((piece == Empty) ? "." : piece_to_char(piece)) + " ";

        file++;
      }

      s += "\n";
    }

    board_to_fen(board, str1);

    s += str1.v + "\n";

    print_out(s);
  }

  bool IS_IN_CHECK(board_t board, int colour) {
    return is_attacked(board, KING_POS(board, colour), COLOUR_OPP(colour));
  }

  LIST_ADD(list_t list, int mv) {
    list.move[list.size] = mv;
    list.size++;
  }

  LIST_CLEAR(list_t list) {
    list.size = 0;
  }

  material_info_copy(material_info_t dst, material_info_t src) {
    dst.lock = src.lock;
    dst.recog = src.recog;

    dst.cflags[0] = src.cflags[0];
    dst.cflags[1] = src.cflags[1];

    dst.mul[0] = src.mul[0];
    dst.mul[1] = src.mul[1];

    dst.phase = src.phase;
    dst.opening = src.opening;
    dst.endgame = src.endgame;

    dst.flags = src.flags;
  }

  pawn_info_copy(pawn_info_t dst, pawn_info_t src) {
    dst.lock = src.lock;
    dst.opening = src.opening;
    dst.endgame = src.endgame;
    dst.flags[0] = src.flags[0];
    dst.flags[1] = src.flags[1];
    dst.passed_bits[0] = src.passed_bits[0];
    dst.passed_bits[1] = src.passed_bits[1];
    dst.single_file[0] = src.single_file[0];
    dst.single_file[1] = src.single_file[1];
    dst.pad = src.pad;
  }

  set_opt_t_def(
      int k, String vary, bool decl, String init, String type, String extra) {
    Option[k].vary = vary; // string
    Option[k].decl = decl; // bool
    Option[k].init = init; // string
    Option[k].val = init; // string the same as init
    Option[k].type = type; // string
    Option[k].extra = extra; // string
  }

  vector_init() {
    int delta; // int
    int x; // int
    int y; // int
    int dist; // int
    int tmp; // int

    for (y = -7; y <= 7; y++) {
      for (x = -7; x <= 7; x++) {
        delta = y * 16 + x;
        //ASSERT(964, delta_is_ok(delta));
        dist = 0;
        tmp = x;
        if (tmp < 0) tmp = -tmp;
        if (tmp > dist) dist = tmp;
        tmp = y;
        if (tmp < 0) tmp = -tmp;
        if (tmp > dist) dist = tmp;

        Distance[DeltaOffset + delta] = dist;
      }
    }
  }

  bool delta_is_ok(int delta) {
    if (delta < -119 || delta > 119) return false;

    if ((delta & 0xF) == 8)
      return false; // delta % 16 would be ill-defined for negative numbers

    return true;
  }

  bool inc_is_ok(int inc) {
    int dir; // int

    for (dir = 0; dir < 8; dir++) {
      if (KingInc[dir] == inc) return true;
    }

    return false;
  }

  my_timer_reset(my_timer_t timer) {
    timer.elapsed = 0.0;
    timer.running = false;
  }

  my_timer_start(my_timer_t timer) {
    timer.running = true;
    timer.started = DateTime.now();
  }

  double my_timer_elapsed_real(my_timer_t timer) {
    if (timer.running) {
      timer.elapsed =
          timer.started.difference(DateTime.now()).inSeconds.abs().toDouble();
    }

    return timer.elapsed;
  }

  attack_init() {
    int delta; // int
    int inc; // int
    int piece; // int
    int dir; // int
    int dist; // int
    int size; // int
    int king; // int
    int from; // int
    int to; // int
    int pos; // int

// pawn attacks

    DeltaMask[DeltaOffset - 17] |= BlackPawnFlag;
    DeltaMask[DeltaOffset - 15] |= BlackPawnFlag;

    DeltaMask[DeltaOffset + 15] |= WhitePawnFlag;
    DeltaMask[DeltaOffset + 17] |= WhitePawnFlag;

// knight attacks

    for (dir = 0; dir < 8; dir++) {
      delta = KnightInc[dir];
      //ASSERT(3, delta_is_ok(delta));

      //ASSERT(4, DeltaIncAll[DeltaOffset + delta] == IncNone);
      DeltaIncAll[DeltaOffset + delta] = delta;
      DeltaMask[DeltaOffset + delta] |= KnightFlag;
    }

// bishop/queen attacks

    for (dir = 0; dir <= 3; dir++) {
      inc = BishopInc[dir];
      //ASSERT(5, inc != IncNone);

      IncMask[IncOffset + inc] |= BishopFlag;

      for (dist = 1; dist < 8; dist++) {
        delta = inc * dist;
        //ASSERT(6, delta_is_ok(delta));

        //ASSERT(7, DeltaIncLine[DeltaOffset + delta] == IncNone);
        DeltaIncLine[DeltaOffset + delta] = inc;
        //ASSERT(8, DeltaIncAll[DeltaOffset + delta] == IncNone);
        DeltaIncAll[DeltaOffset + delta] = inc;
        DeltaMask[DeltaOffset + delta] |= BishopFlag;
      }
    }

// rook/queen attacks

    for (dir = 0; dir < 4; dir++) {
      inc = RookInc[dir];
      //ASSERT(9, inc != IncNone);

      IncMask[IncOffset + inc] |= RookFlag;

      for (dist = 1; dist < 8; dist++) {
        delta = inc * dist;
        //ASSERT(10, delta_is_ok(delta));

        //ASSERT(11, DeltaIncLine[DeltaOffset + delta] == IncNone);
        DeltaIncLine[DeltaOffset + delta] = inc;
        //ASSERT(12, DeltaIncAll[DeltaOffset + delta] == IncNone);
        DeltaIncAll[DeltaOffset + delta] = inc;
        DeltaMask[DeltaOffset + delta] |= RookFlag;
      }
    }

// king attacks

    for (dir = 0; dir < 8; dir++) {
      delta = KingInc[dir];
      //ASSERT(13, delta_is_ok(delta));

      DeltaMask[DeltaOffset + delta] |= KingFlag;
    }

// PieceCode
    PieceCode[WN] = 0;
    PieceCode[WB] = 1;
    PieceCode[WR] = 2;
    PieceCode[WQ] = 3;

    PieceCode[BN] = 0;
    PieceCode[BB] = 1;
    PieceCode[BR] = 2;
    PieceCode[BQ] = 3;

// PieceDeltaSize[][] & PieceDeltaDelta[][][]
    for (piece = 0; piece <= 3; piece++) {
      PieceDeltaSize.add(List.filled(256, 0));
      PieceDeltaDelta.add([]);

      for (delta = 0; delta < 256; delta++)
        PieceDeltaDelta[piece].add(List.filled(4, 0));
    }

    for (king = 0; king < SquareNb; king++) {
      if (SQUARE_IS_OK(king)) {
        for (from = 0; from < SquareNb; from++) {
          if (SQUARE_IS_OK(from)) {
// knight
            pos = 0;
            for (;;) {
              inc = KnightInc[pos];
              if (inc == IncNone) break;
              to = from + inc;
              if (SQUARE_IS_OK(to) && DISTANCE(to, king) == 1) {
                add_attack(0, king - from, to - from);
              }
              pos++;
            }

// bishop
            pos = 0;
            for (;;) {
              inc = BishopInc[pos];
              if (inc == IncNone) break;
              to = from + inc;
              while (SQUARE_IS_OK(to)) {
                if (DISTANCE(to, king) == 1) {
                  add_attack(1, king - from, to - from);
                  break;
                }
                to += inc;
              }
              pos++;
            }

// rook
            pos = 0;
            for (;;) {
              inc = RookInc[pos];
              if (inc == IncNone) break;
              to = from + inc;
              while (SQUARE_IS_OK(to)) {
                if (DISTANCE(to, king) == 1) {
                  add_attack(2, king - from, to - from);
                  break;
                }
                to += inc;
              }
              pos++;
            }

// queen
            pos = 0;
            for (;;) {
              inc = QueenInc[pos];
              if (inc == IncNone) break;
              to = from + inc;
              while (SQUARE_IS_OK(to)) {
                if (DISTANCE(to, king) == 1) {
                  add_attack(3, king - from, to - from);
                  break;
                }
                to += inc;
              }
              pos++;
            }
          }
        }
      }

      for (piece = 0; piece < 4; piece++) {
        for (delta = 0; delta < 256; delta++) {
          size = PieceDeltaSize[piece][delta];
          //ASSERT(14, size >= 0 && size < 3);
          PieceDeltaDelta[piece][delta][size] = DeltaNone;
        }
      }
    }
  }

  add_attack(int piece, int king, int target) {
    int size; // int
    int i; // int

    //ASSERT(15, piece >= 0 && piece < 4);
    //ASSERT(16, delta_is_ok(king));
    //ASSERT(17, delta_is_ok(target));

    size = PieceDeltaSize[piece][DeltaOffset + king];
    //ASSERT(18, size >= 0 && size < 3);

    for (i = 0; i < size; i++) {
      if (PieceDeltaDelta[piece][DeltaOffset + king][i] == target)
        return; // already in the table
    }

    if (size < 2) {
      PieceDeltaDelta[piece][DeltaOffset + king][size] = target;
      size++;
      PieceDeltaSize[piece][DeltaOffset + king] = size;
    }
  }

  bool is_attacked(board_t board, int to, int colour) {
    // bool

    int inc; // int
    int pawn; // int
    int ptr; // int
    int from; // int
    int piece; // int
    int delta; // int
    int sq; // int

    //ASSERT(20, SQUARE_IS_OK(to));
    //ASSERT(21, COLOUR_IS_OK(colour));

// pawn attack
    inc = PawnMoveInc[colour];
    pawn = PawnMake[colour];

    if (board.square[to - (inc - 1)] == pawn) return true;

    if (board.square[to - (inc + 1)] == pawn) return true;

// piece attack
    ptr = 0;
    for (;;) {
      from = board.piece[colour][ptr];
      if (from == SquareNone) break;
      piece = board.square[from];
      delta = to - from;

      if (PSEUDO_ATTACK(piece, delta)) {
        inc = DELTA_INC_ALL(delta);
        //ASSERT(22, inc != IncNone);

        sq = from;
        for (;;) {
          sq += inc;
          if (sq == to) {
            return true;
          }
          if (board.square[sq] != Empty) break;
        }
      }
      ptr++;
    }

    return false;
  }

  line_is_empty(board_t board, int from, int to) {
    int delta; // int
    int inc; // int
    int sq; // int

    //ASSERT(24, SQUARE_IS_OK(from));
    //ASSERT(25, SQUARE_IS_OK(to));

    delta = to - from;
    //ASSERT(26, delta_is_ok(delta));

    inc = DELTA_INC_ALL(delta);
    //ASSERT(27, inc != IncNone);

    sq = from;
    for (;;) {
      sq += inc;
      if (sq == to) return true;
      if (board.square[sq] != Empty) break;
    }

    return false; // blocker
  }

  bool is_pinned(board_t board, int square, int colour) {
    int from; // int
    int to; // int
    int inc; // int
    int sq; // int
    int piece; // int

    //ASSERT(29, SQUARE_IS_OK(square));
    //ASSERT(30, COLOUR_IS_OK(colour));

    from = square;
    to = KING_POS(board, colour);

    inc = DELTA_INC_LINE(to - from);
    if (inc == IncNone) return false; // not a line

    sq = from;
    for (;;) {
      sq += inc;
      if (board.square[sq] != Empty) break;
    }

    if (sq != to) return false; // blocker

    sq = from;
    for (;;) {
      sq -= inc;
      piece = board.square[sq];
      if (piece != Empty) break;
    }

    return COLOUR_IS(piece, COLOUR_OPP(colour)) && SLIDER_ATTACK(piece, inc);
  }

  bool attack_is_ok(attack_t attack) {
    int i; // int
    int sq; // int
    int inc; // int

// checks

    if (attack.dn < 0 || attack.dn > 2) return false;

    for (i = 0; i < attack.dn; i++) {
      sq = attack.ds[i];
      if (!SQUARE_IS_OK(sq)) return false;

      inc = attack.di[i];
      if (inc != IncNone && (!inc_is_ok(inc))) return false;
    }

    if (attack.ds[attack.dn] != SquareNone) return false;

    if (attack.di[attack.dn] != IncNone) return false;

    return true;
  }

  attack_set(attack_t attack, board_t board) {
    int me; // int
    int opp; // int
    int ptr; // int
    int from; // int
    int to; // int
    int inc; // int
    int pawn; // int
    int delta; // int
    int piece; // int
    int sq; // int
    bool cont = false;

// init

    attack.dn = 0;

    me = board.turn;
    opp = COLOUR_OPP(me);

    to = KING_POS(board, me);

// pawn attacks
    inc = PawnMoveInc[opp];
    pawn = PawnMake[opp];

    from = to - (inc - 1);
    if (board.square[from] == pawn) {
      attack.ds[attack.dn] = from;
      attack.di[attack.dn] = IncNone;
      attack.dn++;
    }

    from = to - (inc + 1);
    if (board.square[from] == pawn) {
      attack.ds[attack.dn] = from;
      attack.di[attack.dn] = IncNone;
      attack.dn++;
    }

// piece attacks

    ptr = 1; // no king
    for (;;) {
      from = board.piece[opp][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      delta = to - from;
      //ASSERT(33, delta_is_ok(delta));

      if (PSEUDO_ATTACK(piece, delta)) {
        inc = IncNone;

        if (PIECE_IS_SLIDER(piece)) {
// check for (blockers

          inc = DELTA_INC_LINE(delta);
          //ASSERT(34, inc != IncNone);

          sq = from;
          for (;;) {
            sq += inc;
            if (board.square[sq] != Empty) break;
          }

          if (sq != to) {
            cont = true; // blocker => next attacker
          }
        }

        if (cont) {
          cont = false;
        } else {
          attack.ds[attack.dn] = from;
          attack.di[attack.dn] = -inc;
          attack.dn++;
        }
      }
      ptr++;
    }

    attack.ds[attack.dn] = SquareNone;
    attack.di[attack.dn] = IncNone;

    //ASSERT(35, attack_is_ok(attack));
  }

  bool piece_attack_king(board_t board, int piece, int from, int king) {
    int code; // int
    int delta_ptr; // int
    int delta; // int
    int inc; // int
    int to; // int
    int sq; // int

    //ASSERT(37, piece_is_ok(piece));
    //ASSERT(38, SQUARE_IS_OK(from));
    //ASSERT(39, SQUARE_IS_OK(king));

    code = PieceCode[piece];
    //ASSERT(40, code >= 0 && code < 4);

    if (PIECE_IS_SLIDER(piece)) {
      delta_ptr = 0;
      for (;;) {
        delta = PieceDeltaDelta[code][DeltaOffset + (king - from)][delta_ptr];
        if (delta == DeltaNone) break;

        //ASSERT(41, delta_is_ok(delta));
        inc = DeltaIncLine[DeltaOffset + delta];
        //ASSERT(42, inc != IncNone);
        to = from + delta;

        sq = from;
        for (;;) {
          sq += inc;

          if (sq == to && SQUARE_IS_OK(to)) {
            //ASSERT(43, DISTANCE(to, king) == 1);
            return true;
          }

          if (board.square[sq] != Empty) break;
        }

        delta_ptr++;
      }
    } else {
      // non-slider

      delta_ptr = 0;
      for (;;) {
        delta = PieceDeltaDelta[code][DeltaOffset + (king - from)][delta_ptr];
        if (delta == DeltaNone) break;

        //ASSERT(44, delta_is_ok(delta));

        to = from + delta;

        if (SQUARE_IS_OK(to)) {
          //ASSERT(45, DISTANCE(to, king) == 1);
          return true;
        }

        delta_ptr++;
      }
    }

    return false;
  }

  int see_move(int move, board_t board) {
    int att; // int
    int def; // int
    int from; // int
    int to; // int
    int value; // int
    int piece_value; // int
    int piece; // int
    int capture; // int
    int pos; // int
    alists_t alists = new alists_t(); // alists_t[1]
    alist_t alist = new alist_t(); // alist_t *

    //ASSERT(745, move_is_ok(move));

// init
    from = MOVE_FROM(move);
    to = MOVE_TO(move);

// move the piece

    piece_value = 0;

    piece = board.square[from];
    //ASSERT(747, piece_is_ok(piece));

    att = PIECE_COLOUR(piece);
    def = COLOUR_OPP(att);

// promote

    if (MOVE_IS_PROMOTE(move)) {
      //ASSERT(748, PIECE_IS_PAWN(piece));
      piece = move_promote(move);
      //ASSERT(749, piece_is_ok(piece));
      //ASSERT(750, COLOUR_IS(piece, att));
    }

    piece_value += ValuePiece[piece];

// clear attacker lists

    alist_clear(alists.alist[Black]);
    alist_clear(alists.alist[White]);

// find hidden attackers

    alists_hidden(alists, board, from, to);

// capture the piece

    value = 0;

    capture = board.square[to];

    if (capture != Empty) {
      //ASSERT(751, piece_is_ok(capture));
      //ASSERT(752, COLOUR_IS(capture, def));

      value += ValuePiece[capture];
    }

// promote
    if (MOVE_IS_PROMOTE(move)) value += ValuePiece[piece] - ValuePawn;

// en-passant

    if (MOVE_IS_EN_PASSANT(move)) {
      //ASSERT(753, value == 0);
      //ASSERT(754, PIECE_IS_PAWN(board.square[SQUARE_EP_DUAL(to)]));
      value += ValuePawn;
      alists_hidden(alists, board, SQUARE_EP_DUAL(to), to);
    }

// build defender list

    alist = alists.alist[def];

    alist_build(alist, board, to, def);
    if (alist.size == 0) return value; // no defender => stop SEE

// build attacker list

    alist = alists.alist[att];

    alist_build(alist, board, to, att);

// remove the moved piece (if it's an attacker)

    pos = 0;
    while (pos < alist.size && alist.square[pos] != from) pos++;

    if (pos < alist.size) alist_remove(alist, pos);

// SEE search

    value -= see_rec(alists, board, def, to, piece_value);

    return value;
  }

  int see_square(board_t board, int to, int colour) {
    int att; // int
    int def; // int
    int piece_value; // int
    int piece; // int
    alists_t alists = new alists_t(); // alists_t[1]
    alist_t alist = new alist_t(); // alist_t *

    //ASSERT(756, SQUARE_IS_OK(to));
    //ASSERT(757, COLOUR_IS_OK(colour));

    //ASSERT(758, COLOUR_IS(board.square[to], COLOUR_OPP(colour)));

// build attacker list

    att = colour;
    alist = alists.alist[att];
    alist_clear(alist);
    alist_build(alist, board, to, att);

    if (alist.size == 0) return 0; // no attacker => stop SEE

// build defender list

    def = COLOUR_OPP(att);
    alist = alists.alist[def];
    alist_clear(alist);

    alist_build(alist, board, to, def);

// captured piece

    piece = board.square[to];
    //ASSERT(759, piece_is_ok(piece));
    //ASSERT(760, COLOUR_IS(piece, def));

    piece_value = ValuePiece[piece];

// SEE search

    return see_rec(alists, board, att, to, piece_value);
  }

  int see_rec(
      alists_t alists, board_t board, int colour, int to, int piece_value) {
    int from; // int
    int piece; // int
    int value; // int

    //ASSERT(763, COLOUR_IS_OK(colour));
    //ASSERT(764, SQUARE_IS_OK(to));
    //ASSERT(765, piece_value > 0);

// find the least valuable attacker

    from = alist_pop(alists.alist[colour], board);
    if (from == SquareNone) return 0; // no more attackers

// find hidden attackers

    alists_hidden(alists, board, from, to);

// calculate the capture value

    value = piece_value; // captured piece
    if (value == ValueKing) {
      return value; // do not allow an answer to a king capture
    }

    piece = board.square[from];
    //ASSERT(766, piece_is_ok(piece));
    //ASSERT(767, COLOUR_IS(piece, colour));
    piece_value = ValuePiece[piece];

// promote

    if (piece_value == ValuePawn && SquareIsPromote[to]) {
      // PIECE_IS_PAWN(piece)
      //ASSERT(768, PIECE_IS_PAWN(piece));
      piece_value = ValueQueen;
      value += ValueQueen - ValuePawn;
    }

    value -= see_rec(alists, board, COLOUR_OPP(colour), to, piece_value);

    if (value < 0) value = 0;

    return value;
  }

  alist_build(alist_t alist, board_t board, int to, int colour) {
    int ptr; // int
    int from; // int
    int piece; // int
    int delta; // int
    int inc; // int
    int sq; // int
    int pawn; // int

    //ASSERT(771, SQUARE_IS_OK(to));
    //ASSERT(772, COLOUR_IS_OK(colour));

// piece attacks

    ptr = 0;
    for (;;) {
      from = board.piece[colour][ptr];

      if (from == SquareNone) break;

      piece = board.square[from];
      delta = to - from;

      if (PSEUDO_ATTACK(piece, delta)) {
        inc = DELTA_INC_ALL(delta);
        //ASSERT(773, inc != IncNone);

        sq = from;
        for (;;) {
          sq += inc;
          if (sq == to) {
            // attack
            alist_add(alist, from, board);
            break;
          }

          if (board.square[sq] != Empty) break;
        }
      }

      ptr++;
    }

// pawn attacks
    inc = PawnMoveInc[colour];
    pawn = PawnMake[colour];

    from = to - (inc - 1);
    if (board.square[from] == pawn) alist_add(alist, from, board);

    from = to - (inc + 1);
    if (board.square[from] == pawn) alist_add(alist, from, board);
  }

  alists_hidden(alists_t alists, board_t board, int from, int to) {
    int inc; // int
    int sq; // int
    int piece; // int

    //ASSERT(776, SQUARE_IS_OK(from));
    //ASSERT(777, SQUARE_IS_OK(to));

    inc = DELTA_INC_LINE(to - from);

    if (inc != IncNone) {
      // line

      sq = from;

      for (;;) {
        sq -= inc;
        piece = board.square[sq];
        if (piece != Empty) break;
      }

      if (SLIDER_ATTACK(piece, inc)) {
        //ASSERT(778, piece_is_ok(piece));
        //ASSERT(779, PIECE_IS_SLIDER(piece));

        alist_add(alists.alist[PIECE_COLOUR(piece)], sq, board);
      }
    }
  }

  alist_clear(alist_t alist) {
    alist.size = 0;
  }

  alist_add(alist_t alist, int square, board_t board) {
    int piece; // int
    int size; // int
    int pos; // int

    //ASSERT(782, SQUARE_IS_OK(square));

// insert in MV order
    piece = board.square[square];

    alist.size++;
    size = alist.size;

    //ASSERT(784, size > 0 && size < 16);

    pos = size - 1;
    while (pos > 0 && piece > board.square[alist.square[pos - 1]]) {
      //ASSERT(785, pos > 0 && pos < size);
      alist.square[pos] = alist.square[pos - 1];
      pos--;
    }

    //ASSERT(786, pos >= 0 && pos < size);
    alist.square[pos] = square;
  }

  alist_remove(alist_t alist, int pos) {
    int size; // int
    int i; // int

    //ASSERT(788, pos >= 0 && pos < alist.size);

    size = alist.size;
    alist.size--;

    //ASSERT(789, size >= 1);

    //ASSERT(790, pos >= 0 && pos < size);

    for (i = pos; i <= size - 2; i++) {
      //ASSERT(791, i >= 0 && i < size - 1);
      alist.square[i] = alist.square[i + 1];
    }
  }

  int alist_pop(alist_t alist, board_t board) {
    int sq; // int
    int size; // int

    sq = SquareNone;

    size = alist.size;

    if (size != 0) {
      size--;
      //ASSERT(794, size >= 0);
      sq = alist.square[size];
      alist.size = size;
    }

    return sq;
  }

  bool board_is_ok(board_t board) {
    int sq; // int
    int piece; // int
    int colour; // int
    int size; // int
    int pos; // int

// squares
    for (sq = 0; sq < SquareNb; sq++) {
      piece = board.square[sq];
      pos = board.pos[sq];

      if (SQUARE_IS_OK(sq)) {
// inside square

        if (piece == Empty) {
          if (pos != -1) return false;
        } else {
          if (!piece_is_ok(piece)) return false;

          if (!PIECE_IS_PAWN(piece)) {
            colour = PIECE_COLOUR(piece);
            if (pos < 0 || pos >= board.piece_size[colour]) return false;
            if (board.piece[colour][pos] != sq) return false;
          } else {
            // pawn
            if (SquareIsPromote[sq]) return false;

            colour = PIECE_COLOUR(piece);
            if (pos < 0 || pos >= board.pawn_size[colour]) return false;
            if (board.pawn[colour][pos] != sq) return false;
          }
        }
      } else {
// edge square
        if (piece != Edge) return false;
        if (pos != -1) return false;
      }
    }

// piece lists
    for (colour = 0; colour <= 1; colour++) {
// piece list
      size = board.piece_size[colour];
      if (size < 1 || size > 16) return false;

      for (pos = 0; pos < size; pos++) {
        sq = board.piece[colour][pos];
        if (!SQUARE_IS_OK(sq)) return false;
        if (board.pos[sq] != pos) return false;
        piece = board.square[sq];
        if (!COLOUR_IS(piece, colour)) return false;
        if (pos == 0 && (!PIECE_IS_KING(piece))) return false;
        if (pos != 0 && PIECE_IS_KING(piece)) return false;
        if (pos != 0 &&
            PieceOrder[piece] >
                PieceOrder[board.square[board.piece[colour][pos - 1]]])
          return false;
      }

      sq = board.piece[colour][size];
      if (sq != SquareNone) return false;

// pawn list
      size = board.pawn_size[colour];
      if (size < 0 || size > 8) return false;

      for (pos = 0; pos < size; pos++) {
        sq = board.pawn[colour][pos];
        if (!SQUARE_IS_OK(sq)) return false;
        if (SquareIsPromote[sq]) return false;
        if (board.pos[sq] != pos) return false;
        piece = board.square[sq];
        if (!COLOUR_IS(piece, colour)) return false;
        if (!PIECE_IS_PAWN(piece)) return false;
      }

      sq = board.pawn[colour][size];
      if (sq != SquareNone) return false;

// piece total
      if (board.piece_size[colour] + board.pawn_size[colour] > 16) return false;
    }

// material
    if (board.piece_nb !=
        board.piece_size[White] +
            board.pawn_size[White] +
            board.piece_size[Black] +
            board.pawn_size[Black]) {
      return false;
    }

    if (board.number[WhitePawn12] != board.pawn_size[White]) return false;
    if (board.number[BlackPawn12] != board.pawn_size[Black]) return false;
    if (board.number[WhiteKing12] != 1) return false;
    if (board.number[BlackKing12] != 1) return false;

// misc

    if (!COLOUR_IS_OK(board.turn)) return false;
    if (board.ply_nb < 0) return false;
    if (board.sp < board.ply_nb) return false;
    if (board.cap_sq != SquareNone && (!SQUARE_IS_OK(board.cap_sq)))
      return false;
    if (board.opening != board_opening(board)) return false;
    if (board.endgame != board_endgame(board)) return false;
    return true;
  }

  board_clear(board_t board) {
    int sq; // int
    int sq_64; // int

// edge squares
    board.square = List.filled(SquareNb, Edge);

// empty squares
    for (sq_64 = 0; sq_64 <= 63; sq_64++) {
      sq = SquareFrom64[sq_64];
      board.square[sq] = Empty;
    }

// misc
    board.turn = ColourNone;
    board.flags = FlagsNone;
    board.ep_square = SquareNone;
    board.ply_nb = 0;
  }

  board_copy(board_t dst, board_t src) {
    int i; // int

    //ASSERT(48, board_is_ok(src));

    for (i = 0; i < src.square.length; i++) dst.square[i] = src.square[i];
    for (i = 0; i < src.pos.length; i++) dst.pos[i] = src.pos[i];

    for (i = 0; i < src.piece[0].length; i++) dst.piece[0][i] = src.piece[0][i];
    for (i = 0; i < src.piece[1].length; i++) dst.piece[1][i] = src.piece[1][i];

    for (i = 0; i < src.piece_size.length; i++)
      dst.piece_size[i] = src.piece_size[i];

    //dst.piece_size = src.piece_size;

    for (i = 0; i < src.pawn[0].length; i++) dst.pawn[0][i] = src.pawn[0][i];

    for (i = 0; i < src.pawn[1].length; i++) dst.pawn[1][i] = src.pawn[1][i];

    for (i = 0; i < src.pawn_size.length; i++)
      dst.pawn_size[i] = src.pawn_size[i];

    dst.piece_nb = src.piece_nb;
    for (i = 0; i < src.number.length; i++) dst.number[i] = src.number[i];

    for (i = 0; i < src.pawn_file[0].length; i++)
      dst.pawn_file[0][i] = src.pawn_file[0][i];

    for (i = 0; i < src.pawn_file[1].length; i++)
      dst.pawn_file[1][i] = src.pawn_file[1][i];

    dst.turn = src.turn;
    dst.flags = src.flags;
    dst.ep_square = src.ep_square;
    dst.ply_nb = src.ply_nb;
    dst.sp = src.sp;

    dst.cap_sq = src.cap_sq;

    dst.opening = src.opening;
    dst.endgame = src.endgame;

    dst.key = src.key;
    dst.pawn_key = src.pawn_key;
    dst.material_key = src.material_key;

    for (i = 0; i < src.stack.length; i++) dst.stack[i] = src.stack[i];
  }

  board_init_list(board_t board) {
    int sq_64; // int
    int sq; // int
    int piece; // int
    int colour; // int
    int pos; // int
    int i; // int
    int size; // int
    int square; // int
    int order; // int

    bool illegal_pos = false;

// init
    board.pos = List.filled(SquareNb, -1);

    board.piece_nb = 0;

    board.number = List.filled(12, 0);

// piece lists
    for (colour = 0; colour <= 1; colour++) {
// piece list
      pos = 0;

      for (sq_64 = 0; sq_64 <= 63; sq_64++) {
        sq = SquareFrom64[sq_64];
        piece = board.square[sq];
        if (piece != Empty && (!piece_is_ok(piece))) illegal_pos = true;

        if (COLOUR_IS(piece, colour) && (!PIECE_IS_PAWN(piece))) {
          if (pos >= 16) illegal_pos = true;
          //ASSERT(50, pos >= 0 && pos < 16);

          board.pos[sq] = pos;
          board.piece[colour][pos] = sq;
          pos++;

          board.piece_nb++;
          board.number[PieceTo12[piece]]++;
        }
      }

      int kg = (COLOUR_IS_WHITE(colour) ? WhiteKing12 : BlackKing12);
      if (board.number[kg] != 1) illegal_pos = true;

      //ASSERT(51, pos >= 1 && pos <= 16);
      board.piece[colour][pos] = SquareNone;
      board.piece_size[colour] = pos;

// MV sort
      size = board.piece_size[colour];

      for (i = 1; i < size; i++) {
        square = board.piece[colour][i];
        piece = board.square[square];
        order = PieceOrder[piece];
        pos = i;
        while (pos > 0) {
          sq = board.piece[colour][pos - 1];
          if (order <= PieceOrder[board.square[sq]]) break;

          //ASSERT(52, pos > 0 && pos < size);
          board.piece[colour][pos] = sq;
          //ASSERT(53, board.pos[sq] == pos - 1);
          board.pos[sq] = pos;
          pos--;
        }

        //ASSERT(54, pos >= 0 && pos < size);
        board.piece[colour][pos] = square;
        //ASSERT(55, board.pos[square] == i);
        board.pos[square] = pos;
      }

// pawn list

      board.pawn_file[colour] = List.filled(FileNb, 0);

      pos = 0;

      for (sq_64 = 0; sq_64 <= 63; sq_64++) {
        sq = SquareFrom64[sq_64];
        piece = board.square[sq];

        if (COLOUR_IS(piece, colour) && PIECE_IS_PAWN(piece)) {
          if (pos >= 8 || SquareIsPromote[sq]) illegal_pos = true;
          //ASSERT(60, pos >= 0 && pos < 8);

          board.pos[sq] = pos;
          board.pawn[colour][pos] = sq;
          pos++;

          board.piece_nb++;
          board.number[PieceTo12[piece]]++;
          board.pawn_file[colour][SQUARE_FILE(sq)] |=
              BitEQ[PAWN_RANK(sq, colour)];
        }
      }

      //ASSERT(61, pos >= 0 && pos <= 8);
      board.pawn[colour][pos] = SquareNone;
      board.pawn_size[colour] = pos;

      if (board.piece_size[colour] + board.pawn_size[colour] > 16)
        illegal_pos = true;
    }

// last square
    board.cap_sq = SquareNone;

// PST
    board.opening = board_opening(board);
    board.endgame = board_endgame(board);

// hash key

    for (i = 0; i < board.ply_nb; i++) board.stack[i] = 0;
    board.sp = board.ply_nb;

    board.key = hash_key(board);
    board.pawn_key = hash_pawn_key(board);
    board.material_key = hash_material_key(board);

// legality

    if (!board_is_legal(board)) illegal_pos = true;

    if (illegal_pos) my_fatal("board_init_list: illegal position");

    //ASSERT(62, board_is_ok(board));
  }

  bool board_is_legal(board_t board) {
    return (!IS_IN_CHECK(board, COLOUR_OPP(board.turn)));
  }

  bool board_is_check(board_t board) {
    return IS_IN_CHECK(board, board.turn);
  }

  bool board_is_mate(board_t board) {
    attack_t attack = new attack_t(); // attack_t[1]

    attack_set(attack, board);

    if (!ATTACK_IN_CHECK(attack)) return false; // not in check => not mate

    if (legal_evasion_exist(board, attack))
      return false; // legal move => not mate

    return true; // in check && no legal move => mate
  }

  bool board_is_stalemate(board_t board) {
    list_t list = new list_t(); // list_t[1];
    int i; // int
    int move; // int

// init
    if (IS_IN_CHECK(board, board.turn)) {
      return false; // in check => not stalemate
    }

// move loop
    gen_moves(list, board);

    for (i = 0; i < list.size; i++) {
      move = list.move[i];
      if (pseudo_is_legal(move, board)) {
        return false; // legal move => not stalemate
      }
    }

    return true; // in check && no legal move => mate
  }

  bool board_is_repetition(board_t board) {
    int i; // int

// 50-move rule
    if (board.ply_nb >= 100) {
      // potential draw
      if (board.ply_nb > 100) return true;

      //ASSERT(68, board.ply_nb == 100);
      return (!board_is_mate(board));
    }

// position repetition
    //ASSERT(69, board.sp >= board.ply_nb);
    for (i = 4; i < board.ply_nb - 1; i += 2) {
      if (board.stack[board.sp - i] == board.key) return true;
    }

    return false;
  }

  int board_opening(board_t board) {
    int opening; // int
    int colour; // int
    int ptr; // int
    int sq; // int
    int piece; // int

    opening = 0;
    for (colour = 0; colour <= 1; colour++) {
      ptr = 0;
      for (;;) {
        sq = board.piece[colour][ptr];
        if (sq == SquareNone) break;
        piece = board.square[sq];
        opening += Pget(PieceTo12[piece], SquareTo64[sq], Opening);
        ptr++;
      }

      ptr = 0;
      for (;;) {
        sq = board.pawn[colour][ptr];
        if (sq == SquareNone) break;
        piece = board.square[sq];
        opening += Pget(PieceTo12[piece], SquareTo64[sq], Opening);
        ptr++;
      }
    }

    return opening;
  }

  int board_endgame(board_t board) {
    int endgame; // int
    int colour; // int
    int ptr; // int
    int sq; // int
    int piece; // int

    endgame = 0;
    for (colour = 0; colour <= 1; colour++) {
      ptr = 0;
      for (;;) {
        sq = board.piece[colour][ptr];
        if (sq == SquareNone) break;
        piece = board.square[sq];
        endgame += Pget(PieceTo12[piece], SquareTo64[sq], Endgame);
        ptr++;
      }

      ptr = 0;
      for (;;) {
        sq = board.pawn[colour][ptr];
        if (sq == SquareNone) break;
        piece = board.square[sq];
        endgame += Pget(PieceTo12[piece], SquareTo64[sq], Endgame);
        ptr++;
      }
    }

    return endgame;
  }

  eval_init() {
    int colour; // int

// UCI options
    PieceActivityWeight = (option_get_int("Piece Activity") * 256 + 50) ~/ 100;
    KingSafetyWeight = (option_get_int("King Safety") * 256 + 50) ~/ 100;
    PassedPawnWeight = (option_get_int("Passed Pawns") * 256 + 50) ~/ 100;

// mobility table

    for (colour = 0; colour <= 1; colour++)
      MobUnit[colour] = List.filled(PieceNb, 0);

    MobUnit[White][Empty] = MobMove;

    MobUnit[White][BP] = MobAttack;
    MobUnit[White][BN] = MobAttack;
    MobUnit[White][BB] = MobAttack;
    MobUnit[White][BR] = MobAttack;
    MobUnit[White][BQ] = MobAttack;
    MobUnit[White][BK] = MobAttack;

    MobUnit[White][WP] = MobDefense;
    MobUnit[White][WN] = MobDefense;
    MobUnit[White][WB] = MobDefense;
    MobUnit[White][WR] = MobDefense;
    MobUnit[White][WQ] = MobDefense;
    MobUnit[White][WK] = MobDefense;

    MobUnit[Black][Empty] = MobMove;

    MobUnit[Black][WP] = MobAttack;
    MobUnit[Black][WN] = MobAttack;
    MobUnit[Black][WB] = MobAttack;
    MobUnit[Black][WR] = MobAttack;
    MobUnit[Black][WQ] = MobAttack;
    MobUnit[Black][WK] = MobAttack;

    MobUnit[Black][BP] = MobDefense;
    MobUnit[Black][BN] = MobDefense;
    MobUnit[Black][BB] = MobDefense;
    MobUnit[Black][BR] = MobDefense;
    MobUnit[Black][BQ] = MobDefense;
    MobUnit[Black][BK] = MobDefense;

    KingAttackUnit[WN] = 1;
    KingAttackUnit[WB] = 1;
    KingAttackUnit[WR] = 2;
    KingAttackUnit[WQ] = 4;

    KingAttackUnit[BN] = 1;
    KingAttackUnit[BB] = 1;
    KingAttackUnit[BR] = 2;
    KingAttackUnit[BQ] = 4;
  }

  int evalpos(board_t board) {
    opening_t opening = new opening_t(); // int
    endgame_t endgame = new endgame_t(); // int
    material_info_t mat_info = new material_info_t(); // material_info_t[1]
    pawn_info_t pawn_info = new pawn_info_t(); // pawn_info_t[1]
    List<int> mul = [0, 0]; // int[ColourNb]
    int phase; // int
    int eval1; // int
    int wb; // int
    int bb; // int

    //ASSERT(85, board_is_legal(board));
    //ASSERT(86, !board_is_check(board)); // exceptions are extremely rare

// material
    material_get_info(mat_info, board);

    opening.v += mat_info.opening;
    endgame.v += mat_info.endgame;

    mul[White] = mat_info.mul[White];
    mul[Black] = mat_info.mul[Black];

// PST
    opening.v += board.opening;
    endgame.v += board.endgame;

// pawns
    pawn_get_info(pawn_info, board);

    opening.v += pawn_info.opening;
    endgame.v += pawn_info.endgame;

// draw
    eval_draw(board, mat_info, pawn_info, mul);

    if (mat_info.mul[White] < mul[White]) mul[White] = mat_info.mul[White];

    if (mat_info.mul[Black] < mul[Black]) mul[Black] = mat_info.mul[Black];

    if (mul[White] == 0 && mul[Black] == 0) return ValueDraw;

// eval

    eval_piece(board, mat_info, pawn_info, opening, endgame);
    eval_king(board, mat_info, opening, endgame);
    eval_passer(board, pawn_info, opening, endgame);
    eval_pattern(board, opening, endgame);

// phase mix
    phase = mat_info.phase;
    eval1 = ((opening.v * (256 - phase)) + (endgame.v * phase)) ~/ 256;

// drawish bishop endgames
    if ((mat_info.flags & DrawBishopFlag) != 0) {
      wb = board.piece[White][1];
      //ASSERT(87, PIECE_IS_BISHOP(board.square[wb]));

      bb = board.piece[Black][1];
      //ASSERT(88, PIECE_IS_BISHOP(board.square[bb]));

      if (SQUARE_COLOUR(wb) != SQUARE_COLOUR(bb)) {
        if (mul[White] == 16) mul[White] = 8; // 1/2

        if (mul[Black] == 16) mul[Black] = 8; // 1/2
      }
    }

// draw bound

    if (eval1 > ValueDraw) {
      eval1 = (eval1 * mul[White]) ~/ 16;
    } else {
      if (eval1 < ValueDraw) eval1 = (eval1 * mul[Black]) ~/ 16;
    }

// value range

    if (eval1 < -ValueEvalInf) eval1 = -ValueEvalInf;

    if (eval1 > ValueEvalInf) eval1 = ValueEvalInf;

    //ASSERT(89, eval1 >= -ValueEvalInf && eval1 <= ValueEvalInf);

// turn
    if (COLOUR_IS_BLACK(board.turn)) eval1 = -eval1;

    //ASSERT(90, !value_is_mate(eval1));

    return eval1 + (5 - rnd.nextInt(10)); // add some randomness
  }

  eval_draw(board_t board, material_info_t mat_info, pawn_info_t pawn_info,
      List<int> mul) {
    int colour; // int
    int me; // int
    int opp; // int
    int pawn; // int
    int king; // int
    int pawn_file; // int
    int prom; // int
    List<int> list = List.filled(9, 0); // int list[7+1]
    bool ifelse;

// draw patterns
    for (colour = 0; colour <= 1; colour++) {
      me = colour;
      opp = COLOUR_OPP(me);

// KB*P+K* draw

      if ((mat_info.cflags[me] & MatRookPawnFlag) != 0) {
        pawn = pawn_info.single_file[me];

        if (pawn != SquareNone) {
          // all pawns on one file

          pawn_file = SQUARE_FILE(pawn);

          if (pawn_file == FileA || pawn_file == FileH) {
            king = KING_POS(board, opp);
            prom = PAWN_PROMOTE(pawn, me);

            if (DISTANCE(king, prom) <= 1 &&
                (!bishop_can_attack(board, prom, me))) {
              mul[me] = 0;
            }
          }
        }
      }

// K(B)P+K+ draw

      if ((mat_info.cflags[me] & MatBishopFlag) != 0) {
        pawn = pawn_info.single_file[me];

        if (pawn != SquareNone) {
          // all pawns on one file

          king = KING_POS(board, opp);

          if (SQUARE_FILE(king) == SQUARE_FILE(pawn) &&
              PAWN_RANK(king, me) > PAWN_RANK(pawn, me) &&
              (!bishop_can_attack(board, king, me))) {
            mul[me] = 1; // 1/16
          }
        }
      }

// KNPK* draw

      if ((mat_info.cflags[me] & MatKnightFlag) != 0) {
        pawn = board.pawn[me][0];
        king = KING_POS(board, opp);

        if (SQUARE_FILE(king) == SQUARE_FILE(pawn) &&
            PAWN_RANK(king, me) > PAWN_RANK(pawn, me) &&
            PAWN_RANK(pawn, me) <= Rank6) {
          mul[me] = 1; // 1/16
        }
      }
    }

// recognisers, only heuristic draws herenot

    ifelse = true;

    if (ifelse && mat_info.recog == MAT_KPKQ) {
// KPKQ (white)

      draw_init_list(list, board, White);

      if (draw_kpkq(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KQKP) {
// KPKQ (black)

      draw_init_list(list, board, Black);

      if (draw_kpkq(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KPKR) {
// KPKR (white)

      draw_init_list(list, board, White);

      if (draw_kpkr(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KRKP) {
// KPKR (black)

      draw_init_list(list, board, Black);

      if (draw_kpkr(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KPKB) {
// KPKB (white)

      draw_init_list(list, board, White);

      if (draw_kpkb(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KBKP) {
// KPKB (black)

      draw_init_list(list, board, Black);

      if (draw_kpkb(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KPKN) {
// KPKN (white)

      draw_init_list(list, board, White);

      if (draw_kpkn(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KNKP) {
// KPKN (black)

      draw_init_list(list, board, Black);

      if (draw_kpkn(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KNPK) {
// KNPK (white)

      draw_init_list(list, board, White);

      if (draw_knpk(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KKNP) {
// KNPK (black)

      draw_init_list(list, board, Black);

      if (draw_knpk(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KRPKR) {
// KRPKR (white)

      draw_init_list(list, board, White);

      if (draw_krpkr(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KRKRP) {
// KRPKR (black)

      draw_init_list(list, board, Black);

      if (draw_krpkr(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KBPKB) {
// KBPKB (white)

      draw_init_list(list, board, White);

      if (draw_kbpkb(list, board.turn)) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KBKBP) {
// KBPKB (black)

      draw_init_list(list, board, Black);

      if (draw_kbpkb(list, COLOUR_OPP(board.turn))) {
        mul[White] = 1; // 1/16;
        mul[Black] = 1; // 1/16;
      }

      ifelse = false;
    }
  }

  int add_line(board_t board, int me, int from, int dx) {
    int to = from + dx;
    int capture;
    int mob = 0;

    for (;;) {
      capture = board.square[to];
      if (capture != Empty) break;

      mob += MobMove;
      to += dx;
    }

    mob += MobUnit[me][capture];

    return mob;
  }

  eval_piece(board_t board, material_info_t mat_info, pawn_info_t pawn_info,
      opening_t opening, endgame_t endgame) {
    int colour; // int
    List<int> op = [0, 0]; // int[ColourNb]
    List<int> eg = [0, 0]; // int[ColourNb]
    int me; // int
    int opp; // int
    int ptr; // int
    int from; // int
    int piece; // int
    int mob; // int
    List<int> unit = []; // int
    int rook_file; // int
    int king_file; // int
    int king; // int
    int delta; // int
    int ptype;

// eval
    for (colour = 0; colour <= 1; colour++) {
      me = colour;
      opp = COLOUR_OPP(me);

      unit = MobUnit[me];

// piece loop
      ptr = 1; // no king
      for (;;) {
        from = board.piece[me][ptr];
        if (from == SquareNone) break;

        piece = board.square[from];

        ptype = PIECE_TYPE(piece);

        if (ptype == Knight64) {
// mobility

          mob = -KnightUnit;

          mob += unit[board.square[from - 33]];
          mob += unit[board.square[from - 31]];
          mob += unit[board.square[from - 18]];
          mob += unit[board.square[from - 14]];
          mob += unit[board.square[from + 14]];
          mob += unit[board.square[from + 18]];
          mob += unit[board.square[from + 31]];
          mob += unit[board.square[from + 33]];

          op[me] += mob * KnightMobOpening;
          eg[me] += mob * KnightMobEndgame;
        }

        if (ptype == Bishop64) {
// mobility
          mob = -BishopUnit;

          mob += add_line(board, me, from, -17);
          mob += add_line(board, me, from, -15);
          mob += add_line(board, me, from, 15);
          mob += add_line(board, me, from, 17);

          op[me] += mob * BishopMobOpening;
          eg[me] += mob * BishopMobEndgame;
        }

        if (ptype == Rook64) {
// mobility
          mob = -RookUnit;

          mob += add_line(board, me, from, -16);
          mob += add_line(board, me, from, -1);
          mob += add_line(board, me, from, 1);
          mob += add_line(board, me, from, 16);

          op[me] += mob * RookMobOpening;
          eg[me] += mob * RookMobEndgame;

// open file
          if (UseOpenFile) {
            op[me] -= (RookOpenFileOpening ~/ 2);
            eg[me] -= (RookOpenFileEndgame ~/ 2);

            rook_file = SQUARE_FILE(from);

            if (board.pawn_file[me][rook_file] == 0) {
              // no friendly pawn

              op[me] += RookSemiOpenFileOpening;
              eg[me] += RookSemiOpenFileEndgame;

              if (board.pawn_file[opp][rook_file] == 0) {
                // no enemy pawn

                op[me] += RookOpenFileOpening - RookSemiOpenFileOpening;
                eg[me] += RookOpenFileEndgame - RookSemiOpenFileEndgame;
              }

              if ((mat_info.cflags[opp] & MatKingFlag) != 0) {
                king = KING_POS(board, opp);
                king_file = SQUARE_FILE(king);

                delta = (rook_file - king_file).abs(); // file distance

                if (delta <= 1) {
                  op[me] += RookSemiKingFileOpening;
                  if (delta == 0) {
                    op[me] += RookKingFileOpening - RookSemiKingFileOpening;
                  }
                }
              }
            }
          }

// 7th rank

          if (PAWN_RANK(from, me) == Rank7) {
// if opponent pawn on 7th rank+.
            if ((pawn_info.flags[opp] & BackRankFlag) != 0 ||
                PAWN_RANK(KING_POS(board, opp), me) == Rank8) {
              op[me] += Rook7thOpening;
              eg[me] += Rook7thEndgame;
            }
          }
        }

        if (ptype == Queen64) {
// mobility
          mob = -QueenUnit;

          mob += add_line(board, me, from, -17);
          mob += add_line(board, me, from, -16);
          mob += add_line(board, me, from, -15);
          mob += add_line(board, me, from, -1);
          mob += add_line(board, me, from, 1);
          mob += add_line(board, me, from, 15);
          mob += add_line(board, me, from, 16);
          mob += add_line(board, me, from, 17);

          op[me] += mob * QueenMobOpening;
          eg[me] += mob * QueenMobEndgame;

// 7th rank

          if (PAWN_RANK(from, me) == Rank7) {
// if opponent pawn on 7th rank+.
            if ((pawn_info.flags[opp] & BackRankFlag) != 0 ||
                PAWN_RANK(KING_POS(board, opp), me) == Rank8) {
              op[me] += Queen7thOpening;
              eg[me] += Queen7Endgame;
            }
          }
        }

        ptr++;
      }
    }

// update
    opening.v += ((op[White] - op[Black]) * PieceActivityWeight) ~/ 256;
    endgame.v += ((eg[White] - eg[Black]) * PieceActivityWeight) ~/ 256;
  }

  eval_king(board_t board, material_info_t mat_info, opening_t opening,
      endgame_t endgame) {
    int colour; // int
    List<int> op = [0, 0]; // int[ColourNb]
    List<int> eg = [0, 0]; // int[ColourNb]
    int me; // int
    int opp; // int
    int from; // int

    int penalty_1; // int
    int penalty_2; // int

    int tmp; // int
    int penalty; // int

    int king; // int
    int ptr; // int
    int piece; // int
    int attack_tot; // int
    int piece_nb; // int

// king attacks
    if (UseKingAttack) {
      for (colour = 0; colour <= 1; colour++) {
        if ((mat_info.cflags[colour] & MatKingFlag) != 0) {
          me = colour;
          opp = COLOUR_OPP(me);

          king = KING_POS(board, me);

// piece attacks
          attack_tot = 0;
          piece_nb = 0;

          ptr = 1; // no king
          for (;;) {
            from = board.piece[opp][ptr];
            if (from == SquareNone) break;

            piece = board.square[from];

            if (piece_attack_king(board, piece, from, king)) {
              piece_nb++;
              attack_tot += KingAttackUnit[piece];
            }

            ptr++;
          }

// scoring
          //ASSERT(104, piece_nb >= 0 && piece_nb < 16);
          op[colour] -=
              (attack_tot * KingAttackOpening * KingAttackWeight[piece_nb]) ~/
                  256;
        }
      }
    }

// white pawn shelter
    if (UseShelter && (mat_info.cflags[White] & MatKingFlag) != 0) {
      me = White;

// king
      penalty_1 = shelter_square(board, KING_POS(board, me), me);

// castling
      penalty_2 = penalty_1;

      if ((board.flags & FlagsWhiteKingCastle) != 0) {
        tmp = shelter_square(board, G1, me);
        if (tmp < penalty_2) penalty_2 = tmp;
      }

      if ((board.flags & FlagsWhiteQueenCastle) != 0) {
        tmp = shelter_square(board, B1, me);
        if (tmp < penalty_2) penalty_2 = tmp;
      }

      //ASSERT(105, penalty_2 >= 0 && penalty_2 <= penalty_1);

// penalty
      penalty = (penalty_1 + penalty_2) ~/ 2;
      //ASSERT(106, penalty >= 0);

      op[me] -= (penalty * ShelterOpening) ~/ 256;
    }

// black pawn shelter

    if (UseShelter && (mat_info.cflags[Black] & MatKingFlag) != 0) {
      me = Black;

// king
      penalty_1 = shelter_square(board, KING_POS(board, me), me);

// castling
      penalty_2 = penalty_1;

      if ((board.flags & FlagsBlackKingCastle) != 0) {
        tmp = shelter_square(board, G8, me);
        if (tmp < penalty_2) penalty_2 = tmp;
      }

      if ((board.flags & FlagsBlackQueenCastle) != 0) {
        tmp = shelter_square(board, B8, me);
        if (tmp < penalty_2) penalty_2 = tmp;
      }

      //ASSERT(107, penalty_2 >= 0 && penalty_2 <= penalty_1);

// penalty
      penalty = (penalty_1 + penalty_2) ~/ 2;
      //ASSERT(108, penalty >= 0);

      op[me] -= (penalty * ShelterOpening) ~/ 256;
    }

// update
    opening.v += ((op[White] - op[Black]) * KingSafetyWeight) ~/ 256;
    endgame.v += ((eg[White] - eg[Black]) * KingSafetyWeight) ~/ 256;
  }

  eval_passer(board_t board, pawn_info_t pawn_info, opening_t opening,
      endgame_t endgame) {
    int colour; // int
    List<int> op = [0, 0]; // int[ColourNb]
    List<int> eg = [0, 0]; // int[ColourNb]
    int att; // int
    int def; // int
    int bits; // int
    int file; // int
    int rank; // int
    int sq; // int
    int min; // int
    int max; // int
    int delta; // int

// passed pawns

    for (colour = 0; colour <= 1; colour++) {
      att = colour;
      def = COLOUR_OPP(att);
      bits = pawn_info.passed_bits[att];
      for (;;) {
        if (bits == 0) break;

        file = BitFirst[bits];
        //ASSERT(113, file >= FileA && file <= FileH);

        rank = BitLast[board.pawn_file[att][file]];
        //ASSERT(114, rank >= Rank2 && rank <= Rank7);

        sq = SQUARE_MAKE(file, rank);
        if (COLOUR_IS_BLACK(att)) sq = SQUARE_RANK_MIRROR(sq);

        //ASSERT(115, PIECE_IS_PAWN(board.square[sq]));
        //ASSERT(116, COLOUR_IS(board.square[sq], att));

// opening scoring
        op[att] += quad(PassedOpeningMin, PassedOpeningMax, rank);

// endgame scoring init
        min = PassedEndgameMin;
        max = PassedEndgameMax;

        delta = max - min;
        //ASSERT(117, delta > 0);

// "dangerous" bonus

// defender has no piece
        if (board.piece_size[def] <= 1 &&
            (unstoppable_passer(board, sq, att) ||
                king_passer(board, sq, att))) {
          delta += UnstoppablePasser;
        } else {
          if (free_passer(board, sq, att)) {
            delta += FreePasser;
          }
        }

// king-distance bonus
        delta -=
            pawn_att_dist(sq, KING_POS(board, att), att) * AttackerDistance;
        delta +=
            pawn_def_dist(sq, KING_POS(board, def), att) * DefenderDistance;

// endgame scoring
        eg[att] += min;
        if (delta > 0) eg[att] += quad(0, delta, rank);

        bits &= (bits - 1);
      }
    }

// update
    opening.v += ((op[White] - op[Black]) * PassedPawnWeight) ~/ 256;
    endgame.v += ((eg[White] - eg[Black]) * PassedPawnWeight) ~/ 256;
  }

  eval_pattern(board_t board, opening_t opening, endgame_t endgame) {
// trapped bishop (7th rank)
    if ((board.square[A7] == WB && board.square[B6] == BP) ||
        (board.square[B8] == WB && board.square[C7] == BP)) {
      opening.v -= TrappedBishop;
      endgame.v -= TrappedBishop;
    }

    if ((board.square[H7] == WB && board.square[G6] == BP) ||
        (board.square[G8] == WB && board.square[F7] == BP)) {
      opening.v -= TrappedBishop;
      endgame.v -= TrappedBishop;
    }

    if ((board.square[A2] == BB && board.square[B3] == WP) ||
        (board.square[B1] == BB && board.square[C2] == WP)) {
      opening.v += TrappedBishop;
      endgame.v += TrappedBishop;
    }

    if ((board.square[H2] == BB && board.square[G3] == WP) ||
        (board.square[G1] == BB && board.square[F2] == WP)) {
      opening.v += TrappedBishop;
      endgame.v += TrappedBishop;
    }

// trapped bishop (6th rank)
    if (board.square[A6] == WB && board.square[B5] == BP) {
      opening.v -= TrappedBishop ~/ 2;
      endgame.v -= TrappedBishop ~/ 2;
    }

    if (board.square[H6] == WB && board.square[G5] == BP) {
      opening.v -= TrappedBishop ~/ 2;
      endgame.v -= TrappedBishop ~/ 2;
    }

    if (board.square[A3] == BB && board.square[B4] == WP) {
      opening.v += TrappedBishop ~/ 2;
      endgame.v += TrappedBishop ~/ 2;
    }

    if (board.square[H3] == BB && board.square[G4] == WP) {
      opening.v += TrappedBishop ~/ 2;
      endgame.v += TrappedBishop ~/ 2;
    }

// blocked bishop
    if (board.square[D2] == WP &&
        board.square[D3] != Empty &&
        board.square[C1] == WB) opening.v -= BlockedBishop;

    if (board.square[E2] == WP &&
        board.square[E3] != Empty &&
        board.square[F1] == WB) opening.v -= BlockedBishop;

    if (board.square[D7] == BP &&
        board.square[D6] != Empty &&
        board.square[C8] == BB) opening.v += BlockedBishop;

    if (board.square[E7] == BP &&
        board.square[E6] != Empty &&
        board.square[F8] == BB) opening.v += BlockedBishop;

// blocked rook
    if ((board.square[C1] == WK || board.square[B1] == WK) &&
        (board.square[A1] == WR ||
            board.square[A2] == WR ||
            board.square[B1] == WR)) opening.v -= BlockedRook;

    if ((board.square[F1] == WK || board.square[G1] == WK) &&
        (board.square[H1] == WR ||
            board.square[H2] == WR ||
            board.square[G1] == WR)) opening.v -= BlockedRook;

    if ((board.square[C8] == BK || board.square[B8] == BK) &&
        (board.square[A8] == BR ||
            board.square[A7] == BR ||
            board.square[B8] == BR)) opening.v += BlockedRook;

    if ((board.square[F8] == BK || board.square[G8] == BK) &&
        (board.square[H8] == BR ||
            board.square[H7] == BR ||
            board.square[G8] == BR)) opening.v += BlockedRook;
  }

  unstoppable_passer(board_t board, int pawn, int colour) {
    int me; // int
    int opp; // int
    int file; // int
    int rank; // int
    int king; // int
    int prom; // int
    int ptr; // int
    int sq; // int
    int dist; // int

    //ASSERT(122, SQUARE_IS_OK(pawn));
    //ASSERT(123, COLOUR_IS_OK(colour));

    me = colour;
    opp = COLOUR_OPP(me);

    file = SQUARE_FILE(pawn);
    rank = PAWN_RANK(pawn, me);

    king = KING_POS(board, opp);

// clear promotion path?
    ptr = 0;
    for (;;) {
      sq = board.piece[me][ptr];
      if (sq == SquareNone) break;

      if (SQUARE_FILE(sq) == file && PAWN_RANK(sq, me) > rank) {
        return false; // "friendly" blocker
      }
      ptr++;
    }

// init
    if (rank == Rank2) {
      pawn += PawnMoveInc[me];
      rank++;
      //ASSERT(124, rank == PAWN_RANK(pawn, me));
    }

    //ASSERT(125, rank >= Rank3 && rank <= Rank7);

    prom = PAWN_PROMOTE(pawn, me);

    dist = DISTANCE(pawn, prom);
    //ASSERT(126, dist == Rank8 - rank);
    if (board.turn == opp) dist++;

    if (DISTANCE(king, prom) > dist) return true; // not in the square

    return false;
  }

  bool king_passer(board_t board, int pawn, int colour) {
    int me; // int
    int king; // int
    int file; // int
    int prom; // int

    //ASSERT(128, SQUARE_IS_OK(pawn));
    //ASSERT(129, COLOUR_IS_OK(colour));
    me = colour;

    king = KING_POS(board, me);
    file = SQUARE_FILE(pawn);
    prom = PAWN_PROMOTE(pawn, me);

    if (DISTANCE(king, prom) <= 1 &&
        DISTANCE(king, pawn) <= 1 &&
        (SQUARE_FILE(king) != file || (file != FileA && file != FileH))) {
      return true;
    }

    return false;
  }

  bool free_passer(board_t board, int pawn, int colour) {
    int me; // int
    int inc; // int
    int sq; // int
    int move; // int

    //ASSERT(131, SQUARE_IS_OK(pawn));
    //ASSERT(132, COLOUR_IS_OK(colour));
    me = colour;

    inc = PawnMoveInc[me];
    sq = pawn + inc;
    //ASSERT(133, SQUARE_IS_OK(sq));

    if (board.square[sq] != Empty) return false;

    move = MOVE_MAKE(pawn, sq);
    if (see_move(move, board) < 0) return false;

    return true;
  }

  int pawn_att_dist(int pawn, int king, int colour) {
    int me; // int
    int inc; // int
    int target; // int

    //ASSERT(134, SQUARE_IS_OK(pawn));
    //ASSERT(135, SQUARE_IS_OK(king));
    //ASSERT(136, COLOUR_IS_OK(colour));
    me = colour;
    inc = PawnMoveInc[me];

    target = pawn + inc;

    return DISTANCE(king, target);
  }

  int pawn_def_dist(int pawn, int king, int colour) {
    int me; // int
    int inc; // int
    int target; // int

    //ASSERT(137, SQUARE_IS_OK(pawn));
    //ASSERT(138, SQUARE_IS_OK(king));
    //ASSERT(139, COLOUR_IS_OK(colour));
    me = colour;
    inc = PawnMoveInc[me];

    target = pawn + inc;

    return DISTANCE(king, target);
  }

  draw_init_list(List<int> list, board_t board, int pawn_colour) {
    int pos; // int
    int att; // int
    int def; // int
    int ptr; // int
    int sq; // int
    int pawn; // int
    int i; // int

    //ASSERT(142, COLOUR_IS_OK(pawn_colour));

// init
    pos = 0;
    att = pawn_colour;
    def = COLOUR_OPP(att);

    //ASSERT(143, board.pawn_size[att] == 1);
    //ASSERT(144, board.pawn_size[def] == 0);

// att
    ptr = 0;
    for (;;) {
      sq = board.piece[att][ptr];
      if (sq == SquareNone) break;
      list[pos] = sq;
      pos++;
      ptr++;
    }

    ptr = 0;
    for (;;) {
      sq = board.pawn[att][ptr];
      if (sq == SquareNone) break;
      list[pos] = sq;
      pos++;
      ptr++;
    }

// def
    ptr = 0;
    for (;;) {
      sq = board.piece[def][ptr];
      if (sq == SquareNone) break;
      list[pos] = sq;
      pos++;
      ptr++;
    }

    ptr = 0;
    for (;;) {
      sq = board.pawn[def][ptr];
      if (sq == SquareNone) break;
      list[pos] = sq;
      pos++;
      ptr++;
    }

    //ASSERT(145, pos == board.piece_nb);

    list[pos] = SquareNone;

// file flip?
    pawn = board.pawn[att][0];

    if (SQUARE_FILE(pawn) >= FileE) {
      for (i = 0; i < pos; i++) {
        list[i] = SQUARE_FILE_MIRROR(list[i]);
      }
    }

// rank flip?
    if (COLOUR_IS_BLACK(pawn_colour)) {
      for (i = 0; i < pos; i++) {
        list[i] = SQUARE_RANK_MIRROR(list[i]);
      }
    }
  }

  draw_kpkq(List<int> list, int turn) {
    int wk; // int
    int wp; // int
    int bk; // int
    int bq; // int
    int prom; // int
    int dist; // int
    bool ifelse;

    //ASSERT(147, COLOUR_IS_OK(turn));

// load
    wk = list[0];
    //ASSERT(148, SQUARE_IS_OK(wk));
    wp = list[1];
    //ASSERT(149, SQUARE_IS_OK(wp));
    //ASSERT(150, SQUARE_FILE(wp) <= FileD);
    bk = list[2];
    //ASSERT(151, SQUARE_IS_OK(bk));
    bq = list[3];
    //ASSERT(152, SQUARE_IS_OK(bq));
    //ASSERT(153, list[4] == SquareNone);

// test
    if (wp == A7) {
      prom = A8;
      dist = 4;

      if (wk == B7 || wk == B8) {
        // best case
        if (COLOUR_IS_WHITE(turn)) dist--;
      } else {
        if (wk == A8 || ((wk == C7 || wk == C8) && bq != A8)) {
          // white loses a tempo
          if (COLOUR_IS_BLACK(turn) && SQUARE_FILE(bq) != FileB) return false;
        } else {
          return false;
        }
      }

      //ASSERT(154, bq != prom);
      if (DISTANCE(bk, prom) > dist) return true;
    } else {
      if (wp == C7) {
        prom = C8;
        dist = 4;

        ifelse = true;
        if (ifelse && wk == C8) {
          // dist = 0

          dist++; // self-blocking penalty
          if (COLOUR_IS_WHITE(turn)) dist--; // right-to-move bonus

          ifelse = false;
        }
        if (ifelse && (wk == B7 || wk == B8)) {
          // dist = 1, right side

          dist--; // right-side bonus
          if (DELTA_INC_LINE(wp - bq) == wk - wp) dist++; // pinned-pawn penalty

          if (COLOUR_IS_WHITE(turn)) dist--; // right-to-move bonus

          ifelse = false;
        }

        if (ifelse && (wk == D7 || wk == D8)) {
          // dist = 1, wrong side

          if (DELTA_INC_LINE(wp - bq) == wk - wp) dist++; // pinned-pawn penalty

          if (COLOUR_IS_WHITE(turn)) dist--; // right-to-move bonus

          ifelse = false;
        }

        if (ifelse && ((wk == A7 || wk == A8) && bq != C8)) {
          // dist = 2, right side

          if (COLOUR_IS_BLACK(turn) && SQUARE_FILE(bq) != FileB) return false;

          dist--; // right-side bonus

          ifelse = false;
        }

        if (ifelse && ((wk == E7 || wk == E8) && bq != C8)) {
          // dist = 2, wrong side

          if (COLOUR_IS_BLACK(turn) && SQUARE_FILE(bq) != FileD) return false;

          ifelse = false;
        }
        if (ifelse) return false;

        //ASSERT(155, bq != prom);
        if (DISTANCE(bk, prom) > dist) return true;
      }
    }

    return false;
  }

  bool draw_kpkr(List<int> list, int turn) {
    int wk; // int
    int wp; // int
    int bk; // int
    int br; // int
    int inc; // int
    int prom; // int
    int dist; // int
    int wk_file; // int
    int wk_rank; // int
    int wp_file; // int
    int wp_rank; // int
    int br_file; // int
    int br_rank; // int

    //ASSERT(157, COLOUR_IS_OK(turn));

// load
    wk = list[0];
    //ASSERT(158, SQUARE_IS_OK(wk));
    wp = list[1];
    //ASSERT(159, SQUARE_IS_OK(wp));
    //ASSERT(160, SQUARE_FILE(wp) <= FileD);
    bk = list[2];
    //ASSERT(161, SQUARE_IS_OK(bk));
    br = list[3];
    //ASSERT(162, SQUARE_IS_OK(br));
    //ASSERT(163, list[4] == SquareNone);

// init
    wk_file = SQUARE_FILE(wk);
    wk_rank = SQUARE_RANK(wk);

    wp_file = SQUARE_FILE(wp);
    wp_rank = SQUARE_RANK(wp);

    br_file = SQUARE_FILE(br);
    br_rank = SQUARE_RANK(br);

    inc = PawnMoveInc[White];
    prom = PAWN_PROMOTE(wp, White);

// conditions

    if (DISTANCE(wk, wp) == 1) {
      //ASSERT(164, (wk_file - wp_file).abs() <= 1);
      //ASSERT(165, (wk_rank - wp_rank).abs() <= 1);

// no-op
    } else {
      if (DISTANCE(wk, wp) == 2 && (wk_rank - wp_rank).abs() <= 1) {
        //ASSERT(166, (wk_file - wp_file).abs() == 2);
        //ASSERT(167, (wk_rank - wp_rank).abs() <= 1);

        if (COLOUR_IS_BLACK(turn) && (br_file * 2) != (wk_file + wp_file))
          return false;
      } else {
        return false;
      }
    }

// white features
    dist = DISTANCE(wk, prom) + DISTANCE(wp, prom);
    if (wk == prom) dist++;

    if (wk == wp + inc) {
      // king on pawn's "front square"
      if (wp_file == FileA) return false;

      dist++; // self-blocking penalty
    }

// black features
    if (br_file != wp_file && br_rank != Rank8) dist--; // misplaced-rook bonus

// test
    if (COLOUR_IS_WHITE(turn)) dist--; // right-to-move bonus

    if (DISTANCE(bk, prom) > dist) return true;

    return false;
  }

  bool draw_kpkb(List<int> list, int turn) {
    int wp; // int
    int bk; // int
    int bb; // int
    int inc; // int
    int en2; // int
    int to; // int
    int delta; // int
    int inc_2; // int
    int sq; // int

    //ASSERT(169, COLOUR_IS_OK(turn));

    //int wk = list[0];
// load
    //ASSERT(170, SQUARE_IS_OK(wk));
    wp = list[1];
    //ASSERT(171, SQUARE_IS_OK(wp));
    //ASSERT(172, SQUARE_FILE(wp) <= FileD);
    bk = list[2];
    //ASSERT(173, SQUARE_IS_OK(bk));
    bb = list[3];
    //ASSERT(174, SQUARE_IS_OK(bb));
    //ASSERT(175, list[4] == SquareNone);

// blocked pawn?
    inc = PawnMoveInc[White];
    en2 = PAWN_PROMOTE(wp, White) + inc;

    to = wp + inc;
    while (to != en2) {
      //ASSERT(176, SQUARE_IS_OK(to));

      if (to == bb) return true; // direct blockade

      delta = to - bb;
      //ASSERT(177, delta_is_ok(delta));

      if (PSEUDO_ATTACK(BB, delta)) {
        inc_2 = DELTA_INC_ALL(delta);
        //ASSERT(178, inc_2 != IncNone);

        sq = bb;
        for (;;) {
          sq += inc_2;
          //ASSERT(179, SQUARE_IS_OK(sq));
          //ASSERT(180, sq != wk);
          //ASSERT(181, sq != wp);
          //ASSERT(182, sq != bb);
          if (sq == to) return true; // indirect blockade
          if (sq == bk) break;
        }
      }
      to += inc;
    }

    return false;
  }

  bool draw_kpkn(List<int> list, int turn) {
    int inc; // int
    int en2; // int
    int file; // int
    int sq; // int

    //ASSERT(184, COLOUR_IS_OK(turn));

// load
    //int wk = list[0];
    //ASSERT(185, SQUARE_IS_OK(wk));
    int wp = list[1];
    //ASSERT(186, SQUARE_IS_OK(wp));
    //ASSERT(187, SQUARE_FILE(wp) <= FileD);
    //int bk = list[2];
    //ASSERT(188, SQUARE_IS_OK(bk));
    int bn = list[3];
    //ASSERT(189, SQUARE_IS_OK(bn));
    //ASSERT(190, list[4] == SquareNone);

// blocked pawn?

    inc = PawnMoveInc[White];
    en2 = PAWN_PROMOTE(wp, White) + inc;

    file = SQUARE_FILE(wp);
    if (file == FileA || file == FileH) en2 -= inc;

    sq = wp + inc;
    while (sq != en2) {
      //ASSERT(191, SQUARE_IS_OK(sq));

      if (sq == bn || PSEUDO_ATTACK(BN, sq - bn)) {
        return true; // blockade
      }

      sq += inc;
    }

    return false;
  }

  bool draw_knpk(List<int> list, int turn) {
    int wp; // int
    int bk; // int

    //ASSERT(193, COLOUR_IS_OK(turn));

// load
    //int wk = list[0];
    //ASSERT(194, SQUARE_IS_OK(wk));
    //int wn = list[1];
    //ASSERT(195, SQUARE_IS_OK(wn));
    wp = list[2];
    //ASSERT(196, SQUARE_IS_OK(wp));
    //ASSERT(197, SQUARE_FILE(wp) <= FileD);
    bk = list[3];
    //ASSERT(198, SQUARE_IS_OK(bk));
    //ASSERT(199, list[4] == SquareNone);

// test

    if (wp == A7 && DISTANCE(bk, A8) <= 1) return true;

    return false;
  }

  bool draw_krpkr(List<int> list, int turn) {
    int wk; // int
    int wr; // int
    int wp; // int
    int bk; // int
    int br; // int

    int wp_file; // int
    int wp_rank; // int
    int bk_file; // int
    int bk_rank; // int
    int br_file; // int
    int br_rank; // int

    int prom; // int

    //ASSERT(201, COLOUR_IS_OK(turn));

// load
    wk = list[0];
    //ASSERT(202, SQUARE_IS_OK(wk));
    wr = list[1];
    //ASSERT(203, SQUARE_IS_OK(wr));
    wp = list[2];
    //ASSERT(204, SQUARE_IS_OK(wp));
    //ASSERT(205, SQUARE_FILE(wp) <= FileD);
    bk = list[3];
    //ASSERT(206, SQUARE_IS_OK(bk));
    br = list[4];
    //ASSERT(207, SQUARE_IS_OK(br));
    //ASSERT(208, list[5] == SquareNone);

// test
    wp_file = SQUARE_FILE(wp);
    wp_rank = SQUARE_RANK(wp);

    bk_file = SQUARE_FILE(bk);
    bk_rank = SQUARE_RANK(bk);

    br_file = SQUARE_FILE(br);
    br_rank = SQUARE_RANK(br);

    prom = PAWN_PROMOTE(wp, White);

    if (bk == prom) {
      if (br_file > wp_file) return true;
    } else {
      if (bk_file == wp_file && bk_rank > wp_rank)
        return true;
      else {
        if (wr == prom &&
            wp_rank == Rank7 &&
            (bk == G7 || bk == H7) &&
            br_file == wp_file) {
          if (br_rank <= Rank3) {
            if (DISTANCE(wk, wp) > 1) return true;
          } else {
            // br_rank >= Rank4
            if (DISTANCE(wk, wp) > 2) return true;
          }
        }
      }
    }

    return false;
  }

  bool draw_kbpkb(List<int> list, int turn) {
    int wb; // int
    int wp; // int
    int bk; // int
    int bb; // int

    int inc; // int
    int en2; // int
    int to; // int
    int delta; // int
    int inc_2; // int
    int sq; // int

    //ASSERT(210, COLOUR_IS_OK(turn));

// load
    //int wk = list[0];
    //ASSERT(211, SQUARE_IS_OK(wk));
    wb = list[1];
    //ASSERT(212, SQUARE_IS_OK(wb));
    wp = list[2];
    //ASSERT(213, SQUARE_IS_OK(wp));
    //ASSERT(214, SQUARE_FILE(wp) <= FileD);
    bk = list[3];
    //ASSERT(215, SQUARE_IS_OK(bk));
    bb = list[4];
    //ASSERT(216, SQUARE_IS_OK(bb));
    //ASSERT(217, list[5] == SquareNone);

// opposit colour?
    if (SQUARE_COLOUR(wb) == SQUARE_COLOUR(bb)) return false;

// blocked pawn?
    inc = PawnMoveInc[White];
    en2 = PAWN_PROMOTE(wp, White) + inc;

    to = wp + inc;
    while (to != en2) {
      //ASSERT(218, SQUARE_IS_OK(to));

      if (to == bb) return true; // direct blockade

      delta = to - bb;
      //ASSERT(219, delta_is_ok(delta));

      if (PSEUDO_ATTACK(BB, delta)) {
        inc_2 = DELTA_INC_ALL(delta);
        //ASSERT(220, inc_2 != IncNone);

        sq = bb;
        for (;;) {
          sq += inc_2;
          //ASSERT(221, SQUARE_IS_OK(sq));
          //ASSERT(222, sq != wk);
          //ASSERT(223, sq != wb);
          //ASSERT(224, sq != wp);
          //ASSERT(225, sq != bb);
          if (sq == to) return true; // indirect blockade

          if (sq == bk) break;
        }
      }
      to += inc;
    }

    return false;
  }

  int shelter_square(board_t board, int square, int colour) {
    int penalty; // int
    int file; // int
    int rank; // int

    //ASSERT(227, SQUARE_IS_OK(square));
    //ASSERT(228, COLOUR_IS_OK(colour));

    penalty = 0;

    file = SQUARE_FILE(square);
    rank = PAWN_RANK(square, colour);

    penalty += shelter_file(board, file, rank, colour) * 2;
    if (file != FileA) penalty += shelter_file(board, file - 1, rank, colour);

    if (file != FileH) penalty += shelter_file(board, file + 1, rank, colour);

    if (penalty == 0) penalty = 11; // weak back rank

    if (UseStorm) {
      penalty += storm_file(board, file, colour);
      if (file != FileA) penalty += storm_file(board, file - 1, colour);

      if (file != FileH) penalty += storm_file(board, file + 1, colour);
    }

    return penalty;
  }

  int shelter_file(board_t board, int file, int rank, int colour) {
    int dist; // int
    int penalty; // int

    //ASSERT(230, file >= FileA && file <= FileH);
    //ASSERT(231, rank >= Rank1 && rank <= Rank8);
    //ASSERT(232, COLOUR_IS_OK(colour));

    dist = BitFirst[(board.pawn_file[colour][file] & BitGE[rank])];
    //ASSERT(233, dist >= Rank2 && dist <= Rank8);

    dist = Rank8 - dist;
    //ASSERT(234, dist >= 0 && dist <= 6);

    penalty = 36 - (dist * dist);
    //ASSERT(235, penalty >= 0 && penalty <= 36);

    return penalty;
  }

  int storm_file(board_t board, int file, int colour) {
    int dist; // int
    int penalty; // int

    //ASSERT(237, file >= FileA && file <= FileH);
    //ASSERT(238, COLOUR_IS_OK(colour));

    dist = BitLast[board.pawn_file[COLOUR_OPP(colour)][file]];
    //ASSERT(239, dist >= Rank1 && dist <= Rank7);

    penalty = 0;

    if (dist == Rank4)
      penalty = StormOpening;
    else {
      if (dist == Rank5)
        penalty = StormOpening * 3;
      else {
        if (dist == Rank6) penalty = StormOpening * 6;
      }
    }

    return penalty;
  }

  bool bishop_can_attack(board_t board, int to, int colour) {
    int ptr; // int
    int from; // int
    int piece; // int

    //ASSERT(241, SQUARE_IS_OK(to));
    //ASSERT(242, COLOUR_IS_OK(colour));

    ptr = 1; // no king
    for (;;) {
      from = board.piece[colour][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      if (PIECE_IS_BISHOP(piece) && SQUARE_COLOUR(from) == SQUARE_COLOUR(to))
        return true;

      ptr++;
    }

    return false;
  }

  random_init() {
    for (int i = 0; i < RandomNb; i++) {
      Random64[i] = ((random_32bit() << 32) | random_32bit());
    }
  }

  hash_init() {
    for (int i = 0; i < 16; i++) {
      Castle64[i] = hash_castle_key(i); // not used later
    }
  }

  int hash_key(board_t board) {
    // uint64
    int key = 0; // uint64;
    int colour; // int
    int ptr; // int
    int sq; // int
    int piece; // int

// pieces
    for (colour = 0; colour <= 1; colour++) {
      ptr = 0;
      for (;;) {
        sq = board.piece[colour][ptr];
        if (sq == SquareNone) break;

        piece = board.square[sq];
        key ^= hash_piece_key(piece, sq);

        ptr++;
      }

      ptr = 0;
      for (;;) {
        sq = board.pawn[colour][ptr];
        if (sq == SquareNone) break;

        piece = board.square[sq];
        key ^= hash_piece_key(piece, sq);

        ptr++;
      }
    }

// castle flags
    key ^= hash_castle_key(board.flags);

// en-passant square
    sq = board.ep_square;
    if (sq != SquareNone) key ^= hash_ep_key(sq);

// turn
    key ^= hash_turn_key(board.turn);

    return key;
  }

  int hash_pawn_key(board_t board) {
    // uint64

    int key = 0; // uint64;
    int colour; // int
    int ptr; // int
    int sq; // int
    int piece; // int

// pawns
    for (colour = 0; colour <= 1; colour++) {
      ptr = 0;
      for (;;) {
        sq = board.pawn[colour][ptr];
        if (sq == SquareNone) break;

        piece = board.square[sq];
        key ^= hash_piece_key(piece, sq);

        ptr++;
      }
    }

    return key;
  }

  int hash_material_key(board_t board) {
    // uint64

    int key = 0; // uint64;
    int piece1; // int
    int count; // int

// counters
    for (piece1 = 0; piece1 <= 11; piece1++) {
      count = board.number[piece1];
      key ^= hash_counter_key(piece1, count);
    }

    return key;
  }

  int hash_piece_key(int piece, int square) {
    // uint64

    //ASSERT(253, piece_is_ok(piece));
    //ASSERT(254, SQUARE_IS_OK(square));
    return Random64[
        RandomPiece + ((PieceTo12[piece] ^ 1) << 6) + SquareTo64[square]];
// xor 1 for PolyGlot book
  }

  int hash_castle_key(flags) {
    // uint64

    int key = 0; // uint64;
    int i; // int

    //ASSERT(255, (flags & bnotxF) == 0);
    for (i = 0; i <= 3; i++) {
      if ((flags & (1 << i)) != 0) {
        key ^= Random64[RandomCastle + i];
      }
    }

    return key;
  }

  int hash_ep_key(int square) {
    // uint64

    //ASSERT(256, SQUARE_IS_OK(square));

    return Random64[RandomEnPassant + SQUARE_FILE(square) - FileA];
  }

  hash_turn_key(int colour) {
    // uint64

    //ASSERT(257, COLOUR_IS_OK(colour));
    return (COLOUR_IS_WHITE(colour) ? Random64[RandomTurn] : 0);
  }

  int hash_counter_key(int piece_12, int count) {
    // uint64

    int key = 0; // uint64;
    int i; // int
    int index; // int

    //ASSERT(258, piece_12 >= 0 && piece_12 < 12);
    //ASSERT(259, count >= 0 && count <= 10);

// counter
    index = piece_12 << 4;
    for (i = 0; i < count; i++) key ^= Random64[index + i];

    return key;
  }

  bool list_is_ok(list_t list) {
    if (list.size < 0 || list.size >= ListSize) return false;

    return true;
  }

  list_remove(list_t list, int pos) {
    int i; // int

    //ASSERT(260, list_is_ok(list));
    //ASSERT(261, pos >= 0 && pos < list.size);
    for (i = pos; i <= list.size - 2; i++) {
      list.move[i] = list.move[i + 1];
      list.value[i] = list.value[i + 1];
    }

    list.size--;
  }

  list_copy(list_t dst, list_t src) {
    int i; // int

    //ASSERT(263, list_is_ok(src));

    dst.size = src.size;

    for (i = 0; i < src.size; i++) {
      dst.move[i] = src.move[i];
      dst.value[i] = src.value[i];
    }
  }

  list_sort(list_t list) {
    int size; // int
    int i; // int
    int j; // int
    int move; // int
    int value; // int

// init
    size = list.size;
    list.value[size] = -32768; // sentinel

// insert sort (stable)
    for (i = size - 2; i >= 0; i--) {
      move = list.move[i];
      value = list.value[i];

      j = i;
      while (value < list.value[j + 1]) {
        list.move[j] = list.move[j + 1];
        list.value[j] = list.value[j + 1];
        j++;
      }

      //ASSERT(265, j < size);
      list.move[j] = move;
      list.value[j] = value;
    }
  }

  bool list_contain(list_t list, int move) {
    int i; // int

    //ASSERT(267, list_is_ok(list));
    //ASSERT(268, move_is_ok(move));
    for (i = 0; i < list.size; i++) {
      if (list.move[i] == move) return true;
    }

    return false;
  }

  list_note(list_t list) {
    int i; // int
    int move; // int

    //ASSERT(269, list_is_ok(list));

    for (i = 0; i < list.size; i++) {
      move = list.move[i];
      //ASSERT(270, move_is_ok(move));
      list.value[i] = -move_order(move);
    }
  }

  list_filter(list_t list, board_t board, keep) {
    int pos = 0; // int
    int i; // int
    int move; // int
    int value; // int

    for (i = 0; i < list.size; i++) {
      //ASSERT(275, pos >= 0 && pos <= i);

      move = list.move[i];
      value = list.value[i];

      if (pseudo_is_legal(move, board) == keep) {
        list.move[pos] = move;
        list.value[pos] = value;
        pos++;
      }
    }

    //ASSERT(276, pos >= 0 && pos <= list.size);
    list.size = pos;

    //ASSERT(277, list_is_ok(list));
  }

  material_init() {
// UCI options
    MaterialWeight = (option_get_int("Material") * 256 + 50) ~/ 100;

// material table
    Material.size = 0;
    Material.mask = 0;
  }

  material_alloc() {
    if (UseTable) {
      Material.size = MaterialTableSize;
      Material.mask = Material.size - 1; // 2^x -1
// Material.table = (entry_t *) my_malloc(Material.size*sizeof(entry_t));

      material_clear();
    }
  }

  material_clear() {
    Material.table = [];
    for (int i = 0; i < Material.size; i++)
      Material.table.add(new material_info_t());

    Material.used = 0;
    Material.read_nb = 0;
    Material.read_hit = 0;
    Material.write_nb = 0;
    Material.write_collision = 0;
  }

  material_get_info(material_info_t info, board_t board) {
    int key = 0; // uint64
    late material_info_t entry;
    int index;

// probe
    if (UseTable) {
      Material.read_nb++;

      key = board.material_key;
      index = (KEY_INDEX(key) & Material.mask);

      entry = Material.table[index];

      if (entry.lock == KEY_LOCK(key)) {
        // found
        Material.read_hit++;

        material_info_copy(info, entry);

        return;
      }
    }

// calculation
    material_comp_info(info, board);

// store
    if (UseTable) {
      Material.write_nb++;

      if (entry.lock == 0) {
        // assume free entry
        Material.used++;
      } else {
        Material.write_collision++;
      }

      material_info_copy(entry, info);

      entry.lock = KEY_LOCK(key);
    }
  }

  material_comp_info(material_info_t info, board_t board) {
    int colour; // int
    int recog; // int
    int flags; // int
    List<int> cflags = [0, 0]; // int[ColourNb]
    List<int> mul = [16, 16]; // int[ColourNb]
    int phase; // int
    int opening; // int
    int endgame; // int
    bool ifelse;

// init
    int wp = board.number[WhitePawn12];
    int wn = board.number[WhiteKnight12];
    int wb = board.number[WhiteBishop12];
    int wr = board.number[WhiteRook12];
    int wq = board.number[WhiteQueen12];

    int bp = board.number[BlackPawn12];
    int bn = board.number[BlackKnight12];
    int bb = board.number[BlackBishop12];
    int br = board.number[BlackRook12];
    int bq = board.number[BlackQueen12];

    int wt = wq + wr + wb + wn + wp; // no king
    int bt = bq + br + bb + bn + bp; // no king

    int wm = wb + wn;
    int bm = bb + bn;

    int w_maj = wq * 2 + wr; // int
    int w_min = wb + wn; // int
    int w_tot = w_maj * 2 + w_min; // int

    int b_maj = bq * 2 + br; // int
    int b_min = bb + bn; // int
    int b_tot = b_maj * 2 + b_min; // int

// recogniser
    recog = MAT_NONE;

    ifelse = true;

    if (ifelse && (wt == 0 && bt == 0)) {
      recog = MAT_KK;

      ifelse = false;
    }

    if (ifelse && (wt == 1 && bt == 0)) {
      if (wb == 1) recog = MAT_KBK;
      if (wn == 1) recog = MAT_KNK;
      if (wp == 1) recog = MAT_KPK;

      ifelse = false;
    }

    if (ifelse && (wt == 0 && bt == 1)) {
      if (bb == 1) recog = MAT_KKB;
      if (bn == 1) recog = MAT_KKN;
      if (bp == 1) recog = MAT_KKP;

      ifelse = false;
    }

    if (ifelse && (wt == 1 && bt == 1)) {
      if (wq == 1 && bq == 1) recog = MAT_KQKQ;
      if (wq == 1 && bp == 1) recog = MAT_KQKP;
      if (wp == 1 && bq == 1) recog = MAT_KPKQ;
      if (wr == 1 && br == 1) recog = MAT_KRKR;
      if (wr == 1 && bp == 1) recog = MAT_KRKP;
      if (wp == 1 && br == 1) recog = MAT_KPKR;
      if (wb == 1 && bb == 1) recog = MAT_KBKB;
      if (wb == 1 && bp == 1) recog = MAT_KBKP;
      if (wp == 1 && bb == 1) recog = MAT_KPKB;
      if (wn == 1 && bn == 1) recog = MAT_KNKN;
      if (wn == 1 && bp == 1) recog = MAT_KNKP;
      if (wp == 1 && bn == 1) recog = MAT_KPKN;

      ifelse = false;
    }

    if (ifelse && (wt == 2 && bt == 0)) {
      if (wb == 1 && wp == 1) recog = MAT_KBPK;
      if (wn == 1 && wp == 1) recog = MAT_KNPK;

      ifelse = false;
    }

    if (ifelse && (wt == 0 && bt == 2)) {
      if (bb == 1 && bp == 1) recog = MAT_KKBP;
      if (bn == 1 && bp == 1) recog = MAT_KKNP;

      ifelse = false;
    }

    if (ifelse && (wt == 2 && bt == 1)) {
      if (wr == 1 && wp == 1 && br == 1) recog = MAT_KRPKR;
      if (wb == 1 && wp == 1 && bb == 1) recog = MAT_KBPKB;

      ifelse = false;
    }

    if (ifelse && (wt == 1 && bt == 2)) {
      if (wr == 1 && br == 1 && bp == 1) recog = MAT_KRKRP;
      if (wb == 1 && bb == 1 && bp == 1) recog = MAT_KBKBP;

      ifelse = false;
    }

// draw node (exact-draw recogniser)
    flags = 0;

// if no major piece || pawn
    if (wq + wr + wp == 0 && bq + br + bp == 0) {
// at most one minor => KK, KBK || KNK
      if (wm + bm <= 1 || recog == MAT_KBKB) flags |= DrawNodeFlag;
    } else {
      if (recog == MAT_KPK ||
          recog == MAT_KKP ||
          recog == MAT_KBPK ||
          recog == MAT_KKBP) flags |= DrawNodeFlag;
    }

// bishop endgame
// if only bishops
    if (wq + wr + wn == 0 && bq + br + bn == 0) {
      if (wb == 1 && bb == 1) {
        if (wp - bp >= -2 && wp - bp <= 2) {
          // pawn diff <= 2
          flags |= DrawBishopFlag;
        }
      }
    }

// white multiplier
    if (wp == 0) {
      // white has no pawns

      ifelse = true;
      if (ifelse && (w_tot == 1)) {
        //ASSERT(283, w_maj == 0);
        //ASSERT(284, w_min == 1);

// KBK* || KNK*, always insufficient
        mul[White] = 0;

        ifelse = false;
      }

      if (ifelse && (w_tot == 2 && wn == 2)) {
        //ASSERT(285, w_maj == 0);
        //ASSERT(286, w_min == 2);

// KNNK*, usually insufficient
        if (b_tot != 0 || bp == 0)
          mul[White] = 0;
        else {
          // KNNKP+, might not be draw
          mul[White] = 1; // 1/16
        }

        ifelse = false;
      }

      if (ifelse && (w_tot == 2 && wb == 2 && b_tot == 1 && bn == 1)) {
        //ASSERT(287, w_maj == 0);
        //ASSERT(288, w_min == 2);
        //ASSERT(289, b_maj == 0);
        //ASSERT(290, b_min == 1);

// KBBKN*, barely drawish (not at all?)
        mul[White] = 8; // 1/2

        ifelse = false;
      }

      if (ifelse && (w_tot - b_tot <= 1 && w_maj <= 2)) {
// no more than 1 minor up, drawish

        mul[White] = 2; // 1/8
        ifelse = false;
      }
    } else {
      if (wp == 1) {
        // white has one pawn

        if (b_min != 0) {
// assume black sacrifices a minor against the lone pawn

          b_min--;
          b_tot++;

          ifelse = true;
          if (ifelse && (w_tot == 1)) {
            //ASSERT(291, w_maj == 0);
            //ASSERT(292, w_min == 1);

// KBK* || KNK*, always insufficient
            mul[White] = 4; // 1/4

            ifelse = false;
          }

          if (ifelse && (w_tot == 2 && wn == 2)) {
            //ASSERT(293, w_maj == 0);
            //ASSERT(294, w_min == 2);

// KNNK*, usually insufficient
            mul[White] = 4; // 1/4

            ifelse = false;
          }

          if (ifelse && (w_tot - b_tot <= 1 && w_maj <= 2)) {
// no more than 1 minor up, drawish

            mul[White] = 8; // 1/2

            ifelse = false;
          }
        } else {
          if (br != 0) {
// assume black sacrifices a rook against the lone pawn

            b_maj--;
            b_tot -= 2;

            ifelse = true;
            if (ifelse && (w_tot == 1)) {
              //ASSERT(295, w_maj == 0);
              //ASSERT(296, w_min == 1);

// KBK* || KNK*, always insufficient
              mul[White] = 4; // 1/4

              ifelse = false;
            }

            if (ifelse && (w_tot == 2 && wn == 2)) {
              //ASSERT(297, w_maj == 0);
              //ASSERT(298, w_min == 2);

// KNNK*, usually insufficient
              mul[White] = 4; // 1/4

              ifelse = false;
            }

            if (ifelse && (w_tot - b_tot <= 1 && w_maj <= 2)) {
// no more than 1 minor up, drawish
              mul[White] = 8; // 1/2

              ifelse = false;
            }
          }
        }
      }
    }

// black multiplier
    if (bp == 0) {
      // black has no pawns

      ifelse = true;
      if (ifelse && (b_tot == 1)) {
        //ASSERT(299, b_maj == 0);
        //ASSERT(300, b_min == 1);

// KBK* || KNK*, always insufficient
        mul[Black] = 0;

        ifelse = false;
      }

      if (ifelse && (b_tot == 2 && bn == 2)) {
        //ASSERT(301, b_maj == 0);
        //ASSERT(302, b_min == 2);

// KNNK*, usually insufficient
        if (w_tot != 0 || wp == 0)
          mul[Black] = 0;
        else {
          // KNNKP+, might not be draw
          mul[Black] = 1; // 1/16
        }

        ifelse = false;
      }

      if (ifelse && (b_tot == 2 && bb == 2 && w_tot == 1 && wn == 1)) {
        //ASSERT(303, b_maj == 0);
        //ASSERT(304, b_min == 2);
        //ASSERT(305, w_maj == 0);
        //ASSERT(306, w_min == 1);

// KBBKN*, barely drawish (not at all?)
        mul[Black] = 8; // 1/2

        ifelse = false;
      }

      if (ifelse && (b_tot - w_tot <= 1 && b_maj <= 2)) {
// no more than 1 minor up, drawish
        mul[Black] = 2; // 1/8

        ifelse = false;
      }
    } else {
      if (bp == 1) {
        // black has one pawn

        if (w_min != 0) {
// assume white sacrifices a minor against the lone pawn

          w_min--;
          w_tot--;

          ifelse = true;
          if (ifelse && (b_tot == 1)) {
            //ASSERT(307, b_maj == 0);
            //ASSERT(308, b_min == 1);

// KBK* || KNK*, always insufficient
            mul[Black] = 4; // 1/4

            ifelse = false;
          }

          if (ifelse && (b_tot == 2 && bn == 2)) {
            //ASSERT(309, b_maj == 0);
            //ASSERT(310, b_min == 2);

// KNNK*, usually insufficient
            mul[Black] = 4; // 1/4

            ifelse = false;
          }

          if (ifelse && (b_tot - w_tot <= 1 && b_maj <= 2)) {
// no more than 1 minor up, drawish
            mul[Black] = 8; // 1/2

            ifelse = false;
          }
        } else {
          if (wr != 0) {
// assume white sacrifices a rook against the lone pawn

            w_maj--;
            w_tot -= 2;

            ifelse = true;
            if (ifelse && (b_tot == 1)) {
              //ASSERT(311, b_maj == 0);
              //ASSERT(312, b_min == 1);

// KBK* || KNK*, always insufficient
              mul[Black] = 4; // 1/4

              ifelse = false;
            }

            if (ifelse && (b_tot == 2 && bn == 2)) {
              //ASSERT(313, b_maj == 0);
              //ASSERT(314, b_min == 2);

// KNNK*, usually insufficient
              mul[Black] = 4; // 1/4

              ifelse = false;
            }

            if (ifelse && (b_tot - w_tot <= 1 && b_maj <= 2)) {
// no more than 1 minor up, drawish
              mul[Black] = 8; // 1/2

              ifelse = false;
            }
          }
        }
      }
    }

// potential draw for white
    if (wt == wb + wp && wp >= 1) cflags[White] |= MatRookPawnFlag;

    if (wt == wb + wp && wb <= 1 && wp >= 1 && bt > bp)
      cflags[White] |= MatBishopFlag;

    if (wt == 2 && wn == 1 && wp == 1 && bt > bp)
      cflags[White] |= MatKnightFlag;

// potential draw for black
    if (bt == bb + bp && bp >= 1) cflags[Black] |= MatRookPawnFlag;

    if (bt == bb + bp && bb <= 1 && bp >= 1 && wt > wp)
      cflags[Black] |= MatBishopFlag;

    if (bt == 2 && bn == 1 && bp == 1 && wt > wp)
      cflags[Black] |= MatKnightFlag;

// draw leaf (likely draw)
    if (recog == MAT_KQKQ || recog == MAT_KRKR) {
      mul[White] = 0;
      mul[Black] = 0;
    }

// king safety
    if (bq >= 1 && bq + br + bb + bn >= 2) cflags[White] |= MatKingFlag;
    if (wq >= 1 && wq + wr + wb + wn >= 2) cflags[Black] |= MatKingFlag;

// phase (0: opening . 256: endgame)
    phase = TotalPhase;

    phase -= wp * PawnPhase;
    phase -= wn * KnightPhase;
    phase -= wb * BishopPhase;
    phase -= wr * RookPhase;
    phase -= wq * QueenPhase;

    phase -= bp * PawnPhase;
    phase -= bn * KnightPhase;
    phase -= bb * BishopPhase;
    phase -= br * RookPhase;
    phase -= bq * QueenPhase;

    if (phase < 0) phase = 0;

    //ASSERT(315, phase >= 0 && phase <= TotalPhase);
    phase = min(((phase << 8) + (TotalPhase >>> 1)) ~/ TotalPhase, 256);

    //ASSERT(316, phase >= 0 && phase <= 256);

// material
    opening = 0;
    endgame = 0;

    opening += wp * PawnOpening;
    opening += wn * KnightOpening;
    opening += wb * BishopOpening;
    opening += wr * RookOpening;
    opening += wq * QueenOpening;

    opening -= bp * PawnOpening;
    opening -= bn * KnightOpening;
    opening -= bb * BishopOpening;
    opening -= br * RookOpening;
    opening -= bq * QueenOpening;

    endgame += wp * PawnEndgame;
    endgame += wn * KnightEndgame;
    endgame += wb * BishopEndgame;
    endgame += wr * RookEndgame;
    endgame += wq * QueenEndgame;

    endgame -= bp * PawnEndgame;
    endgame -= bn * KnightEndgame;
    endgame -= bb * BishopEndgame;
    endgame -= br * RookEndgame;
    endgame -= bq * QueenEndgame;

// bishop pair
    if (wb >= 2) {
      // assumes different colours
      opening += BishopPairOpening;
      endgame += BishopPairEndgame;
    }

    if (bb >= 2) {
      // assumes different colours
      opening -= BishopPairOpening;
      endgame -= BishopPairEndgame;
    }

// store info
    info.recog = recog;
    info.flags = flags;

    for (colour = 0; colour <= 1; colour++) {
      info.cflags[colour] = cflags[colour];
      info.mul[colour] = mul[colour];
    }

    info.phase = phase;
    info.opening = (opening * MaterialWeight) ~/ 256;
    info.endgame = (endgame * MaterialWeight) ~/ 256;
  }

  bool move_is_ok(int move) {
    if (move < 0 || move >= 65536 || move == MoveNone || move == Movenull)
      return false;

    return true;
  }

  int move_promote(move) {
    int code; // int
    int piece; // int

    //ASSERT(317, move_is_ok(move));

    //ASSERT(318, MOVE_IS_PROMOTE(move));
    code = ((move >>> 12) & 3);
    piece = PromotePiece[code];

    if (SQUARE_RANK(MOVE_TO(move)) == Rank8)
      piece |= WhiteFlag;
    else {
      //ASSERT(319, SQUARE_RANK(MOVE_TO(move)) == Rank1);
      piece |= BlackFlag;
    }

    //ASSERT(320, piece_is_ok(piece));

    return piece;
  }

  int move_order(int move) {
    //ASSERT(321, move_is_ok(move));

    return (((move & V07777) << 2) | ((move >>> 12) & 3));
  }

  bool move_is_capture(int move, board_t board) {
    //ASSERT(322, move_is_ok(move));

    return MOVE_IS_EN_PASSANT(move) || (board.square[MOVE_TO(move)] != Empty);
  }

  bool move_is_under_promote(int move) {
    //ASSERT(324, move_is_ok(move));

    return MOVE_IS_PROMOTE(move) && ((move & MoveAllFlags) != MovePromoteQueen);
  }

  bool move_is_tactical(int move, board_t board) {
    //ASSERT(325, move_is_ok(move));

    return ((move & (1 << 15)) != 0) || (board.square[MOVE_TO(move)] != Empty);
  }

  int move_capture(int move, board_t board) {
    //ASSERT(327, move_is_ok(move));

    if (MOVE_IS_EN_PASSANT(move))
      return PAWN_OPP(board.square[MOVE_FROM(move)]);

    return board.square[MOVE_TO(move)];
  }

  move_to_string(int move, string_t str1) {
    string_t str2 = new string_t();

    //ASSERT(329, move == Movenull || move_is_ok(move));

    str1.v = "";

// if not null move
    if (move != Movenull) {
// normal moves
      square_to_string(MOVE_FROM(move), str2);
      str1.v += str2.v;
      square_to_string(MOVE_TO(move), str2);
      str1.v += str2.v;
      //ASSERT(332, (str1.v.length == 4));

// promotes
      if (MOVE_IS_PROMOTE(move))
        str1.v += piece_to_char(move_promote(move)).toLowerCase();
    }
  }

  int move_from_string(string_t str1, board_t board) {
    string_t str2 = new string_t();
    String c = " "; // char;

    int from; // int
    int to; // int
    int move; // int
    int piece; // int
    int delta; // int

// from
    str2.v = substr(str1.v, 0, 2);

    from = square_from_string(str2);
    if (from == SquareNone) return MoveNone;

// to
    str2.v = substr(str1.v, 2, 2);

    to = square_from_string(str2);
    if (to == SquareNone) return MoveNone;

    move = MOVE_MAKE(from, to);

// promote
    if (str1.v.length > 4) {
      c = str1.v[4];
      if (c == "n") move |= MovePromoteKnight;
      if (c == "b") move |= MovePromoteBishop;
      if (c == "r") move |= MovePromoteRook;
      if (c == "q") move |= MovePromoteQueen;
    }

// flags
    piece = board.square[from];

    if (PIECE_IS_PAWN(piece)) {
      if (to == board.ep_square) move |= MoveEnPassant;
    } else {
      if (PIECE_IS_KING(piece)) {
        delta = to - from;
        if (delta == 2 || delta == -2) move |= MoveCastle;
      }
    }

    return move;
  }

  gen_quiet_checks(list_t list, board_t board) {
    //ASSERT(337, !board_is_check(board));

    list.size = 0;
    add_quiet_checks(list, board);
    add_castle_checks(list, board);

    //ASSERT(338, list_is_ok(list));
  }

  add_quiet_checks(list_t list, board_t board) {
    int me; // int
    int opp; // int
    int king; // int

    int ptr; // int
    int ptr_2; // int

    int from; // int
    int to; // int
    int sq; // int

    int piece; // int
    int inc_ptr; // int
    int inc; // int
    int pawn; // int
    int rank; // int
    List<int> pin = List.filled(9, 0); // int[8+1]
    bool gotonextpiece = false;

// init
    me = board.turn;
    opp = COLOUR_OPP(me);

    king = KING_POS(board, opp);

    find_pins(pin, board);

// indirect checks
    ptr = 0;
    for (;;) {
      from = pin[ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      //ASSERT(341, is_pinned(board, from, opp));

      if (PIECE_IS_PAWN(piece)) {
        inc = PawnMoveInc[me];
        rank = PAWN_RANK(from, me);

        if (rank != Rank7) {
          // promotes are generated with captures
          to = from + inc;
          if (board.square[to] == Empty) {
            if (DELTA_INC_LINE(to - king) != DELTA_INC_LINE(from - king)) {
              //ASSERT(342, !SquareIsPromote[to]);
              LIST_ADD(list, MOVE_MAKE(from, to));
              if (rank == Rank2) {
                to = from + (2 * inc);
                if (board.square[to] == Empty) {
                  //ASSERT(343, DELTA_INC_LINE(to - king) != DELTA_INC_LINE(from - king));
                  //ASSERT(344, !SquareIsPromote[to]);
                  LIST_ADD(list, MOVE_MAKE(from, to));
                }
              }
            }
          }
        }
      } else {
        if (PIECE_IS_SLIDER(piece)) {
          inc_ptr = 0;
          for (;;) {
            inc = PieceInc[piece][inc_ptr];
            if (inc == IncNone) break;

            to = from + inc;
            for (;;) {
              if (board.square[to] != Empty) break;

              //ASSERT(345, DELTA_INC_LINE(to - king) != DELTA_INC_LINE(from - king));
              LIST_ADD(list, MOVE_MAKE(from, to));

              to += inc;
            }
            inc_ptr++;
          }
        } else {
          inc_ptr = 0;
          for (;;) {
            inc = PieceInc[piece][inc_ptr];
            if (inc == IncNone) break;

            to = from + inc;
            if (board.square[to] == Empty) {
              if (DELTA_INC_LINE(to - king) != DELTA_INC_LINE(from - king)) {
                LIST_ADD(list, MOVE_MAKE(from, to));
              }
            }

            inc_ptr++;
          }
        }
      }
      ptr++;
    }

// piece direct checks
    ptr = 1; // no king
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      ptr_2 = 0;
      for (;;) {
        sq = pin[ptr_2];
        if (sq == SquareNone) break;

        if (sq == from) {
          gotonextpiece = true;
          break;
        }

        ptr_2++;
      }

      if (gotonextpiece)
        gotonextpiece = false;
      else {
        //ASSERT(346, !is_pinned(board, from, opp));

        piece = board.square[from];

        if (PIECE_IS_SLIDER(piece)) {
          inc_ptr = 0;
          for (;;) {
            inc = PieceInc[piece][inc_ptr];
            if (inc == IncNone) break;

            to = from + inc;
            for (;;) {
              if (board.square[to] != Empty) break;

              if (PIECE_ATTACK(board, piece, to, king))
                LIST_ADD(list, MOVE_MAKE(from, to));

              to += inc;
            }
            inc_ptr++;
          }
        } else {
          inc_ptr = 0;
          for (;;) {
            inc = PieceInc[piece][inc_ptr];
            if (inc == IncNone) break;

            to = from + inc;
            if (board.square[to] == Empty) {
              if (PSEUDO_ATTACK(piece, king - to))
                LIST_ADD(list, MOVE_MAKE(from, to));
            }

            inc_ptr++;
          }
        }
      }

// next_piece:
      ptr++;
    }

// pawn direct checks
    inc = PawnMoveInc[me];
    pawn = PawnMake[me];

    to = king - (inc - 1);
    //ASSERT(347, PSEUDO_ATTACK(pawn, king - to));

    from = to - inc;
    if (board.square[from] == pawn) {
      if (board.square[to] == Empty) {
        //ASSERT(348, !SquareIsPromote[to]);
        LIST_ADD(list, MOVE_MAKE(from, to));
      }
    } else {
      from = to - (2 * inc);
      if (board.square[from] == pawn) {
        if (PAWN_RANK(from, me) == Rank2 &&
            board.square[to] == Empty &&
            board.square[from + inc] == Empty) {
          //ASSERT(349, !SquareIsPromote[to]);
          LIST_ADD(list, MOVE_MAKE(from, to));
        }
      }
    }

    to = king - (inc + 1);
    //ASSERT(350, PSEUDO_ATTACK(pawn, king - to));

    from = to - inc;
    if (board.square[from] == pawn) {
      if (board.square[to] == Empty) {
        //ASSERT(351, !SquareIsPromote[to]);
        LIST_ADD(list, MOVE_MAKE(from, to));
      }
    } else {
      from = to - (2 * inc);
      if (board.square[from] == pawn) {
        if (PAWN_RANK(from, me) == Rank2 &&
            board.square[to] == Empty &&
            board.square[from + inc] == Empty) {
          //ASSERT(352, !SquareIsPromote[to]);
          LIST_ADD(list, MOVE_MAKE(from, to));
        }
      }
    }
  }

  add_castle_checks(list_t list, board_t board) {
    //ASSERT(355, !board_is_check(board));

    if (COLOUR_IS_WHITE(board.turn)) {
      if ((board.flags & FlagsWhiteKingCastle) != 0 &&
          board.square[F1] == Empty &&
          board.square[G1] == Empty &&
          (!is_attacked(board, F1, Black))) {
        add_check(list, MOVE_MAKE_FLAGS(E1, G1, MoveCastle), board);
      }

      if ((board.flags & FlagsWhiteQueenCastle) != 0 &&
          board.square[D1] == Empty &&
          board.square[C1] == Empty &&
          board.square[B1] == Empty &&
          (!is_attacked(board, D1, Black))) {
        add_check(list, MOVE_MAKE_FLAGS(E1, C1, MoveCastle), board);
      }
    } else {
      // black

      if ((board.flags & FlagsBlackKingCastle) != 0 &&
          board.square[F8] == Empty &&
          board.square[G8] == Empty &&
          (!is_attacked(board, F8, White))) {
        add_check(list, MOVE_MAKE_FLAGS(E8, G8, MoveCastle), board);
      }

      if ((board.flags & FlagsBlackQueenCastle) != 0 &&
          board.square[D8] == Empty &&
          board.square[C8] == Empty &&
          board.square[B8] == Empty &&
          (!is_attacked(board, D8, White))) {
        add_check(list, MOVE_MAKE_FLAGS(E8, C8, MoveCastle), board);
      }
    }
  }

  add_check(list_t list, int move, board_t board) {
    undo_t undo = new undo_t(); // undo_t[1];

    //ASSERT(357, move_is_ok(move));

    move_do(board, move, undo);
    if (IS_IN_CHECK(board, board.turn)) LIST_ADD(list, move);

    move_undo(board, move, undo);
  }

  bool move_is_check(int move, board_t board) {
    undo_t undo = new undo_t(); // undo_t[1];

    bool check; // bool
    int me; // int
    int opp; // int
    int king; // int
    int from; // int
    int to; // int
    int piece; // int

    //ASSERT(359, move_is_ok(move));

// slow test for complex moves
    if (MOVE_IS_SPECIAL(move)) {
      move_do(board, move, undo);
      check = IS_IN_CHECK(board, board.turn);
      move_undo(board, move, undo);
      return check;
    }

// init
    me = board.turn;
    opp = COLOUR_OPP(me);
    king = KING_POS(board, opp);

    from = MOVE_FROM(move);
    to = MOVE_TO(move);
    piece = board.square[from];
    //ASSERT(361, COLOUR_IS(piece, me));

// direct check
    if (PIECE_ATTACK(board, piece, to, king)) return true;

// indirect check
    if (is_pinned(board, from, opp) &&
        DELTA_INC_LINE(king - to) != DELTA_INC_LINE(king - from)) return true;

    return false;
  }

  find_pins(List<int> list, board_t board) {
    int me; // int
    int opp; // int
    int king; // int
    int ptr; // int
    int from; // int
    int piece; // int
    int delta; // int
    int inc; // int
    int sq; // int
    int pin; // int
    int capture; // int
    int q = 0; // int

// init
    me = board.turn;
    opp = COLOUR_OPP(me);

    king = KING_POS(board, opp);

    ptr = 1; // no king
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      delta = king - from;
      //ASSERT(364, delta_is_ok(delta));

      if (PSEUDO_ATTACK(piece, delta)) {
        //ASSERT(365, PIECE_IS_SLIDER(piece));

        inc = DELTA_INC_LINE(delta);
        //ASSERT(366, inc != IncNone);

        //ASSERT(367, SLIDER_ATTACK(piece, inc));

        sq = from;
        for (;;) {
          sq += inc;
          capture = board.square[sq];
          if (capture != Empty) break;
        }

        //ASSERT(368, sq != king);

        if (COLOUR_IS(capture, me)) {
          pin = sq;

          for (;;) {
            sq += inc;
            if (board.square[sq] != Empty) break;
          }

          if (sq == king) list[q++] = pin;
        }
      }

      ptr++;
    }

    list[q] = SquareNone;
  }

  initCmsk(int sq, int flagMask) {
    CastleMask[sq] &= (~flagMask);
  }

  move_do_init() {
    initCmsk(E1, FlagsWhiteKingCastle);
    initCmsk(H1, FlagsWhiteKingCastle);

    initCmsk(E1, FlagsWhiteQueenCastle);
    initCmsk(A1, FlagsWhiteQueenCastle);

    initCmsk(E8, FlagsBlackKingCastle);
    initCmsk(H8, FlagsBlackKingCastle);

    initCmsk(E8, FlagsBlackQueenCastle);
    initCmsk(A8, FlagsBlackQueenCastle);
  }

  move_do(board_t board, int move, undo_t undo) {
    int me; // int
    int opp; // int
    int from; // int
    int to; // int
    int piece; // int
    int pos; // int
    int capture; // int
    int old_flags; // int
    int new_flags; // int

    int delta; // int
    int sq; // int
    int pawn; // int
    int rook; // int

    //ASSERT(370, move_is_ok(move));

    //ASSERT(372, board_is_legal(board));

// initialise undo
    undo.capture = false;

    undo.turn = board.turn;
    undo.flags = board.flags;
    undo.ep_square = board.ep_square;
    undo.ply_nb = board.ply_nb;

    undo.cap_sq = board.cap_sq;

    undo.opening = board.opening;
    undo.endgame = board.endgame;

    undo.key = board.key;
    undo.pawn_key = board.pawn_key;
    undo.material_key = board.material_key;

// init
    me = board.turn;
    opp = COLOUR_OPP(me);

    from = MOVE_FROM(move);
    to = MOVE_TO(move);

    piece = board.square[from];

    //ASSERT(373, COLOUR_IS(piece, me));

// update key stack

    //ASSERT(374, board.sp < StackSize);
    board.stack[board.sp] = board.key;
    board.sp++;

// update turn
    board.turn = opp;

// update castling rights
    old_flags = board.flags;
    new_flags = ((old_flags & CastleMask[from]) & CastleMask[to]);

    board.flags = new_flags;

// update en-passant square
    sq = board.ep_square;
    if (sq != SquareNone) board.ep_square = SquareNone;

    if (PIECE_IS_PAWN(piece)) {
      delta = to - from;

      if (delta == 32 || delta == -32) {
        pawn = PawnMake[opp];
        if (board.square[to - 1] == pawn || board.square[to + 1] == pawn) {
          board.ep_square = (from + to) ~/ 2;
        }
      }
    }

// update move number (captures are handled later)
    board.ply_nb++;
    if (PIECE_IS_PAWN(piece)) board.ply_nb = 0; // conversion

// update last square
    board.cap_sq = SquareNone;

// remove the captured piece
    sq = to;
    if (MOVE_IS_EN_PASSANT(move)) sq = SQUARE_EP_DUAL(sq);

    capture = board.square[sq];
    if (capture != Empty) {
      //ASSERT(375, COLOUR_IS(capture, opp));
      //ASSERT(376, !PIECE_IS_KING(capture));

      undo.capture = true;
      undo.capture_square = sq;
      undo.capture_piece = capture;
      undo.capture_pos = board.pos[sq];

      square_clear(board, sq, capture, true);

      board.ply_nb = 0; // conversion
      board.cap_sq = to;
    }

// move the piece
    if (MOVE_IS_PROMOTE(move)) {
// promote
      undo.pawn_pos = board.pos[from];

      square_clear(board, from, piece, true);

      piece = move_promote(move);

// insert the promote piece in MV order
      pos = board.piece_size[me];
      while (pos > 0 && piece > board.square[board.piece[me][pos - 1]]) pos--;

      square_set(board, to, piece, pos, true);

      board.cap_sq = to;
    } else {
// normal move
      square_move(board, from, to, piece, true);
    }

// move the rook in case of castling
    if (MOVE_IS_CASTLE(move)) {
      rook = (Rook64 | COLOUR_FLAG(me));

      if (to == G1) {
        square_move(board, H1, F1, rook, true);
      } else {
        if (to == C1) {
          square_move(board, A1, D1, rook, true);
        } else {
          if (to == G8) {
            square_move(board, H8, F8, rook, true);
          } else {
            if (to == C8) {
              square_move(board, A8, D8, rook, true);
            } else {
              //ASSERT(377, false);
            }
          }
        }
      }
    }

    //ASSERT(378, board_is_ok(board));
  }

  move_undo(board_t board, int move, undo_t undo) {
    int me; // int
    int from; // int
    int to; // int
    int piece; // int
    int pos; // int
    int rook; // int

    //ASSERT(380, move_is_ok(move));

// init
    me = undo.turn;

    from = MOVE_FROM(move);
    to = MOVE_TO(move);

    piece = board.square[to];
    //ASSERT(382, COLOUR_IS(piece, me));

// castle
    if (MOVE_IS_CASTLE(move)) {
      rook = (Rook64 | COLOUR_FLAG(me));

      if (to == G1) {
        square_move(board, F1, H1, rook, false);
      } else {
        if (to == C1) {
          square_move(board, D1, A1, rook, false);
        } else {
          if (to == G8) {
            square_move(board, F8, H8, rook, false);
          } else {
            if (to == C8) {
              square_move(board, D8, A8, rook, false);
            } else {
              //ASSERT(383, false);
            }
          }
        }
      }
    }

// move the piece backward
    if (MOVE_IS_PROMOTE(move)) {
// promote

      //ASSERT(384, piece == move_promote(move));
      square_clear(board, to, piece, false);

      piece = PawnMake[me];
      pos = undo.pawn_pos;

      square_set(board, from, piece, pos, false);
    } else {
// normal move
      square_move(board, to, from, piece, false);
    }

// put the captured piece back
    if (undo.capture) {
      square_set(board, undo.capture_square, undo.capture_piece,
          undo.capture_pos, false);
    }

// update board info
    board.turn = undo.turn;
    board.flags = undo.flags;
    board.ep_square = undo.ep_square;
    board.ply_nb = undo.ply_nb;

    board.cap_sq = undo.cap_sq;

    board.opening = undo.opening;
    board.endgame = undo.endgame;

    board.key = undo.key;
    board.pawn_key = undo.pawn_key;
    board.material_key = undo.material_key;

// update key stack
    //ASSERT(385, board.sp > 0);
    board.sp--;

    //ASSERT(386, board_is_ok(board));
    //ASSERT(387, board_is_legal(board));
  }

  move_do_null(board_t board, undo_t undo) {
    int sq; // int

    //ASSERT(390, board_is_legal(board));
    //ASSERT(391, !board_is_check(board));

// initialise undo
    undo.turn = board.turn;
    undo.ep_square = board.ep_square;
    undo.ply_nb = board.ply_nb;
    undo.cap_sq = board.cap_sq;
    undo.key = board.key;

// update key stack
    //ASSERT(392, board.sp < StackSize);
    board.stack[board.sp] = board.key;
    board.sp++;

// update turn
    board.turn = COLOUR_OPP(board.turn);

// update en-passant square
    sq = board.ep_square;
    if (sq != SquareNone) board.ep_square = SquareNone;

// update move number
    board.ply_nb = 0; // null move is considered as a conversion

// update last square
    board.cap_sq = SquareNone;

    //ASSERT(393, board_is_ok(board));
  }

  move_undo_null(board_t board, undo_t undo) {
    //ASSERT(396, board_is_legal(board));
    //ASSERT(397, !board_is_check(board));

// update board info
    board.turn = undo.turn;
    board.ep_square = undo.ep_square;
    board.ply_nb = undo.ply_nb;
    board.cap_sq = undo.cap_sq;
    board.key = undo.key;

// update key stack
    //ASSERT(398, board.sp > 0);
    board.sp--;

    //ASSERT(399, board_is_ok(board));
  }

  square_clear(board_t board, int square, int piece, bool update) {
    int pos; // int
    int piece_12; // int
    int colour; // int
    int sq; // int
    int i; // int
    int size; // int
    int sq_64; // int
    int t; // int
    int hash_xor; // uint64

    //ASSERT(401, SQUARE_IS_OK(square));
    //ASSERT(402, piece_is_ok(piece));

// init
    pos = board.pos[square];
    //ASSERT(404, pos >= 0);
    piece_12 = PieceTo12[piece];
    colour = PIECE_COLOUR(piece);

// square
    //ASSERT(405, board.square[square] == piece);
    board.square[square] = Empty;

// piece list
    if (!PIECE_IS_PAWN(piece)) {
// init
      size = board.piece_size[colour];
      //ASSERT(406, size >= 1);

// stable swap

      //ASSERT(407, pos >= 0 && pos < size);

      //ASSERT(408, board.pos[square] == pos);
      board.pos[square] = -1;

      for (i = pos; i <= size - 2; i++) {
        sq = board.piece[colour][i + 1];

        board.piece[colour][i] = sq;

        //ASSERT(409, board.pos[sq] == i + 1);
        board.pos[sq] = i;
      }

// size
      size--;
      board.piece[colour][size] = SquareNone;
      board.piece_size[colour] = size;
    } else {
// init

      size = board.pawn_size[colour];
      //ASSERT(410, size >= 1);

// stable swap
      //ASSERT(411, pos >= 0 && pos < size);

      //ASSERT(412, board.pos[square] == pos);
      board.pos[square] = -1;

      for (i = pos; i <= size - 2; i++) {
        sq = board.pawn[colour][i + 1];

        board.pawn[colour][i] = sq;

        //ASSERT(413, board.pos[sq] == i + 1);
        board.pos[sq] = i;
      }

// size
      size--;
      board.pawn[colour][size] = SquareNone;
      board.pawn_size[colour] = size;

// pawn "bitboard"
      t = SQUARE_FILE(square);
      board.pawn_file[colour][t] ^= BitEQ[PAWN_RANK(square, colour)];
    }

// material
    //ASSERT(414, board.piece_nb > 0);
    board.piece_nb--;

    //ASSERT(415, board.number[piece_12] > 0);
    board.number[piece_12]--;

// update
    if (update) {
// init
      sq_64 = SquareTo64[square];

// PST
      board.opening -= Pget(piece_12, sq_64, Opening);
      board.endgame -= Pget(piece_12, sq_64, Endgame);

// hash key
      hash_xor = Random64[RandomPiece + ((piece_12 ^ 1) << 6) + sq_64];
// xor 1 for PolyGlot book (not AS3)
      board.key ^= hash_xor;
      if (PIECE_IS_PAWN(piece)) board.pawn_key ^= hash_xor;

// material key
      board.material_key ^= Random64[(piece_12 << 4) + board.number[piece_12]];
    }
  }

  square_set(board_t board, int square, int piece, int pos, bool update) {
    int piece_12; // int
    int colour; // int
    int sq; // int
    int i; // int
    int size; // int
    int sq_64; // int
    int t; // int
    int hash_xor; // uint64

    //ASSERT(417, SQUARE_IS_OK(square));
    //ASSERT(418, piece_is_ok(piece));
    //ASSERT(419, pos >= 0);

// init
    piece_12 = PieceTo12[piece];
    colour = PIECE_COLOUR(piece);

// square
    //ASSERT(421, board.square[square] == Empty);
    board.square[square] = piece;

// piece list
    if (!PIECE_IS_PAWN(piece)) {
// init
      size = board.piece_size[colour];
      //ASSERT(422, size >= 0);

// size
      size++;
      board.piece[colour][size] = SquareNone;
      board.piece_size[colour] = size;

// stable swap
      //ASSERT(423, pos >= 0 && pos < size);

      for (i = size - 1; i >= pos + 1; i--) {
        sq = board.piece[colour][i - 1];

        board.piece[colour][i] = sq;
        //ASSERT(424, board.pos[sq] == i - 1);
        board.pos[sq] = i;
      }

      board.piece[colour][pos] = square;
      //ASSERT(425, board.pos[square] == -1);
      board.pos[square] = pos;
    } else {
// init
      size = board.pawn_size[colour];
      //ASSERT(426, size >= 0);

// size
      size++;
      board.pawn[colour][size] = SquareNone;
      board.pawn_size[colour] = size;

// stable swap
      //ASSERT(427, pos >= 0 && pos < size);

      for (i = size - 1; i >= pos + 1; i--) {
        sq = board.pawn[colour][i - 1];

        board.pawn[colour][i] = sq;
        //ASSERT(428, board.pos[sq] == i - 1);
        board.pos[sq] = i;
      }

      board.pawn[colour][pos] = square;
      //ASSERT(429, board.pos[square] == -1);
      board.pos[square] = pos;

// pawn "bitboard"
      t = SQUARE_FILE(square);
      board.pawn_file[colour][t] ^= BitEQ[PAWN_RANK(square, colour)];
    }

// material
    //ASSERT(430, board.piece_nb < 32);
    board.piece_nb++;
    //ASSERT(431, board.number[piece_12] < 9);
    board.number[piece_12]++;

// update
    if (update) {
// init
      sq_64 = SquareTo64[square];
// PST
      board.opening += Pget(piece_12, sq_64, Opening);
      board.endgame += Pget(piece_12, sq_64, Endgame);
// hash key
      hash_xor = Random64[RandomPiece + ((piece_12 ^ 1) << 6) + sq_64];
// xor 1 for PolyGlot book (not AS3)
      board.key ^= hash_xor;
      if (PIECE_IS_PAWN(piece)) board.pawn_key ^= hash_xor;

// material key
      board.material_key ^= Random64[(piece_12 << 4) + board.number[piece_12]];
    }
  }

  square_move(board_t board, int from, int to, int piece, bool update) {
    int piece_12; // int
    int colour; // int
    int pos; // int
    int from_64; // int
    int to_64; // int
    int piece_index; // int
    int t; // int
    int hash_xor; // uint64

    //ASSERT(433, SQUARE_IS_OK(from));
    //ASSERT(434, SQUARE_IS_OK(to));
    //ASSERT(435, piece_is_ok(piece));

// init
    colour = PIECE_COLOUR(piece);
    pos = board.pos[from];
    print("Here is POS Befor acces ${pos}");
    //ASSERT(437, pos >= 0);

// from
    //ASSERT(438, board.square[from] == piece);
    board.square[from] = Empty;
    //ASSERT(439, board.pos[from] == pos);
    board.pos[from] = -1; // not needed
// to
    //ASSERT(440, board.square[to] == Empty);
    board.square[to] = piece;
    //ASSERT(441, board.pos[to] == -1);
    board.pos[to] = pos;

// piece list

    if (!PIECE_IS_PAWN(piece)) {
      //ASSERT(442, board.piece[colour][pos] == from);
      board.piece[colour][pos] = to;
    } else {
      //ASSERT(443, board.pawn[colour][pos] == from);
      board.pawn[colour][pos] = to;

// pawn "bitboard"
      t = SQUARE_FILE(from);
      board.pawn_file[colour][t] ^= BitEQ[PAWN_RANK(from, colour)];
      t = SQUARE_FILE(to);
      board.pawn_file[colour][t] ^= BitEQ[PAWN_RANK(to, colour)];
    }

// update
    if (update) {
// init
      from_64 = SquareTo64[from];
      to_64 = SquareTo64[to];
      piece_12 = PieceTo12[piece];

// PST
      board.opening +=
          Pget(piece_12, to_64, Opening) - Pget(piece_12, from_64, Opening);
      board.endgame +=
          Pget(piece_12, to_64, Endgame) - Pget(piece_12, from_64, Endgame);

// hash key
      piece_index = RandomPiece + ((piece_12 ^ 1) << 6);
// xor 1 for PolyGlot book (not AS3)

      hash_xor =
          (Random64[piece_index + to_64] ^ Random64[piece_index + from_64]);

      board.key ^= hash_xor;
      if (PIECE_IS_PAWN(piece)) board.pawn_key ^= hash_xor;
    }
  }

  gen_legal_evasions(list_t list, board_t board, attack_t attack) {
    gen_evasions(list, board, attack, true, false);
    //ASSERT(447, list_is_ok(list));
  }

  gen_pseudo_evasions(list_t list, board_t board, attack_t attack) {
    gen_evasions(list, board, attack, false, false);
    //ASSERT(451, list_is_ok(list));
  }

  bool legal_evasion_exist(board_t board, attack_t attack) {
    list_t list = new list_t(); // list[1] dummy
    return gen_evasions(list, board, attack, true, true);
  }

  bool gen_evasions(
      list_t list, board_t board, attack_t attack, bool legal, bool stop) {
    int me; // int
    int opp; // int
    int opp_flag; // int
    int king; // int
    int inc_ptr; // int
    int inc; // int
    int to; // int
    int piece; // int

    //ASSERT(459, board_is_check(board));
    //ASSERT(460, ATTACK_IN_CHECK(attack));

// init
    list.size = 0;

    me = board.turn;
    opp = COLOUR_OPP(me);

    opp_flag = COLOUR_FLAG(opp);

    king = KING_POS(board, me);

    inc_ptr = 0;
    for (;;) {
      inc = KingInc[inc_ptr];
      if (inc == IncNone) break;

// avoid escaping along a check line
      if (inc != -attack.di[0] && inc != -attack.di[1]) {
        to = king + inc;
        piece = board.square[to];
        if (piece == Empty || FLAG_IS(piece, opp_flag)) {
          if ((!legal) || (!is_attacked(board, to, opp))) {
            if (stop) return true;

            LIST_ADD(list, MOVE_MAKE(king, to));
          }
        }
      }

      inc_ptr++;
    }

    if (attack.dn >= 2) return false; // double check, we are

// single check
    //ASSERT(461, attack.dn == 1);

// capture the checking piece
    if (add_pawn_captures(list, board, attack.ds[0], legal, stop) && stop)
      return true;

    if (add_piece_moves(list, board, attack.ds[0], legal, stop) && stop)
      return true;

// interpose a piece
    inc = attack.di[0];

    if (inc != IncNone) {
      // line
      to = king + inc;
      while (to != attack.ds[0]) {
        //ASSERT(462, SQUARE_IS_OK(to));
        //ASSERT(463, board.square[to] == Empty);
        if (add_pawn_moves(list, board, to, legal, stop) && stop) return true;

        if (add_piece_moves(list, board, to, legal, stop) && stop) return true;

        to += inc;
      }
    }

    return false;
  }

  bool add_pawn_moves(
      list_t list, board_t board, int to, bool legal, bool stop) {
    int me; // int
    int inc; // int
    int pawn; // int
    int from; // int
    int piece; // int

    //ASSERT(466, SQUARE_IS_OK(to));
    //ASSERT(469, board.square[to] == Empty);
    me = board.turn;

    inc = PawnMoveInc[me];
    pawn = PawnMake[me];

    from = to - inc;
    piece = board.square[from];

    if (piece == pawn) {
      // single push

      if ((!legal) || (!is_pinned(board, from, me))) {
        if (stop) return true;

        add_pawn_move(list, from, to);
      }
    } else {
      if (piece == Empty && PAWN_RANK(to, me) == Rank4) {
        // double push

        from = to - (2 * inc);
        if (board.square[from] == pawn) {
          if ((!legal) || (!is_pinned(board, from, me))) {
            if (stop) return true;

            //ASSERT(470, !SquareIsPromote[to]);
            LIST_ADD(list, MOVE_MAKE(from, to));
          }
        }
      }
    }

    return false;
  }

  bool add_pawn_captures(
      list_t list, board_t board, int to, bool legal, bool stop) {
    int me; // int
    int inc; // int
    int pawn; // int
    int from; // int

    //ASSERT(473, SQUARE_IS_OK(to));

    //ASSERT(476, COLOUR_IS(board.square[to], COLOUR_OPP(board.turn)));
    me = board.turn;

    inc = PawnMoveInc[me];
    pawn = PawnMake[me];

    from = to - (inc - 1);
    if (board.square[from] == pawn) {
      if ((!legal) || (!is_pinned(board, from, me))) {
        if (stop) return true;

        add_pawn_move(list, from, to);
      }
    }

    from = to - (inc + 1);
    if (board.square[from] == pawn) {
      if ((!legal) || (!is_pinned(board, from, me))) {
        if (stop) return true;

        add_pawn_move(list, from, to);
      }
    }

    if (board.ep_square != SquareNone &&
        to == SQUARE_EP_DUAL(board.ep_square)) {
      //ASSERT(477, PAWN_RANK(to, me) == Rank5);
      //ASSERT(478, PIECE_IS_PAWN(board.square[to]));

      to = board.ep_square;
      //ASSERT(479, PAWN_RANK(to, me) == Rank6);
      //ASSERT(480, board.square[to] == Empty);

      from = to - (inc - 1);
      if (board.square[from] == pawn) {
        if ((!legal) || (!is_pinned(board, from, me))) {
          if (stop) return true;

          //ASSERT(481, !SquareIsPromote[to]);
          LIST_ADD(list, MOVE_MAKE_FLAGS(from, to, MoveEnPassant));
        }
      }

      from = to - (inc + 1);
      if (board.square[from] == pawn) {
        if ((!legal) || (!is_pinned(board, from, me))) {
          if (stop) return true;

          //ASSERT(482, !SquareIsPromote[to]);
          LIST_ADD(list, MOVE_MAKE_FLAGS(from, to, MoveEnPassant));
        }
      }
    }

    return false;
  }

  bool add_piece_moves(
      list_t list, board_t board, int to, bool legal, bool stop) {
    int me; // int
    int ptr; // int
    int from; // int
    int piece; // int

    //ASSERT(485, SQUARE_IS_OK(to));
    me = board.turn;

    ptr = 1; // no king
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      if (PIECE_ATTACK(board, piece, from, to)) {
        if ((!legal) || (!is_pinned(board, from, me))) {
          if (stop) return true;

          LIST_ADD(list, MOVE_MAKE(from, to));
        }
      }

      ptr++;
    }

    return false;
  }

  gen_legal_moves(list_t list, board_t board) {
    attack_t attack = new attack_t(); // attack_t[1]

    attack_set(attack, board);

    if (ATTACK_IN_CHECK(attack)) {
      gen_legal_evasions(list, board, attack);
    } else {
      gen_moves(list, board);
      list_filter(list, board, true);
    }

    //ASSERT(490, list_is_ok(list));
  }

  gen_moves(list_t list, board_t board) {
    //ASSERT(493, !board_is_check(board));
    list.size = 0;
    add_moves(list, board);
    add_en_passant_captures(list, board);
    add_castle_moves(list, board);
    //ASSERT(494, list_is_ok(list));
  }

  gen_captures(list_t list, board_t board) {
    list.size = 0;
    add_captures(list, board);
    add_en_passant_captures(list, board);
    //ASSERT(497, list_is_ok(list));
  }

  gen_quiet_moves(list_t list, board_t board) {
    //ASSERT(500, !board_is_check(board));
    list.size = 0;
    add_quiet_moves(list, board);
    add_castle_moves(list, board);
    //ASSERT(501, list_is_ok(list));
  }

  add_moves(list_t list, board_t board) {
    int me; // int
    int opp; // int
    int opp_flag; // int
    int ptr; // int
    int from; // int
    int to; // int
    int piece; // int
    int capture; // int
    int inc_ptr; // int
    int inc; // int

    me = board.turn;
    opp = COLOUR_OPP(me);

    opp_flag = COLOUR_FLAG(opp);

// piece moves
    ptr = 0;
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      if (PIECE_IS_SLIDER(piece)) {
        inc_ptr = 0;
        for (;;) {
          inc = PieceInc[piece][inc_ptr];
          if (inc == IncNone) break;

          to = from + inc;
          for (;;) {
            capture = board.square[to];
            if (capture != Empty) break;

            LIST_ADD(list, MOVE_MAKE(from, to));

            to += inc;
          }

          if (FLAG_IS(capture, opp_flag)) LIST_ADD(list, MOVE_MAKE(from, to));

          inc_ptr++;
        }
      } else {
        inc_ptr = 0;
        for (;;) {
          inc = PieceInc[piece][inc_ptr];
          if (inc == IncNone) break;

          to = from + inc;
          capture = board.square[to];
          if (capture == Empty || FLAG_IS(capture, opp_flag))
            LIST_ADD(list, MOVE_MAKE(from, to));

          inc_ptr++;
        }
      }

      ptr++;
    }

// pawn moves
    inc = PawnMoveInc[me];

    ptr = 0;
    for (;;) {
      from = board.pawn[me][ptr];
      if (from == SquareNone) break;

      to = from + (inc - 1);
      if (FLAG_IS(board.square[to], opp_flag)) add_pawn_move(list, from, to);

      to = from + (inc + 1);
      if (FLAG_IS(board.square[to], opp_flag)) add_pawn_move(list, from, to);

      to = from + inc;
      if (board.square[to] == Empty) {
        add_pawn_move(list, from, to);
        if (PAWN_RANK(from, me) == Rank2) {
          to = from + (2 * inc);
          if (board.square[to] == Empty) {
            //ASSERT(504, !SquareIsPromote[to]);
            LIST_ADD(list, MOVE_MAKE(from, to));
          }
        }
      }

      ptr++;
    }
  }

  add_capt1(int from, int dt, list_t list, board_t board, int opp_flag) {
    int to = from + dt;
    if (FLAG_IS(board.square[to], opp_flag))
      LIST_ADD(list, MOVE_MAKE(from, to));
  }

  add_capt2(int from, int dt, list_t list, board_t board, int opp_flag) {
    int to = from + dt;
    int capture;
    for (;;) {
      capture = board.square[to];
      if (capture != Empty) break;
      to += dt;
    }
    if (FLAG_IS(capture, opp_flag)) LIST_ADD(list, MOVE_MAKE(from, to));
  }

  add_capt3(int from, int dt, list_t list, board_t board, int opp_flag) {
    int to = from + dt;
    if (FLAG_IS(board.square[to], opp_flag)) add_pawn_move(list, from, to);
  }

  add_capt4(int from, int dt, list_t list, board_t board) {
    int to = from + dt;
    if (board.square[to] == Empty) add_promote(list, MOVE_MAKE(from, to));
  }

  add_captures(list_t list, board_t board) {
    int me; // int
    int opp; // int
    int opp_flag; // int
    int ptr; // int
    int from; // int
    int piece; // int
    int p;

    me = board.turn;
    opp = COLOUR_OPP(me);
    opp_flag = COLOUR_FLAG(opp);

// piece captures
    ptr = 0;
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      p = PIECE_TYPE(piece);

      if (p == Knight64) {
        add_capt1(from, -33, list, board, opp_flag);
        add_capt1(from, -31, list, board, opp_flag);
        add_capt1(from, -18, list, board, opp_flag);
        add_capt1(from, -14, list, board, opp_flag);
        add_capt1(from, 14, list, board, opp_flag);
        add_capt1(from, 18, list, board, opp_flag);
        add_capt1(from, 31, list, board, opp_flag);
        add_capt1(from, 33, list, board, opp_flag);
      } else {
        if (p == Bishop64) {
          add_capt2(from, -17, list, board, opp_flag);
          add_capt2(from, -15, list, board, opp_flag);
          add_capt2(from, 15, list, board, opp_flag);
          add_capt2(from, 17, list, board, opp_flag);
        } else {
          if (p == Rook64) {
            add_capt2(from, -16, list, board, opp_flag);
            add_capt2(from, -1, list, board, opp_flag);
            add_capt2(from, 1, list, board, opp_flag);
            add_capt2(from, 16, list, board, opp_flag);
          } else {
            if (p == Queen64) {
              add_capt2(from, -17, list, board, opp_flag);
              add_capt2(from, -16, list, board, opp_flag);
              add_capt2(from, -15, list, board, opp_flag);
              add_capt2(from, -1, list, board, opp_flag);
              add_capt2(from, 1, list, board, opp_flag);
              add_capt2(from, 15, list, board, opp_flag);
              add_capt2(from, 16, list, board, opp_flag);
              add_capt2(from, 17, list, board, opp_flag);
            } else {
              if (p == King64) {
                add_capt1(from, -17, list, board, opp_flag);
                add_capt1(from, -16, list, board, opp_flag);
                add_capt1(from, -15, list, board, opp_flag);
                add_capt1(from, -1, list, board, opp_flag);
                add_capt1(from, 1, list, board, opp_flag);
                add_capt1(from, 15, list, board, opp_flag);
                add_capt1(from, 16, list, board, opp_flag);
                add_capt1(from, 17, list, board, opp_flag);
              } else {
                //ASSERT(507, false);
              }
            }
          }
        }
      }

      ptr++;
    }

// pawn captures
    if (COLOUR_IS_WHITE(me)) {
      ptr = 0;
      for (;;) {
        from = board.pawn[me][ptr];
        if (from == SquareNone) break;

        add_capt3(from, 15, list, board, opp_flag);
        add_capt3(from, 17, list, board, opp_flag);

// promote
        if (SQUARE_RANK(from) == Rank7) add_capt4(from, 16, list, board);

        ptr++;
      }
    } else {
      // black

      ptr = 0;
      for (;;) {
        from = board.pawn[me][ptr];
        if (from == SquareNone) break;

        add_capt3(from, -17, list, board, opp_flag);
        add_capt3(from, -15, list, board, opp_flag);

// promote
        if (SQUARE_RANK(from) == Rank2) add_capt4(from, -16, list, board);

        ptr++;
      }
    }
  }

  add_quietm1(int from, int dt, list_t list, board_t board) {
    int to = from + dt;
    if (board.square[to] == Empty) LIST_ADD(list, MOVE_MAKE(from, to));
  }

  add_quietm2(int from, int dt, list_t list, board_t board) {
    int to = from + dt;
    for (;;) {
      if (board.square[to] != Empty) break;
      LIST_ADD(list, MOVE_MAKE(from, to));
      to += dt;
    }
  }

  add_quiet_moves(list_t list, board_t board) {
    int me; // int
    int ptr; // int
    int from; // int
    int to; // int
    int piece; // int
    int p;

    me = board.turn;

// piece moves
    ptr = 0;
    for (;;) {
      from = board.piece[me][ptr];
      if (from == SquareNone) break;

      piece = board.square[from];

      p = PIECE_TYPE(piece);

      if (p == Knight64) {
        add_quietm1(from, -33, list, board);
        add_quietm1(from, -31, list, board);
        add_quietm1(from, -18, list, board);
        add_quietm1(from, -14, list, board);
        add_quietm1(from, 14, list, board);
        add_quietm1(from, 18, list, board);
        add_quietm1(from, 31, list, board);
        add_quietm1(from, 33, list, board);
      } else {
        if (p == Bishop64) {
          add_quietm2(from, -17, list, board);
          add_quietm2(from, -15, list, board);
          add_quietm2(from, 15, list, board);
          add_quietm2(from, 17, list, board);
        } else {
          if (p == Rook64) {
            add_quietm2(from, -16, list, board);
            add_quietm2(from, -1, list, board);
            add_quietm2(from, 1, list, board);
            add_quietm2(from, 16, list, board);
          } else {
            if (p == Queen64) {
              add_quietm2(from, -17, list, board);
              add_quietm2(from, -16, list, board);
              add_quietm2(from, -15, list, board);
              add_quietm2(from, -1, list, board);
              add_quietm2(from, 1, list, board);
              add_quietm2(from, 15, list, board);
              add_quietm2(from, 16, list, board);
              add_quietm2(from, 17, list, board);
            } else {
              if (p == King64) {
                add_quietm1(from, -17, list, board);
                add_quietm1(from, -16, list, board);
                add_quietm1(from, -15, list, board);
                add_quietm1(from, -1, list, board);
                add_quietm1(from, 1, list, board);
                add_quietm1(from, 15, list, board);
                add_quietm1(from, 16, list, board);
                add_quietm1(from, 17, list, board);
              } else {
                //ASSERT(510, false);
              }
            }
          }
        }
      }

      ptr++;
    }

// pawn moves
    if (COLOUR_IS_WHITE(me)) {
      ptr = 0;
      for (;;) {
        from = board.pawn[me][ptr];
        if (from == SquareNone) break;

// non promotes
        if (SQUARE_RANK(from) != Rank7) {
          to = from + 16;
          if (board.square[to] == Empty) {
            //ASSERT(511, !SquareIsPromote[to]);
            LIST_ADD(list, MOVE_MAKE(from, to));
            if (SQUARE_RANK(from) == Rank2) {
              to = from + 32;
              if (board.square[to] == Empty) {
                //ASSERT(512, !SquareIsPromote[to]);
                LIST_ADD(list, MOVE_MAKE(from, to));
              }
            }
          }
        }

        ptr++;
      }
    } else {
      // black

      ptr = 0;
      for (;;) {
        from = board.pawn[me][ptr];
        if (from == SquareNone) break;

// non promotes
        if (SQUARE_RANK(from) != Rank2) {
          to = from - 16;
          if (board.square[to] == Empty) {
            //ASSERT(513, !SquareIsPromote[to]);
            LIST_ADD(list, MOVE_MAKE(from, to));
            if (SQUARE_RANK(from) == Rank7) {
              to = from - 32;
              if (board.square[to] == Empty) {
                //ASSERT(514, !SquareIsPromote[to]);
                LIST_ADD(list, MOVE_MAKE(from, to));
              }
            }
          }
        }

        ptr++;
      }
    }
  }

  add_promotes(list_t list, board_t board) {
    int me; // int
    int inc; // int
    int ptr; // int
    int from; // int

    me = board.turn;
    inc = PawnMoveInc[me];

    ptr = 0;
    for (;;) {
      from = board.pawn[me][ptr];
      if (from == SquareNone) break;

      if (PAWN_RANK(from, me) == Rank7) add_capt4(from, inc, list, board);

      ptr++;
    }
  }

  add_en_passant_captures(list_t list, board_t board) {
    int from; // int
    int to; // int
    int me; // int
    int inc; // int
    int pawn; // int

    to = board.ep_square;

    if (to != SquareNone) {
      me = board.turn;

      inc = PawnMoveInc[me];
      pawn = PawnMake[me];

      from = to - (inc - 1);
      if (board.square[from] == pawn) {
        //ASSERT(519, !SquareIsPromote[to]);
        LIST_ADD(list, MOVE_MAKE_FLAGS(from, to, MoveEnPassant));
      }

      from = to - (inc + 1);
      if (board.square[from] == pawn) {
        //ASSERT(520, !SquareIsPromote[to]);
        LIST_ADD(list, MOVE_MAKE_FLAGS(from, to, MoveEnPassant));
      }
    }
  }

  add_castle_moves(list_t list, board_t board) {
    //ASSERT(523, !board_is_check(board));

    if (COLOUR_IS_WHITE(board.turn)) {
      if ((board.flags & FlagsWhiteKingCastle) != 0 &&
          board.square[F1] == Empty &&
          board.square[G1] == Empty &&
          (!is_attacked(board, F1, Black))) {
        LIST_ADD(list, MOVE_MAKE_FLAGS(E1, G1, MoveCastle));
      }

      if ((board.flags & FlagsWhiteQueenCastle) != 0 &&
          board.square[D1] == Empty &&
          board.square[C1] == Empty &&
          board.square[B1] == Empty &&
          (!is_attacked(board, D1, Black))) {
        LIST_ADD(list, MOVE_MAKE_FLAGS(E1, C1, MoveCastle));
      }
    } else {
      // black

      if ((board.flags & FlagsBlackKingCastle) != 0 &&
          board.square[F8] == Empty &&
          board.square[G8] == Empty &&
          (!is_attacked(board, F8, White))) {
        LIST_ADD(list, MOVE_MAKE_FLAGS(E8, G8, MoveCastle));
      }

      if ((board.flags & FlagsBlackQueenCastle) != 0 &&
          board.square[D8] == Empty &&
          board.square[C8] == Empty &&
          board.square[B8] == Empty &&
          (!is_attacked(board, D8, White))) {
        LIST_ADD(list, MOVE_MAKE_FLAGS(E8, C8, MoveCastle));
      }
    }
  }

  add_pawn_move(list_t list, from, to) {
    //ASSERT(525, SQUARE_IS_OK(from));
    //ASSERT(526, SQUARE_IS_OK(to));

    int move = MOVE_MAKE(from, to);

    if (SquareIsPromote[to]) {
      LIST_ADD(list, (move | MovePromoteQueen));
      LIST_ADD(list, (move | MovePromoteKnight));
      LIST_ADD(list, (move | MovePromoteRook));
      LIST_ADD(list, (move | MovePromoteBishop));
    } else
      LIST_ADD(list, move);
  }

  add_promote(list_t list, int move) {
    //ASSERT(528, move_is_ok(move));

    //ASSERT(529, (move & bnotV07777) == 0);
    //ASSERT(530, SquareIsPromote[MOVE_TO(move)]);

    LIST_ADD(list, (move | MovePromoteQueen));
    LIST_ADD(list, (move | MovePromoteKnight));
    LIST_ADD(list, (move | MovePromoteRook));
    LIST_ADD(list, (move | MovePromoteBishop));
  }

  bool move_is_pseudo(int move, board_t board) {
    int me; // int
    int from; // int
    int to; // int
    int piece; // int
    int capture; // int
    int inc; // int
    int delta; // int

    //ASSERT(531, move_is_ok(move));
    //ASSERT(533, !board_is_check(board));

// special cases
    if (MOVE_IS_SPECIAL(move)) return move_is_pseudo_debug(move, board);

    //ASSERT(534, (move & bnotV07777) == 0);

// init
    me = board.turn;
// from
    from = MOVE_FROM(move);
    //ASSERT(535, SQUARE_IS_OK(from));
    piece = board.square[from];
    if (!COLOUR_IS(piece, me)) return false;

    //ASSERT(536, piece_is_ok(piece));

    to = MOVE_TO(move);
    //ASSERT(537, SQUARE_IS_OK(to));

    capture = board.square[to];
    if (COLOUR_IS(capture, me)) return false;

// move
    if (PIECE_IS_PAWN(piece)) {
      if (SquareIsPromote[to]) return false;

      inc = PawnMoveInc[me];
      delta = to - from;
      //ASSERT(538, delta_is_ok(delta));

      if (capture == Empty) {
// pawn push
        if (delta == inc) return true;

        if (delta == (2 * inc) &&
            PAWN_RANK(from, me) == Rank2 &&
            board.square[from + inc] == Empty) {
          return true;
        }
      } else {
// pawn capture
        if (delta == (inc - 1) || delta == (inc + 1)) return true;
      }
    } else {
      if (PIECE_ATTACK(board, piece, from, to)) return true;
    }

    return false;
  }

  bool quiet_is_pseudo(int move, board_t board) {
    int me; // int
    int from; // int
    int to; // int
    int piece; // int
    int inc; // int
    int delta; // int

    //ASSERT(539, move_is_ok(move));
    //ASSERT(541, !board_is_check(board));

// special cases
    if (MOVE_IS_CASTLE(move))
      return move_is_pseudo_debug(move, board);
    else {
      if (MOVE_IS_SPECIAL(move)) return false;
    }

    //ASSERT(542, (move & bnotV07777) == 0);

// init
    me = board.turn;
// from
    from = MOVE_FROM(move);
    //ASSERT(543, SQUARE_IS_OK(from));
    piece = board.square[from];
    if (!COLOUR_IS(piece, me)) return false;

    //ASSERT(544, piece_is_ok(piece));
    to = MOVE_TO(move);
    //ASSERT(545, SQUARE_IS_OK(to));
    if (board.square[to] != Empty) return false; // capture

// move
    if (PIECE_IS_PAWN(piece)) {
      if (SquareIsPromote[to]) return false;

      inc = PawnMoveInc[me];
      delta = to - from;
      //ASSERT(546, delta_is_ok(delta));

// pawn push
      if (delta == inc) return true;

      if (delta == (2 * inc) &&
          PAWN_RANK(from, me) == Rank2 &&
          board.square[from + inc] == Empty) return true;
    } else {
      if (PIECE_ATTACK(board, piece, from, to)) return true;
    }

    return false;
  }

  bool pseudo_is_legal(int move, board_t board) {
    int opp; // int
    int me; // int
    int from; // int
    int to; // int
    int piece; // int
    bool legal; // bool
    int king; // int
    undo_t undo = new undo_t(); //undo_t[1]

    //ASSERT(547, move_is_ok(move));

// init
    me = board.turn;
    opp = COLOUR_OPP(me);

    from = MOVE_FROM(move);
    to = MOVE_TO(move);

    piece = board.square[from];
    //ASSERT(549, COLOUR_IS(piece, me));

// slow test for en-passant captures
    if (MOVE_IS_EN_PASSANT(move)) {
      move_do(board, move, undo);
      legal = !IS_IN_CHECK(board, me);
      move_undo(board, move, undo);
      return legal;
    }

// king moves (including castle)
    if (PIECE_IS_KING(piece)) {
      return !is_attacked(board, to, opp);
    }

// pins
    if (is_pinned(board, from, me)) {
      king = KING_POS(board, me);
      return (DELTA_INC_LINE(king - to) ==
          DELTA_INC_LINE(king - from)); // does not discover the line
    }

    return true;
  }

  bool move_is_pseudo_debug(int move, board_t board) {
    list_t list = new list_t(); //list_t[1]

    //ASSERT(552, move_is_ok(move));

    //ASSERT(554, !board_is_check(board));

    gen_moves(list, board);

    return list_contain(list, move);
  }

  option_init() {
    for (int i = 0; i <= 20; i++) Option.add(new opt_t_def());

// options are as they are for the execuatable version
    set_opt_t_def(0, "Hash", false, "16", "spin", "min 4 max 1024");
    set_opt_t_def(1, "Ponder", false, "false", "check", "");
    set_opt_t_def(2, "OwnBook", false, "false", "check", "");
    set_opt_t_def(3, "BookFile", false, "book_small.bin", "string", "");
    set_opt_t_def(4, "nullMove Pruning", true, "Fail High", "combo",
        "var Always var Fail High var Never");
    set_opt_t_def(5, "nullMove Reduction", true, "3", "spin", "min 1 max 3");
    set_opt_t_def(6, "Verification Search", true, "endgame", "combo",
        "var Always var endgame var Never");
    set_opt_t_def(
        7, "Verification Reduction", true, "5", "spin", "min 1 max 6");
    set_opt_t_def(8, "History Pruning", true, "true", "check", "");
    set_opt_t_def(9, "History Threshold", true, "60", "spin", "min 0 max 100");
    set_opt_t_def(10, "Futility Pruning", true, "false", "check", "");
    set_opt_t_def(11, "Futility Margin", true, "100", "spin", "min 0 max 500");
    set_opt_t_def(12, "Delta Pruning", true, "false", "check", "");
    set_opt_t_def(13, "Delta Margin", true, "50", "spin", "min 0 max 500");
    set_opt_t_def(
        14, "Quiescence Check Plies", true, "1", "spin", "min 0 max 2");
    set_opt_t_def(15, "Material", true, "100", "spin", "min 0 max 400");
    set_opt_t_def(16, "Piece Activity", true, "100", "spin", "min 0 max 400");
    set_opt_t_def(17, "King Safety", true, "100", "spin", "min 0 max 400");
    set_opt_t_def(18, "Pawn Structure", true, "100", "spin", "min 0 max 400");
    set_opt_t_def(19, "Passed Pawns", true, "100", "spin", "min 0 max 400");
    set_opt_t_def(20, "", false, "", "", "");
  }

  option_list() {
    late opt_t_def opt;

    for (int i = 0;; i++) {
      opt = Option[i];
      if (opt.vary.length == 0) break;

      if (opt.decl) {
        send("option name " +
            opt.vary +
            " type " +
            opt.type +
            " default " +
            opt.val +
            opt.extra);
      }
    }
  }

  bool option_set(String vary, String val) {
    int i = option_find(vary);
    if (i < 0) return false;

    Option[i].val = val;

    return true;
  }

  String option_get(String vary) {
    int i = option_find(vary);
    if (i < 0) {
      my_fatal("option_get(): unknown option : " + vary + "\n");
      return "";
    }

    return Option[i].val;
  }

  bool option_get_bool(String vary) {
    String val = option_get(vary); // string

    if (string_equal(val, "true") ||
        string_equal(val, "yes") ||
        string_equal(val, "1")) {
      return true;
    } else {
      if (string_equal(val, "false") ||
          string_equal(val, "no") ||
          string_equal(val, "0")) {
        return false;
      }
    }

    //ASSERT(558, false);
    return false;
  }

  int option_get_int(String vary) {
    return int.parse(option_get(vary));
  }

  String option_get_string(String vary) {
    return option_get(vary);
  }

  int option_find(String vary) {
    late opt_t_def opt;

    for (int i = 0;; i++) {
      opt = Option[i];
      if (opt.vary.length == 0) break;

      if (string_equal(opt.vary, vary)) return i;
    }

    return -1;
  }

  pawn_init_bit() {
    int rank; // int
    int first; // int
    int last; // int
    int count; // int
    int b; // int
    int rev; // int

// rank-indexed Bit*[]

    for (rank = Rank1; rank <= Rank8; rank++) {
      BitEQ[rank] = (1 << (rank - Rank1));
      BitLT[rank] = BitEQ[rank] - 1;
      BitLE[rank] = (BitLT[rank] | BitEQ[rank]);
      BitGT[rank] = (BitLE[rank] ^ 0xFF);
      BitGE[rank] = (BitGT[rank] | BitEQ[rank]);
    }

    for (rank = Rank1; rank <= Rank8; rank++) {
      BitRank1[rank] = BitEQ[rank + 1];
      BitRank2[rank] = (BitEQ[rank + 1] | BitEQ[rank + 2]);
      BitRank3[rank] = ((BitEQ[rank + 1] | BitEQ[rank + 2]) | BitEQ[rank + 3]);
    }

// bit-indexed Bit*[]

    for (b = 0; b <= 0x100 - 1; b++) {
      first = Rank8;
      last = Rank1;
      count = 0;
      rev = 0;

      for (rank = Rank1; rank <= Rank8; rank++) {
        if ((b & BitEQ[rank]) != 0) {
          if (rank < first) first = rank;
          if (rank > last) last = rank;
          count++;
          rev |= BitEQ[RANK_OPP(rank)];
        }
      }

      BitFirst[b] = first;
      BitLast[b] = last;
      BitCount[b] = count;
      BitRev[b] = rev;
    }
  }

  pawn_init() {
// UCI options
    PawnStructureWeight = (option_get_int("Pawn Structure") * 256 + 50) ~/ 100;

// bonus
    Bonus[Rank4] = 26;
    Bonus[Rank5] = 77;
    Bonus[Rank6] = 154;
    Bonus[Rank7] = 256;

// pawn hash-table
    Pawn.size = 0;
    Pawn.mask = 0;
  }

  pawn_alloc() {
    if (UseTable) {
      Pawn.size = PawnTableSize;
      Pawn.mask = Pawn.size - 1; // 2^x -1
// Pawn.table = (entry_t *) my_malloc(Pawn.size*sizeof(entry_t));
      pawn_clear();
    }
  }

  pawn_clear() {
    Pawn.table = [];
    for (int i = 0; i < Pawn.size; i++) Pawn.table.add(pawn_info_t());

    Pawn.used = 0;
    Pawn.read_nb = 0;
    Pawn.read_hit = 0;
    Pawn.write_nb = 0;
    Pawn.write_collision = 0;
  }

  pawn_get_info(pawn_info_t info, board_t board) {
    int key = 0; // uint64
    pawn_info_t entry = new pawn_info_t();
    int index;

// probe
    if (UseTable) {
      Pawn.read_nb++;

      key = board.pawn_key;
      index = (KEY_INDEX(key) & Pawn.mask);

      entry = Pawn.table[index];

      if (entry.lock == KEY_LOCK(key)) {
// found
        Pawn.read_hit++;
        pawn_info_copy(info, entry);
        return;
      }
    }

// calculation
    pawn_comp_info(info, board);

// store
    if (UseTable) {
      Pawn.write_nb++;

      if (entry.lock == 0)
        Pawn.used++; // assume free entry
      else
        Pawn.write_collision++;

      pawn_info_copy(entry, info);
      entry.lock = KEY_LOCK(key);
    }
  }

  pawn_comp_info(pawn_info_t info, board_t board) {
    int colour; // int
    int file; // int
    int rank; // int
    int me; // int
    int opp; // int
    int ptr; // int
    int sq; // int
    bool backward; // bool
    bool candidate; // bool
    bool doubled; // bool
    bool isolated; // bool
    bool open; // bool
    int t1; // int
    int t2; // int
    int n; // int
    int bits; // int
    List<int> opening = [0, 0]; // int[ColourNb]
    List<int> endgame = [0, 0]; // int[ColourNb]
    List<int> flags = [0, 0]; // int[ColourNb]
    List<int> file_bits = [0, 0]; // int[ColourNb]
    List<int> passed_bits = [0, 0]; // int[ColourNb]
    List<int> single_file = [0, 0]; // int[ColourNb]
    int q;
    int om;
    int em;

// pawn_file[]

    for (colour = 0; colour <= 1; colour++) {
      List<int> pawn_file = List.filled(FileNb, 0); // int[FileNb]

      me = colour;
      for (file = 0; file < FileNb; file++) pawn_file[file] = 0;

      ptr = 0;
      for (;;) {
        sq = board.pawn[me][ptr];
        if (sq == SquareNone) break;

        file = SQUARE_FILE(sq);
        rank = PAWN_RANK(sq, me);
        //ASSERT(565, file >= FileA && file <= FileH);
        //ASSERT(566, rank >= Rank2 && rank <= Rank7);
        pawn_file[file] = (pawn_file[file] | BitEQ[rank]);

        ptr++;
      }

      for (file = 0; file < FileNb; file++) {
        if (board.pawn_file[colour][file] != pawn_file[file])
          my_fatal("board.pawn_file[][]");
      }
    }

// features && scoring

    for (colour = 0; colour <= 1; colour++) {
      me = colour;
      opp = COLOUR_OPP(me);

      ptr = 0;
      for (;;) {
        sq = board.pawn[me][ptr];
        if (sq == SquareNone) break;
// init
        file = SQUARE_FILE(sq);
        rank = PAWN_RANK(sq, me);
        //ASSERT(567, file >= FileA && file <= FileH);
        //ASSERT(568, rank >= Rank2 && rank <= Rank7);

// flags
        file_bits[me] |= BitEQ[file];
        if (rank == Rank2) flags[me] |= BackRankFlag;

// features
        backward = false;
        candidate = false;
        doubled = false;
        isolated = false;
        open = false;

        t1 = (board.pawn_file[me][file - 1] | board.pawn_file[me][file + 1]);
        t2 = (board.pawn_file[me][file] | BitRev[board.pawn_file[opp][file]]);

// doubled
        if ((board.pawn_file[me][file] & BitLT[rank]) != 0) doubled = true;

// isolated && backward
        if (t1 == 0)
          isolated = true;
        else {
          if ((t1 & BitLE[rank]) == 0) {
            backward = true;

// really backward?
            if ((t1 & BitRank1[rank]) != 0) {
              //ASSERT(569, rank + 2 <= Rank8);
              q = (t2 & BitRank1[rank]);
              q |= BitRev[board.pawn_file[opp][file - 1]];
              q |= BitRev[board.pawn_file[opp][file + 1]];

              if ((q & BitRank2[rank]) == 0) backward = false;
            } else {
              if (rank == Rank2 && ((t1 & BitEQ[rank + 2]) != 0)) {
                //ASSERT(570, rank + 3 <= Rank8);
                q = (t2 & BitRank2[rank]);
                q |= BitRev[board.pawn_file[opp][file - 1]];
                q |= BitRev[board.pawn_file[opp][file + 1]];

                if ((q & BitRank3[rank]) == 0) backward = false;
              }
            }
          }
        }

// open, candidate && passed
        if ((t2 & BitGT[rank]) == 0) {
          open = true;

          q = (BitRev[board.pawn_file[opp][file - 1]] |
              BitRev[board.pawn_file[opp][file + 1]]);

          if ((q & BitGT[rank]) == 0)
            passed_bits[me] |= BitEQ[file];
          else {
// candidate?
            n = 0;
            n += BitCount[(board.pawn_file[me][file - 1] & BitLE[rank])];
            n += BitCount[(board.pawn_file[me][file + 1] & BitLE[rank])];
            n -= BitCount[
                (BitRev[board.pawn_file[opp][file - 1]] & BitGT[rank])];
            n -= BitCount[
                (BitRev[board.pawn_file[opp][file + 1]] & BitGT[rank])];

            if (n >= 0) {
// safe?
              n = 0;
              n += BitCount[(board.pawn_file[me][file - 1] & BitEQ[rank - 1])];
              n += BitCount[(board.pawn_file[me][file + 1] & BitEQ[rank - 1])];
              n -= BitCount[
                  (BitRev[board.pawn_file[opp][file - 1]] & BitEQ[rank + 1])];
              n = BitCount[
                  (BitRev[board.pawn_file[opp][file + 1]] & BitEQ[rank + 1])];

              if (n >= 0) candidate = true;
            }
          }
        }

// score
        om = opening[me];
        em = endgame[me];

        if (doubled) {
          om -= doubledOpening;
          em -= doubledEndgame;
        }

        if (isolated) {
          if (open) {
            om -= IsolatedOpeningOpen;
            em -= IsolatedEndgame;
          } else {
            om -= IsolatedOpening;
            em -= IsolatedEndgame;
          }
        }

        if (backward) {
          if (open) {
            om -= BackwardOpeningOpen;
            em -= BackwardEndgame;
          } else {
            om -= BackwardOpening;
            em -= BackwardEndgame;
          }
        }

        if (candidate) {
          om += quad(CandidateOpeningMin, CandidateOpeningMax, rank);
          em += quad(CandidateEndgameMin, CandidateEndgameMax, rank);
        }

        opening[me] = om;
        endgame[me] = em;
        ptr++;
      }
    }

// store info
    info.opening =
        ((opening[White] - opening[Black]) * PawnStructureWeight) ~/ 256;
    info.endgame =
        ((endgame[White] - endgame[Black]) * PawnStructureWeight) ~/ 256;

    for (colour = 0; colour <= 1; colour++) {
      me = colour;
      opp = COLOUR_OPP(me);

// draw flags
      bits = file_bits[me];

      if (bits != 0 && ((bits & bits - 1) == 0)) {
        // one set bit

        file = BitFirst[bits];
        rank = BitFirst[board.pawn_file[me][file]];
        //ASSERT(571, rank >= Rank2);

        q = (BitRev[board.pawn_file[opp][file - 1]] |
            BitRev[board.pawn_file[opp][file + 1]]);

        if ((q & BitGT[rank]) == 0) {
          rank = BitLast[board.pawn_file[me][file]];
          single_file[me] = SQUARE_MAKE(file, rank);
        }
      }

      info.flags[colour] = flags[colour];
      info.passed_bits[colour] = passed_bits[colour];
      info.single_file[colour] = single_file[colour];
    }
  }

  int quad(int y_min, int y_max, int x) {
    //ASSERT(572, y_min >= 0 && y_min <= y_max && y_max <= 32767);
    //ASSERT(573, x >= Rank2 && x <= Rank7);
    int y = (y_min + ((y_max - y_min) * Bonus[x] + 128) ~/ 256).floor();
    //ASSERT(574, y >= y_min && y <= y_max);
    return y;
  }

  piece_init() {
    int piece; // int
    int piece_12; // int

// PieceTo12[], PieceOrder[], PieceInc[]

    for (piece = 0; piece < PieceNb; piece++) {
      PieceInc.add(List.filled(9, 0));
    }

    for (piece_12 = 0; piece_12 <= 11; piece_12++) {
      PieceTo12[PieceFrom12[piece_12]] = piece_12;
      PieceOrder[PieceFrom12[piece_12]] = (piece_12 >>> 1);
    }

    PieceInc[WhiteKnight256] = KnightInc;
    PieceInc[WhiteBishop256] = BishopInc;
    PieceInc[WhiteRook256] = RookInc;
    PieceInc[WhiteQueen256] = QueenInc;
    PieceInc[WhiteKing256] = KingInc;

    PieceInc[BlackKnight256] = KnightInc;
    PieceInc[BlackBishop256] = BishopInc;
    PieceInc[BlackRook256] = RookInc;
    PieceInc[BlackQueen256] = QueenInc;
    PieceInc[BlackKing256] = KingInc;
  }

  bool piece_is_ok(int piece) {
    if (piece < 0 || piece >= PieceNb || PieceTo12[piece] < 0) return false;

    return true;
  }

  String piece_to_char(int piece) {
    //ASSERT(576, piece_is_ok(piece));
    return PieceString[PieceTo12[piece]];
  }

  int piece_from_char(String c) {
    int ptr = PieceString.indexOf(c); // int
    if (ptr < 0) return PieceNone256;
    //ASSERT(575, ptr >= 0 && ptr < 12);
    return PieceFrom12[ptr];
  }

  search_clear() {
    SearchInput.infinite = false;
    SearchInput.depth_is_limited = false;
    SearchInput.depth_limit = 0;
    SearchInput.time_is_limited = false;
    SearchInput.time_limit_1 = 0.0;
    SearchInput.time_limit_2 = 0.0;

    SearchInfo.can_stop = false;
    SearchInfo.stop = false;
    SearchInfo.check_nb = 10000; // was 100000
    SearchInfo.check_inc = 10000; // was 100000
    SearchInfo.last_time = 0.0;

    SearchBest.move = MoveNone;
    SearchBest.value = 0;
    SearchBest.flags = SearchUnknown;
    SearchBest.pv[0] = MoveNone;

    SearchRoot.depth = 0;
    SearchRoot.move = MoveNone;
    SearchRoot.move_pos = 0;
    SearchRoot.move_nb = 0;
    SearchRoot.last_value = 0;
    SearchRoot.bad_1 = false;
    SearchRoot.bad_2 = false;
    SearchRoot.change = false;
    SearchRoot.easy = false;
    SearchRoot.flag = false;

    SearchCurrent.mate = 0;
    SearchCurrent.depth = 0;
    SearchCurrent.max_depth = 0;
    SearchCurrent.node_nb = 0;
    SearchCurrent.time = 0.0;
    SearchCurrent.speed = 0.0;
  }

  setstartpos() {
    Init = false;
    search_clear();
    board_from_fen(SearchInput.board, StartFen);
  }

  int trans_age(trans_t trans, int date) {
    int age; // int

    //ASSERT(908, date >= 0 && date < DateSize);
    age = trans.date - date;
    if (age < 0) age += DateSize;
    //ASSERT(909, age >= 0 && age < DateSize);
    return age;
  }

  bool entry_is_ok(entry_t entry) {
    if (entry.date >= DateSize) return false;
    if (entry.move == MoveNone && entry.move_depth != DepthNone) return false;
    if (entry.move != MoveNone && entry.move_depth == DepthNone) return false;
    if (entry.min_value == -ValueInf && entry.min_depth != DepthNone)
      return false;
    if (entry.min_value > -ValueInf && entry.min_depth == DepthNone)
      return false;
    if (entry.max_value == ValueInf && entry.max_depth != DepthNone)
      return false;
    if (entry.max_value < ValueInf && entry.max_depth == DepthNone)
      return false;

    return true;
  }

  bool trans_is_ok(trans_t trans) {
    int date; // int

    if (trans.size == 0) return false;
    if ((trans.mask == 0) || (trans.mask >= trans.size)) return false;
    if (trans.date >= DateSize) return false;

    for (date = 0; date < DateSize; date++) {
      if (trans.age[date] != trans_age(trans, date)) return false;
    }

    return true;
  }

  trans_cl_I(trans_t trans, int index) {
    entry_t clear_entry = trans.table[index];

    clear_entry.lock = 0;
    clear_entry.move = MoveNone;
    clear_entry.depth = DepthNone;
    clear_entry.date = trans.date;
    clear_entry.move_depth = DepthNone;
    clear_entry.flags = 0;
    clear_entry.min_depth = DepthNone;
    clear_entry.max_depth = DepthNone;
    clear_entry.min_value = -ValueInf;
    clear_entry.max_value = ValueInf;

    //ASSERT(903, entry_is_ok(clear_entry));
  }

  trans_set_date(trans_t trans, int date) {
    int date1;
    //ASSERT(906, date >= 0 && date < DateSize);
    trans.date = date;

    trans.age = [];
    for (date1 = 0; date1 < DateSize; date1++)
      trans.age.add(trans_age(trans, date1));

    trans.used = 0;
    trans.read_nb = 0;
    trans.read_hit = 0;
    trans.write_nb = 0;
    trans.write_hit = 0;
    trans.write_collision = 0;
  }

  trans_clear(trans_t trans) {
    trans_set_date(trans, 0);
    trans.table = []; // will define objects while searching
    for (int i = 0; i < trans.size; i++) trans.table.add(new entry_t());
  }

  trans_alloc(trans_t trans) {
    trans.size = TransSize;
    trans.mask = trans.size - 1; // 2^x -1
    trans_clear(trans);
    //ASSERT(900, trans_is_ok(trans));
  }

  inits() {
    if (!Init) {
// late initialisation
      Init = true;

      if (option_get_bool("OwnBook")) {
//   book_open(option_get_string("BookFile"));
        send("Sorry, no book.");
      }

      trans_alloc(Trans);

      pawn_init();
      pawn_alloc();

      material_init();
      material_alloc();

      pst_init();
      eval_init();
    }
  }

  do_input(String cmd) {
    bool ifelse = true;

// parse
    if (ifelse && string_start_with(cmd, "go")) {
      inits();

      parse_go(cmd);

      ifelse = false;
    }

    if (ifelse && string_equal(cmd, "isready")) {
      inits();
      send("readyok");

      ifelse = false;
    }

    if (ifelse && string_start_with(cmd, "position ")) {
      inits();
      parse_position(cmd);

      ifelse = false;
    }

    if (ifelse && string_start_with(cmd, "setoption ")) {
      parse_setoption(cmd);

      ifelse = false;
    }

    if (ifelse && string_equal(cmd, "help")) {
      send(
          "supports commands: setposition fen, setposition moves, go depth, go movetime ");

// option_list();

      ifelse = false;
    }
  }

  ClearAll() {
    // just clear all to be sure that nothing left

    search_clear();
    trans_clear(Trans);
    pawn_clear();
    material_clear();
  }

  int trans_entry(trans_t trans, int key) {
    // index to entry_t
    int index; // uint32

    //ASSERT(929, trans_is_ok(trans));

    if (UseModulo) {
      index = KEY_INDEX(key) % (trans.mask + 1);
    } else {
      index = (KEY_INDEX(key) & trans.mask);
    }

    //ASSERT(930, index <= trans.mask);
    return index;
  }

  trans_inc_date(trans_t trans) {
    trans_set_date(trans, (trans.date + 1) % DateSize);
  }

  trans_store(trans_t trans, key, move, depth, trans_rtrv Tset) {
    late entry_t entry; // entry_t *
    late entry_t best_entry; // entry_t *
    int ei; // int
    int i; // int
    int score; // int
    int best_score; // int
    bool nw_rc = false;

    //ASSERT(910, trans_is_ok(trans));
    //ASSERT(911, move >= 0 && move < 65536);
    //ASSERT(912, depth >= -127 && depth <= 127);
    //ASSERT(913, Tset.trans_min_value >= -ValueInf && Tset.trans_min_value <= ValueInf);
    //ASSERT(914, Tset.trans_max_value >= -ValueInf && Tset.trans_max_value <= ValueInf);
    //ASSERT(915, Tset.trans_min_value <= Tset.trans_max_value);

// init
    trans.write_nb++;

// probe
    best_score = -32767;

    ei = trans_entry(trans, key);

    for (i = 0; i < ClusterSize && (ei + i) < trans.size; i++) {
      entry = trans.table[ei + i];

      if (entry.lock != 0) {
        if (entry.lock == KEY_LOCK(key)) {
// hash hit => update existing entry

          trans.write_hit++;
          if (entry.date != trans.date) trans.used++;

          entry.date = trans.date;

          if (depth > entry.depth)
            entry.depth = depth; // for replacement scheme

          if (move != MoveNone && depth >= entry.move_depth) {
            entry.move_depth = depth;
            entry.move = move;
          }

          if (Tset.trans_min_value > -ValueInf && depth >= entry.min_depth) {
            entry.min_depth = depth;
            entry.min_value = Tset.trans_min_value;
          }

          if (Tset.trans_max_value < ValueInf && depth >= entry.max_depth) {
            entry.max_depth = depth;
            entry.max_value = Tset.trans_max_value;
          }

          //ASSERT(916, entry_is_ok(entry));
          return;
        }
      } else {
        trans_cl_I(trans, ei + i); // create a new entry record
        nw_rc = true;

        entry = trans.table[ei + i];
      }

// evaluate replacement score

      score = (trans.age[entry.date] * 256) - entry.depth;
      //ASSERT(917, score > -32767);

      if (score > best_score) {
        best_entry = entry;
        best_score = score;
      }

      if (nw_rc) break;
    }

// "best" entry found
    entry = best_entry;

    //ASSERT(919, entry.lock != KEY_LOCK(key));

    if (entry.lock != 0) {
      // originally entry.date == trans.date
      trans.write_collision++;
    } else {
      trans.used++;
    }

// store
    entry.lock = KEY_LOCK(key);
    entry.date = trans.date;

    entry.depth = depth;

    entry.move_depth = (move != MoveNone ? depth : DepthNone);
    entry.move = move;

    entry.min_depth = (Tset.trans_min_value > -ValueInf ? depth : DepthNone);
    entry.max_depth = (Tset.trans_max_value < ValueInf ? depth : DepthNone);
    entry.min_value = Tset.trans_min_value;
    entry.max_value = Tset.trans_max_value;

    //ASSERT(921, entry_is_ok(entry));
  }

  trans_retrieve(trans_t trans, key, trans_rtrv Ret) {
    late entry_t entry; // entry_t *
    int ei; // int
    int i; // int

    //ASSERT(922, trans_is_ok(trans));

// init
    trans.read_nb++;

// probe
    ei = trans_entry(trans, key);

    for (i = 0; i < ClusterSize && (ei + i) < trans.size; i++) {
      entry = trans.table[ei + i];

      if (entry.lock == KEY_LOCK(key)) {
// found

        trans.read_hit++;
        if (entry.date != trans.date) entry.date = trans.date;

        Ret.trans_move = entry.move;

        Ret.trans_min_depth = entry.min_depth;
        Ret.trans_max_depth = entry.max_depth;
        Ret.trans_min_value = entry.min_value;
        Ret.trans_max_value = entry.max_value;

        return true;
      }
    }

// not found
    return false;
  }

  trans_stats(trans_t trans) {
    int full;
    int hit;
    int collision;
    String s = "";

    //ASSERT(928, trans_is_ok(trans));

    full = (trans.size > 0 ? (100 * trans.used) ~/ trans.size : 0);
    hit = (trans.read_nb > 0 ? (100 * trans.read_hit) ~/ trans.read_nb : 0);
    collision = (trans.write_nb > 0
        ? (100 * trans.write_collision) ~/ trans.write_nb
        : 0);

    s += "\n" + "hash trans info";
    s += " hashfull " + full.toString() + "%";
    s += " hits " + hit.toString() + "%";
    s += " collisions " + collision.toString() + "%";

    full = (Material.size > 0 ? (100 * Material.used) ~/ Material.size : 0);
    hit = (Material.read_nb > 0
        ? (100 * Material.read_hit) ~/ Material.read_nb
        : 0);
    collision = (Material.write_nb > 0
        ? (100 * Material.write_collision) ~/ Material.write_nb
        : 0);

    s += "\n" + "hash material info";
    s += " hashfull " + full.toString() + "%";
    s += " hits " + hit.toString() + "%";
    s += " collisions " + collision.toString() + "%";

    full = (Pawn.size > 0 ? (100 * Pawn.used) ~/ Pawn.size : 0);
    hit = (Pawn.read_nb > 0 ? (100 * Pawn.read_hit) ~/ Pawn.read_nb : 0);
    collision =
        (Pawn.write_nb > 0 ? (100 * Pawn.write_collision) ~/ Pawn.write_nb : 0);

    s += "\n" + "hash pawn info";
    s += " hashfull " + full.toString() + "%";
    s += " hits " + hit.toString() + "%";
    s += " collisions " + collision.toString() + "%";
    s += "\n";

    send(s);
  }

  parse_go(String cmd) {
    String cmd1 = ""; // string
    String cmd2 = ""; // string
    bool infinite = false; // bool
    int depth = -1; // int
    double movetime = -1.0; // int
    bool ifelse;
    string_t save_board = new string_t();

// parse
    cmd1 = str_after_ok(cmd, " "); // skip "go"
    cmd2 = str_after_ok(cmd1, " "); // value
    cmd1 = str_before_ok(cmd1 + " ", " ");

    ifelse = true;
    if (ifelse && string_equal(cmd1, "depth")) {
      depth = int.parse(cmd2);
      //ASSERT(590, depth >= 0);

      ifelse = false;
    }

    if (ifelse && string_equal(cmd1, "infinite")) {
      infinite = true;

      ifelse = false;
    }

    if (ifelse && string_equal(cmd1, "movetime")) {
      movetime = double.parse(cmd2);
      //ASSERT(593, movetime >= 0.0);

      ifelse = false;
    }

    if (ifelse) {
      movetime = 10; // Otherwise constantly 10 secs

      ifelse = false;
    }

// init
    ClearAll();

// depth limit
    if (depth >= 0) {
      SearchInput.depth_is_limited = true;
      SearchInput.depth_limit = depth;
    }

// time limit
    if (movetime >= 0.0) {
// fixed time
      SearchInput.time_is_limited = true;
      SearchInput.time_limit_1 = movetime;
      SearchInput.time_limit_2 = movetime;
    }

    if (infinite) SearchInput.infinite = true;

// search
    if (!ShowInfo) {
      send("Thinking (ShowInfo=false)...");
    }

    board_to_fen(SearchInput.board, save_board); // save board for sure

    search();
    search_update_current();

    board_from_fen(SearchInput.board, save_board.v); // && restore after search

    send_best_move();
  }

  parse_position(String cmd) {
    String cmd1 = ""; // string
    String cmd2 = ""; // string
    int mc;

    string_t move_string = new string_t(); // string

    int move; // int
    undo_t undo = new undo_t(); // undo_t[1]
    String mnext = "";

    cmd1 = str_after_ok(cmd, " "); // skip "position"
    cmd2 = str_after_ok(cmd1, " "); // value

// start position
    if (string_start_with(cmd1, "fen")) {
      // "fen" present

      board_from_fen(SearchInput.board, cmd2);
    } else {
      if (string_start_with(cmd1, "moves")) {
        // "moves" present

        board_from_fen(SearchInput.board, StartFen);

        mc = 0;
        mnext = cmd2;
        for (;;) {
          if (mnext.length == 0) break;

          move_string.v =
              (mnext.indexOf(" ") < 0 ? mnext : str_before_ok(mnext, " "));

          move = move_from_string(move_string, SearchInput.board);

          move_do(SearchInput.board, move, undo);

          mnext = str_after_ok(mnext, " ");

          mc++;
        }

        SearchInput.board.movenumb = 1 + (mc >>> 1);
      } else {
// assumes startpos

        board_from_fen(SearchInput.board, StartFen);
      }
    }
  }

  parse_setoption(String cmd) {
    String cmd1 = ""; // string

    String name = ""; // string
    String value = ""; // string

    cmd1 = str_after_ok(cmd, " "); // skip "setoption"

    name = str_after_ok(cmd1, "name ");
    name = str_before_ok(name + " ", " ");

    value = str_after_ok(cmd1, "value ");
    value = str_before_ok(value + " ", " ");

    if (name.length > 0 && value.length > 0) {
// update
      option_set(name, value);
    }

// update transposition-table size if needed
    if (Init && string_equal(name, "Hash")) {
      // Init => already allocated

      if (option_get_int("Hash") >= 4) {
        trans_alloc(Trans);
      }
    }
  }

  send_ndtm(int ch) {
    String s = "info";
    String s2 = "";

    if (ch > 5) {
      s += " depth " + SearchCurrent.depth.toString();
      s += " seldepth " + SearchCurrent.max_depth.toString() + " ";
    }

    if (ch >= 20 && ch <= 22) {
      s2 += " score mate " + SearchCurrent.mate.toString() + " ";
    }
    if (ch == 11 || ch == 21) {
      s2 += "lowerbound ";
    }
    if (ch == 12 || ch == 22) {
      s2 += "upperbound ";
    }

    s += " " + s2 + "time " + SearchCurrent.time.toInt().toString() + "s";
    s += " nodes " + SearchCurrent.node_nb.toInt().toString();
    s += " nps " + SearchCurrent.speed.toInt().toString();

    send(s);
  }

  send_best_move() {
    string_t move_string = new string_t(); // string

    int move; // int

// info
    send_ndtm(1);

    trans_stats(Trans);

    move = SearchBest.move; // best move

    move_to_string(move, move_string);

    bestmv = move_string.v;

    format_best_mv2(move);
  }

// move for pgn
  format_best_mv2(int move) {
    int piece;
    String piecech = "";
    String mvattr = "";
    String promos = "";
    String ckmt = "";
    board_t board = SearchInput.board;

    if (MOVE_IS_CASTLE(move)) {
      bestmv2 = (bestmv[2] == "g" ? "0-0" : "0-0-0");
    } else {
      piece = board.square[MOVE_FROM(move)];
      if ((!piece_is_ok(piece)) || piece == PieceNone64) {
        piece = board.square[MOVE_TO(move)];
      }

      piecech = (piece_to_char(piece)).toUpperCase();
      if (piecech == "P") piecech = "";

      mvattr = (move_is_capture(move, board) ? "x" : "-");

      if (bestmv.length > 4) promos = bestmv[4];

      if (move_is_check(move, board)) ckmt = "+";

      bestmv2 = piecech +
          substr(bestmv, 0, 2) +
          mvattr +
          substr(bestmv, 2, 2) +
          promos +
          ckmt;
    }
  }

  pst_init() {
    int i; // int
    int piece; // int
    int sq; // int
    int stage; // int

// UCI options
    PieceActivityWeight = (option_get_int("Piece Activity") * 256 + 50) ~/ 100;
    KingSafetyWeight = (option_get_int("King Safety") * 256 + 50) ~/ 100;
    PawnStructureWeight = (option_get_int("Pawn Structure") * 256 + 50) ~/ 100;

// init
    for (piece = 0; piece <= 11; piece++) {
      Pst.add([]);
      for (sq = 0; sq <= 63; sq++) {
        Pst[piece].add(List.filled(StageNb, 0));

        for (stage = 0; stage < StageNb; stage++) {
          Pset(piece, sq, stage, 0);
        }
      }
    }

// pawns
    piece = WhitePawn12;

// file
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, PawnFile[square_file(sq)] * PawnFileOpening);
    }

// centre control
    Padd(piece, pD3, Opening, 10);
    Padd(piece, pE3, Opening, 10);

    Padd(piece, pD4, Opening, 20);
    Padd(piece, pE4, Opening, 20);

    Padd(piece, pD5, Opening, 10);
    Padd(piece, pE5, Opening, 10);

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, PawnStructureWeight ~/ 256);
      Pmul(piece, sq, Endgame, PawnStructureWeight ~/ 256);
    }

// knights
    piece = WhiteKnight12;

// centre
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening,
          KnightLine[square_file(sq)] * KnightCentreOpening);
      Padd(piece, sq, Opening,
          KnightLine[square_rank(sq)] * KnightCentreOpening);
      Padd(piece, sq, Endgame,
          KnightLine[square_file(sq)] * KnightCentreEndgame);
      Padd(piece, sq, Endgame,
          KnightLine[square_rank(sq)] * KnightCentreEndgame);
    }

// rank
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, KnightRank[square_rank(sq)] * KnightRankOpening);
    }

// back rank
    for (sq = pA1; sq <= pH1; sq++) {
      // only first rank
      Padd(piece, sq, Opening, -KnightBackRankOpening);
    }

// "trapped"
    Padd(piece, pA8, Opening, -KnightTrapped);
    Padd(piece, pH8, Opening, -KnightTrapped);

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, PieceActivityWeight ~/ 256);
      Pmul(piece, sq, Endgame, PieceActivityWeight ~/ 256);
    }

// bishops
    piece = WhiteBishop12;

// centre
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening,
          BishopLine[square_file(sq)] * BishopCentreOpening);
      Padd(piece, sq, Opening,
          BishopLine[square_rank(sq)] * BishopCentreOpening);
      Padd(piece, sq, Endgame,
          BishopLine[square_file(sq)] * BishopCentreEndgame);
      Padd(piece, sq, Endgame,
          BishopLine[square_rank(sq)] * BishopCentreEndgame);
    }

// back rank
    for (sq = pA1; sq <= pH1; sq++) {
      // only first rank
      Padd(piece, sq, Opening, -BishopBackRankOpening);
    }

// main diagonals
    for (i = 0; i <= 7; i++) {
      sq = square_make(i, i);
      Padd(piece, sq, Opening, BishopDiagonalOpening);
      Padd(piece, square_opp(sq), Opening, BishopDiagonalOpening);
    }

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, PieceActivityWeight ~/ 256);
      Pmul(piece, sq, Endgame, PieceActivityWeight ~/ 256);
    }

// rooks
    piece = WhiteRook12;

// file
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, RookFile[square_file(sq)] * RookFileOpening);
    }

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, PieceActivityWeight ~/ 256);
      Pmul(piece, sq, Endgame, PieceActivityWeight ~/ 256);
    }

// queens
    piece = WhiteQueen12;

// centre
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, QueenLine[square_file(sq)] * QueenCentreOpening);
      Padd(piece, sq, Opening, QueenLine[square_rank(sq)] * QueenCentreOpening);
      Padd(piece, sq, Endgame, QueenLine[square_file(sq)] * QueenCentreEndgame);
      Padd(piece, sq, Endgame, QueenLine[square_rank(sq)] * QueenCentreEndgame);
    }

// back rank
    for (sq = pA1; sq <= pH1; sq++) {
      // only first rank
      Padd(piece, sq, Opening, -QueenBackRankOpening);
    }

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, PieceActivityWeight ~/ 256);
      Pmul(piece, sq, Endgame, PieceActivityWeight ~/ 256);
    }

// kings
    piece = WhiteKing12;

// centre
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Endgame, KingLine[square_file(sq)] * KingCentreEndgame);
      Padd(piece, sq, Endgame, KingLine[square_rank(sq)] * KingCentreEndgame);
    }

// file
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, KingFile[square_file(sq)] * KingFileOpening);
    }

// rank
    for (sq = 0; sq <= 63; sq++) {
      Padd(piece, sq, Opening, KingRank[square_rank(sq)] * KingRankOpening);
    }

// weight
    for (sq = 0; sq <= 63; sq++) {
      Pmul(piece, sq, Opening, KingSafetyWeight ~/ 256);
      Pmul(piece, sq, Endgame, PieceActivityWeight ~/ 256);
    }

// symmetry copy for black
    for (piece = 0; piece <= 11; piece += 2) {
      for (sq = 0; sq <= 63; sq++) {
        for (stage = 0; stage < StageNb; stage++) {
          Pset(piece + 1, sq, stage, -Pget(piece, square_opp(sq), stage));
        }
      }
    }
  }

  bool pv_is_ok(List<int> pv) {
    int pos = 0; // int
    int move; // int

    for (;;) {
      if (pos >= 256) return false;

      move = pv[pos];

      if (move == MoveNone) return true;

      if (!move_is_ok(move)) return false;

      pos++;
    }
  }

  pv_copy(List<int> dst, List<int> src) {
    int i = 0; // int
    int m; // int

    //ASSERT(615, pv_is_ok(src));

    for (;;) {
      m = src[i];
      dst[i] = m;
      if (m == MoveNone) break;
      i++;
    }
  }

  pv_cat(List<int> dst, List<int> src, int move) {
    int i = 0; // int
    int m; // int

    //ASSERT(617, pv_is_ok(src));

    dst[0] = move;

    for (;;) {
      m = src[i];
      dst[i + 1] = m;
      if (m == MoveNone) break;
      i++;
    }
  }

  pv_to_string(List<int> pv, string_t str1) {
    int i = 0; // int
    int move; // int
    string_t str2 = new string_t(); // string_t[1]

    //ASSERT(619, pv_is_ok(pv));

// init
    str1.v = "";

// loop
    for (;;) {
      move = pv[i];
      if (move == MoveNone) break;

      if (i > 0) str1.v += " ";

      move_to_string(move, str2);
      str1.v += str2.v;

      i++;
    }
  }

  bool kpk_draw(int wp, int wk, int bk, int turn) {
    //ASSERT(624, SQUARE_IS_OK(wp));
    //ASSERT(625, SQUARE_IS_OK(wk));
    //ASSERT(626, SQUARE_IS_OK(bk));
    //ASSERT(627, COLOUR_IS_OK(turn));

    //ASSERT(628, SQUARE_FILE(wp) <= FileD);

    int wp_file = SQUARE_FILE(wp);
    int wp_rank = SQUARE_RANK(wp);

    int wk_file = SQUARE_FILE(wk);

    int bk_file = SQUARE_FILE(bk);
    int bk_rank = SQUARE_RANK(bk);

    bool ifelse = true;
    if (ifelse && (bk == wp + 16)) {
      if (wp_rank <= Rank6) {
        return true;
      } else {
        //ASSERT(629, wp_rank == Rank7);

        if (COLOUR_IS_WHITE(turn)) {
          if (wk == wp - 15 || wk == wp - 17) return true;
        } else {
          if (wk != wp - 15 && wk != wp - 17) return true;
        }
      }
      ifelse = false;
    }

    if (ifelse && (bk == wp + 32)) {
      if (wp_rank <= Rank5) {
        return true;
      } else {
        //ASSERT(630, wp_rank == Rank6);

        if (COLOUR_IS_WHITE(turn)) {
          if (wk != wp - 1 && wk != wp + 1) return true;
        } else
          return true;
      }

      ifelse = false;
    }

    if (ifelse && (wk == wp - 1 || wk == wp + 1)) {
      if (bk == wk + 32 && COLOUR_IS_WHITE(turn)) {
        // opposition
        return true;
      }

      ifelse = false;
    }

    if (ifelse && (wk == wp + 15 || wk == wp + 16 || wk == wp + 17)) {
      if (wp_rank <= Rank4) {
        if (bk == wk + 32 && COLOUR_IS_WHITE(turn)) {
          // opposition
          return true;
        }
      }
      ifelse = false;
    }

// rook pawn
    if (wp_file == FileA) {
      if (DISTANCE(bk, A8) <= 1) return true;

      if (wk_file == FileA) {
        if (wp_rank == Rank2) wp_rank++;

        if (bk_file == FileC && bk_rank > wp_rank) return true;
      }
    }

    return false;
  }

  bool kbpk_draw(int wp, int wb, int bk) {
    //ASSERT(631, SQUARE_IS_OK(wp));
    //ASSERT(632, SQUARE_IS_OK(wb));
    //ASSERT(633, SQUARE_IS_OK(bk));

    if (SQUARE_FILE(wp) == FileA &&
        DISTANCE(bk, A8) <= 1 &&
        SQUARE_COLOUR(wb) != SQUARE_COLOUR(A8)) {
      return true;
    }

    return false;
  }

  bool recog_draw(board_t board) {
    material_info_t mat_info = new material_info_t(); // material_info_t[1]
    bool ifelse;

    int me; // int
    int opp; // int
    int wp; // int
    int wk; // int
    int bk; // int
    int wb; // int
    int bb; // int

// material

    if (board.piece_nb > 4) return false;

    material_get_info(mat_info, board);

    if ((mat_info.flags & DrawNodeFlag) == 0) return false;

// recognisers

    ifelse = true;
    if (mat_info.recog == MAT_KK) return true; // KK

    if (mat_info.recog == MAT_KBK) return true; // KBK (white)

    if (mat_info.recog == MAT_KKB) return true; // KBK (black)

    if (mat_info.recog == MAT_KNK) return true; // KNK (white)

    if (mat_info.recog == MAT_KKN) return true; // KNK (black)

    if (mat_info.recog == MAT_KPK) {
// KPK (white)
      me = White;
      opp = COLOUR_OPP(me);

      wp = board.pawn[me][0];
      wk = KING_POS(board, me);
      bk = KING_POS(board, opp);

      if (SQUARE_FILE(wp) >= FileE) {
        wp = SQUARE_FILE_MIRROR(wp);
        wk = SQUARE_FILE_MIRROR(wk);
        bk = SQUARE_FILE_MIRROR(bk);
      }

      if (kpk_draw(wp, wk, bk, board.turn)) return true;

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KKP) {
// KPK (black)
      me = Black;
      opp = COLOUR_OPP(me);

      wp = SQUARE_RANK_MIRROR(board.pawn[me][0]);
      wk = SQUARE_RANK_MIRROR(KING_POS(board, me));
      bk = SQUARE_RANK_MIRROR(KING_POS(board, opp));

      if (SQUARE_FILE(wp) >= FileE) {
        wp = SQUARE_FILE_MIRROR(wp);
        wk = SQUARE_FILE_MIRROR(wk);
        bk = SQUARE_FILE_MIRROR(bk);
      }

      if (kpk_draw(wp, wk, bk, COLOUR_OPP(board.turn))) return true;

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KBKB) {
// KBKB
      wb = board.piece[White][1];
      bb = board.piece[Black][1];

      if (SQUARE_COLOUR(wb) == SQUARE_COLOUR(bb)) {
        // bishops on same colour
        return true;
      }
      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KBPK) {
// KBPK (white)
      me = White;
      opp = COLOUR_OPP(me);

      wp = board.pawn[me][0];
      wb = board.piece[me][1];
      bk = KING_POS(board, opp);

      if (SQUARE_FILE(wp) >= FileE) {
        wp = SQUARE_FILE_MIRROR(wp);
        wb = SQUARE_FILE_MIRROR(wb);
        bk = SQUARE_FILE_MIRROR(bk);
      }

      if (kbpk_draw(wp, wb, bk)) return true;

      ifelse = false;
    }

    if (ifelse && mat_info.recog == MAT_KKBP) {
// KBPK (black)
      me = Black;
      opp = COLOUR_OPP(me);

      wp = SQUARE_RANK_MIRROR(board.pawn[me][0]);
      wb = SQUARE_RANK_MIRROR(board.piece[me][1]);
      bk = SQUARE_RANK_MIRROR(KING_POS(board, opp));

      if (SQUARE_FILE(wp) >= FileE) {
        wp = SQUARE_FILE_MIRROR(wp);
        wb = SQUARE_FILE_MIRROR(wb);
        bk = SQUARE_FILE_MIRROR(bk);
      }

      if (kbpk_draw(wp, wb, bk)) return true;

      ifelse = false;
    }

    if (ifelse) {
      //ASSERT(623, false);
    }

    return false;
  }

  sort_init1() {
    int height; // int
    int pos; // int

// killer

    Killer = [];
    for (height = 0; height < HeightMax; height++)
      Killer.add(List.filled(KillerNb, MoveNone));

// history
    History = List.filled(HistorySize, 0);
    HistHit = List.filled(HistorySize, 1);
    HistTot = List.filled(HistorySize, 1);

// Code[]
    Code = List.filled(CODE_SIZE, GEN_ERROR);

    pos = 0;
// main search
    PosLegalEvasion = pos;
    Code[0] = GEN_LEGAL_EVASION;
    Code[1] = GEN_END;

    PosSEE = 2;
    Code[2] = GEN_TRANS;
    Code[3] = GEN_GOOD_CAPTURE;
    Code[4] = GEN_KILLER;
    Code[5] = GEN_QUIET;
    Code[6] = GEN_BAD_CAPTURE;
    Code[7] = GEN_END;

// quiescence search
    PosEvasionQS = 8;
    Code[8] = GEN_EVASION_QS;
    Code[9] = GEN_END;

    PosCheckQS = 10;
    Code[10] = GEN_CAPTURE_QS;
    Code[11] = GEN_CHECK_QS;
    Code[12] = GEN_END;

    PosCaptureQS = 13;
    Code[13] = GEN_CAPTURE_QS;
    Code[14] = GEN_END;

    pos = 15;
    //ASSERT(795, pos < CODE_SIZE);
  }

  note_moves(list_t list, board_t board, int height, int trans_killer) {
    int size; // int
    int i; // int
    int move; // int

    //ASSERT(839, list_is_ok(list));
    //ASSERT(841, height_is_ok(height));
    //ASSERT(842, trans_killer == MoveNone || move_is_ok(trans_killer));

    size = list.size;

    if (size >= 2) {
      for (i = 0; i < size; i++) {
        move = list.move[i];
        list.value[i] = move_value(move, board, height, trans_killer);
      }
    }
  }

  search_full_init(list_t list, board_t board) {
    String str1 = ""; // string
    int tmove; // int

    //ASSERT(640, list_is_ok(list));
    //ASSERT(641, board_is_ok(board));

// null-move options
    str1 = option_get_string("nullMove Pruning");

    if (string_equal(str1, "Always")) {
      Usenull = true;
      UsenullEval = false;
    } else {
      if (string_equal(str1, "Fail High")) {
        Usenull = true;
        UsenullEval = true;
      } else {
        if (string_equal(str1, "Never")) {
          Usenull = false;
          UsenullEval = false;
        } else {
          //ASSERT(642, false);
          Usenull = true;
          UsenullEval = true;
        }
      }
    }

    nullReduction = option_get_int("nullMove Reduction");

    str1 = option_get_string("Verification Search");

    if (string_equal(str1, "Always")) {
      UseVer = true;
      UseVerEndgame = false;
    } else {
      if (string_equal(str1, "endgame")) {
        UseVer = true;
        UseVerEndgame = true;
      } else {
        if (string_equal(str1, "Never")) {
          UseVer = false;
          UseVerEndgame = false;
        } else {
          //ASSERT(643, false);
          UseVer = true;
          UseVerEndgame = true;
        }
      }
    }

    VerReduction = option_get_int("Verification Reduction");

// history-pruning options

    UseHistory = option_get_bool("History Pruning");
    HistoryValue = ((option_get_int("History Threshold") * 16384) + 50) ~/ 100;

// futility-pruning options

    UseFutility = option_get_bool("Futility Pruning");
    FutilityMargin = option_get_int("Futility Margin");

// delta-pruning options

    UseDelta = option_get_bool("Delta Pruning");
    DeltaMargin = option_get_int("Delta Margin");

// quiescence-search options

    CheckNb = option_get_int("Quiescence Check Plies");
    CheckDepth = 1 - CheckNb;

// standard sort

    list_note(list);
    list_sort(list);

// basic sort

    tmove = MoveNone;
    if (UseTrans) {
      trans_retrieve(Trans, board.key, TransRv);
      tmove = TransRv.trans_move;
    }

    note_moves(list, board, 0, tmove);
    list_sort(list);
  }

  search() {
    int move = MoveNone; // int
    int depth; // int

    //ASSERT(634, board_is_ok(SearchInput.board));

// opening book
    if (option_get_bool("OwnBook") && (!SearchInput.infinite)) {
// no book here
// move = book_move(SearchInput.board);

      if (move != MoveNone) {
// play book move
        SearchBest.move = move;
        SearchBest.value = 1;
        SearchBest.flags = SearchExact;
        SearchBest.depth = 1;
        SearchBest.pv[0] = move;
        SearchBest.pv[1] = MoveNone;

        search_update_best();

        return;
      }
    }

// SearchInput
    gen_legal_moves(SearchInput.list, SearchInput.board);

    if (SearchInput.list.size <= 1) {
      SearchInput.depth_is_limited = true;
      SearchInput.depth_limit = 4; // was 1
    }

// SearchInfo
    setjmp = false;
    for (;;) {
      // setjmp loop

      if (setjmp) {
        setjmp = false;
        //ASSERT(635, SearchInfo.can_stop);
        //ASSERT(636, SearchBest.move != MoveNone);
        search_update_current();
        return;
      }

// SearchRoot
      list_copy(SearchRoot.list, SearchInput.list);

// SearchCurrent
      board_copy(SearchCurrent.board, SearchInput.board);
      my_timer_reset(SearchCurrent.timer);
      my_timer_start(SearchCurrent.timer);

// init
      trans_inc_date(Trans);

      sort_init1();
      search_full_init(SearchRoot.list, SearchCurrent.board);

// iterative deepening
      for (depth = 1; depth < DepthMax; depth++) {
        if (DispDepthStart) {
          send("info depth " + depth.toString());
        }

        SearchRoot.bad_1 = false;
        SearchRoot.change = false;

        board_copy(SearchCurrent.board, SearchInput.board);

        if (UseShortSearch && depth <= ShortSearchDepth) {
          search_full_root(
              SearchRoot.list, SearchCurrent.board, depth, SearchShort);
          if (setjmp) break;
        } else {
          search_full_root(
              SearchRoot.list, SearchCurrent.board, depth, SearchNormal);
          if (setjmp) break;
        }

        search_update_current();

        if (DispDepthEnd) send_ndtm(6);

// update search info
        if (depth >= 1) SearchInfo.can_stop = true;

        if (depth == 1 &&
            SearchRoot.list.size >= 2 &&
            SearchRoot.list.value[0] >=
                SearchRoot.list.value[1] + EasyThreshold) {
          SearchRoot.easy = true;
        }

        if (UseBad && depth > 1) {
          SearchRoot.bad_2 = SearchRoot.bad_1;
          SearchRoot.bad_1 = false;
          //ASSERT(637, SearchRoot.bad_2 == (SearchBest.value <= SearchRoot.last_value - BadThreshold));
        }

        SearchRoot.last_value = SearchBest.value;

// stop search?
        if (SearchInput.depth_is_limited && depth >= SearchInput.depth_limit)
          SearchRoot.flag = true;

        if (SearchInput.time_is_limited &&
            SearchCurrent.time >= SearchInput.time_limit_1 &&
            (!SearchRoot.bad_2)) SearchRoot.flag = true;

        if (UseEasy &&
            SearchInput.time_is_limited &&
            SearchCurrent.time >= SearchInput.time_limit_1 * EasyRatio &&
            SearchRoot.easy) {
          //ASSERT(638, !SearchRoot.bad_2);
          //ASSERT(639, !SearchRoot.change);
          SearchRoot.flag = true;
        }

        if (UseEarly &&
            SearchInput.time_is_limited &&
            SearchCurrent.time >= SearchInput.time_limit_1 * EarlyRatio &&
            (!SearchRoot.bad_2) &&
            (!SearchRoot.change)) SearchRoot.flag = true;

        if (SearchInfo.can_stop &&
            (SearchInfo.stop || (SearchRoot.flag && (!SearchInput.infinite))))
          return;
      }
    } // setjmp loop
  }

  search_update_best() {
    int move; // int
    int value; // int
    int flags; // int
    late List<int> pv;
    int mate; // int
    string_t move_string = new string_t(); // string
    string_t pv_string = new string_t(); // string

    search_update_current();

    if (DispBest) {
      move = SearchBest.move;
      value = SearchBest.value;
      flags = SearchBest.flags;
      pv = SearchBest.pv;

      move_to_string(move, move_string);
      pv_to_string(pv, pv_string);

      mate = value_to_mate(value);
      SearchCurrent.mate = mate;

      if (mate == 0) {
// normal evaluation
        if (flags == SearchExact) {
          send_ndtm(10);
        } else {
          if (flags == SearchLower) {
            send_ndtm(11);
          } else {
            if (flags == SearchUpper) {
              send_ndtm(12);
            }
          }
        }
      } else {
// mate announcement
        if (flags == SearchExact) {
          send_ndtm(20);
        } else {
          if (flags == SearchLower) {
            send_ndtm(21);
          } else {
            if (flags == SearchUpper) {
              send_ndtm(22);
            }
          }
        }
      }
    }

// update time-management info
    if (UseBad && SearchBest.depth > 1) {
      if (SearchBest.value <= SearchRoot.last_value - BadThreshold) {
        SearchRoot.bad_1 = true;
        SearchRoot.easy = false;
        SearchRoot.flag = false;
      } else {
        SearchRoot.bad_1 = false;
      }
    }
  }

  search_update_root() {
    int move; // int
    int move_pos; // int

    string_t move_string = new string_t(); // string

    if (DispRoot) {
      search_update_current();

      if (SearchCurrent.time >= 1.0) {
        move = SearchRoot.move;
        move_pos = SearchRoot.move_pos;

        move_to_string(move, move_string);

        send("info currmove " +
            move_string.v +
            " currmovenumber " +
            (move_pos + 1).toString());
      }
    }
  }

  search_update_current() {
    late my_timer_t timer;
    late int node_nb;

    double etime;
    double speed;

    timer = SearchCurrent.timer;
    node_nb = SearchCurrent.node_nb;

    etime = my_timer_elapsed_real(timer);
    speed = (etime >= 1.0 ? node_nb / etime : 0.0);

    SearchCurrent.time = etime;
    SearchCurrent.speed = speed;
  }

  search_check() {
    if (SearchInput.depth_is_limited &&
        SearchRoot.depth > SearchInput.depth_limit) {
      SearchRoot.flag = true;
    }

    if (SearchInput.time_is_limited &&
        SearchCurrent.time >= SearchInput.time_limit_2) {
      SearchRoot.flag = true;
    }

    if (SearchInput.time_is_limited &&
        SearchCurrent.time >= SearchInput.time_limit_1 &&
        (!SearchRoot.bad_1) &&
        (!SearchRoot.bad_2) &&
        ((!UseExtension) || SearchRoot.move_pos == 0)) {
      SearchRoot.flag = true;
    }

    if (SearchInfo.can_stop &&
        (SearchInfo.stop || (SearchRoot.flag && (!SearchInput.infinite)))) {
      setjmp = true; // the same as  longjmp(SearchInfo.buf,1);
    }
  }

  search_send_stat() {
    search_update_current();

    if (DispStat && SearchCurrent.time >= SearchInfo.last_time + 1.0) {
      // at least one-second gap

      SearchInfo.last_time = SearchCurrent.time;

      send_ndtm(3);

      trans_stats(Trans);
    }
  }

  int search_full_root(list_t list, board_t board, int depth, int search_type) {
    //ASSERT(644, list_is_ok(list));
    //ASSERT(645, board_is_ok(board));
    //ASSERT(646, depth_is_ok(depth));
    //ASSERT(647, search_type == SearchNormal || search_type == SearchShort);

    //ASSERT(648, list == SearchRoot.list);
    //ASSERT(649, !(list.size == 0));
    //ASSERT(650, board == SearchCurrent.board);
    //ASSERT(651, board_is_legal(board));
    //ASSERT(652, depth >= 1);

    int value =
        full_root(list, board, -ValueInf, ValueInf, depth, 0, search_type);
    if (setjmp) return 0;

    //ASSERT(653, value_is_ok(value));
    //ASSERT(654, list.value[0] == value);

    return value;
  }

  int full_root(list_t list, board_t board, int alpha, int beta, int depth,
      int height, int search_type) {
    int old_alpha; // int
    int value; // int
    int best_value; // int
    int i; // int
    int move; // int
    int new_depth; // int
    undo_t undo = new undo_t(); // undo_t[1]
    List<int> new_pv = List.filled(HeightMax, 0); // int[HeightMax];

    //ASSERT(655, list_is_ok(list));
    //ASSERT(656, board_is_ok(board));
    //ASSERT(657, range_is_ok(alpha, beta));
    //ASSERT(658, depth_is_ok(depth));
    //ASSERT(659, height_is_ok(height));
    //ASSERT(660, search_type == SearchNormal || search_type == SearchShort);

    //ASSERT(661, list.size == SearchRoot.list.size);
    //ASSERT(662, !(list.size == 0));
    //ASSERT(663, board.key == SearchCurrent.board.key);
    //ASSERT(664, board_is_legal(board));
    //ASSERT(665, depth >= 1);

// init
    SearchCurrent.node_nb++;
    SearchInfo.check_nb--;

    for (i = 0; i < list.size; i++) list.value[i] = ValueNone;

    old_alpha = alpha;
    best_value = ValueNone;

// move loop
    for (i = 0; i < list.size; i++) {
      move = list.move[i];

      SearchRoot.depth = depth;
      SearchRoot.move = move;
      SearchRoot.move_pos = i;
      SearchRoot.move_nb = list.size;

      search_update_root();

      new_depth = full_new_depth(
          depth, move, board, board_is_check(board) && list.size == 1, true);

      move_do(board, move, undo);

      if (search_type == SearchShort || best_value == ValueNone) {
        // first move
        value = -full_search(
            board, -beta, -alpha, new_depth, height + 1, new_pv, NodePV);
        if (setjmp) return 0;
      } else {
        // other moves
        value = -full_search(
            board, -alpha - 1, -alpha, new_depth, height + 1, new_pv, NodeCut);
        if (setjmp) return 0;

        if (value > alpha) {
          //  &&  value < beta
          SearchRoot.change = true;
          SearchRoot.easy = false;
          SearchRoot.flag = false;
          search_update_root();
          value = -full_search(
              board, -beta, -alpha, new_depth, height + 1, new_pv, NodePV);
          if (setjmp) return 0;
        }
      }

      move_undo(board, move, undo);

      if (value <= alpha) {
        // upper bound
        list.value[i] = old_alpha;
      } else {
        if (value >= beta) {
          // lower bound
          list.value[i] = beta;
        } else {
          // alpha < value < beta => exact value
          list.value[i] = value;
        }
      }

      if (value > best_value && (best_value == ValueNone || value > alpha)) {
        SearchBest.move = move;
        SearchBest.value = value;
        if (value <= alpha) {
          // upper bound
          SearchBest.flags = SearchUpper;
        } else {
          if (value >= beta) {
            // lower bound
            SearchBest.flags = SearchLower;
          } else {
            // alpha < value < beta => exact value
            SearchBest.flags = SearchExact;
          }
        }
        SearchBest.depth = depth;

//unshift is faster, but not used here
        pv_cat(SearchBest.pv, new_pv, move);

        search_update_best();
      }

      if (value > best_value) {
        best_value = value;
        if (value > alpha) {
          if (search_type == SearchNormal) alpha = value;

          if (value >= beta) break;
        }
      }
    }

    //ASSERT(666, value_is_ok(best_value));

    list_sort(list);

    //ASSERT(667, SearchBest.move == list.move[0]);
    //ASSERT(668, SearchBest.value == best_value);

    if (UseTrans && best_value > old_alpha && best_value < beta)
      pv_fill(SearchBest.pv, 0, board);

    return best_value;
  }

  int full_search(board_t board, int alpha, int beta, int depth, int height,
      List<int> pv, int node_type) {
    bool in_check; // bool
    bool single_reply; // bool
    int tmove; // int
    int tdepth; // int

    int min_value; // int
    int max_value; // int
    int old_alpha; // int
    int value; // int
    int best_value; // int

    int_t bmove = new int_t(); // int
    int move; // int

    int best_move; // int
    int new_depth; // int
    int played_nb; // int
    int i; // int
    int opt_value; // int
    bool reduced; // bool
    attack_t attack = new attack_t(); // attack_t[1]
    sort_t sort = new sort_t(); // sort_t[1]
    undo_t undo = new undo_t(); // undo_t[1]
    List<int> new_pv = List.filled(HeightMax, 0); // int[HeightMax]
    List<int> played = List.filled(256, 0); // int[256]
    bool gotocut = false;
    bool cont = false;

    //ASSERT(670, range_is_ok(alpha, beta));
    //ASSERT(671, depth_is_ok(depth));
    //ASSERT(672, height_is_ok(height));

    //ASSERT(674, node_type == NodePV || node_type == NodeCut || node_type == NodeAll);

    //ASSERT(675, board_is_legal(board));

// horizon?
    if (depth <= 0) {
      return full_quiescence(board, alpha, beta, 0, height, pv);
    }
// init
    SearchCurrent.node_nb++;
    SearchInfo.check_nb--;
    pv[0] = MoveNone;

    if (height > SearchCurrent.max_depth) SearchCurrent.max_depth = height;

    if (SearchInfo.check_nb <= 0) {
      SearchInfo.check_nb = SearchInfo.check_nb + SearchInfo.check_inc;
      search_check();
      if (setjmp) return 0;
    }

// draw?
    if (board_is_repetition(board) || recog_draw(board)) return ValueDraw;

// mate-distance pruning
    if (UseDistancePruning) {
// lower bound
      // does not work if the current position is mate
      value = (height + 2 - ValueMate);
      if (value > alpha && board_is_mate(board)) value = (height - ValueMate);

      if (value > alpha) {
        alpha = value;
        if (value >= beta) return value;
      }

// upper bound
      value = -(height + 1 - ValueMate);

      if (value < beta) {
        beta = value;
        if (value <= alpha) return value;
      }
    }

// transposition table
    tmove = MoveNone;

    if (UseTrans && depth >= TransDepth) {
      if (trans_retrieve(Trans, board.key, TransRv)) {
        tmove = TransRv.trans_move;

// trans_move is now updated
        if (node_type != NodePV) {
          if (UseMateValues) {
            if (TransRv.trans_min_value > ValueEvalInf &&
                TransRv.trans_min_depth < depth) {
              TransRv.trans_min_depth = depth;
            }

            if (TransRv.trans_max_value < -ValueEvalInf &&
                TransRv.trans_max_depth < depth) {
              TransRv.trans_max_depth = depth;
            }
          }

          min_value = -ValueInf;

          if (TransRv.trans_min_depth >= depth) {
            min_value = value_from_trans(TransRv.trans_min_value, height);
            if (min_value >= beta) return min_value;
          }

          max_value = ValueInf;

          if (TransRv.trans_max_depth >= depth) {
            max_value = value_from_trans(TransRv.trans_max_value, height);
            if (max_value <= alpha) return max_value;
          }

          if (min_value == max_value) return min_value; // exact match
        }
      }
    }

// height limit
    if (height >= HeightMax - 1) return evalpos(board);

// more init
    old_alpha = alpha;
    best_value = ValueNone;
    best_move = MoveNone;
    played_nb = 0;

    attack_set(attack, board);
    in_check = ATTACK_IN_CHECK(attack);

// null-move pruning
    if (Usenull && depth >= nullDepth && node_type != NodePV) {
      if ((!in_check) &&
          (!value_is_mate(beta)) &&
          do_null(board) &&
          ((!UsenullEval) ||
              depth <= nullReduction + 1 ||
              evalpos(board) >= beta)) {
// null-move search
        new_depth = depth - nullReduction - 1;

        move_do_null(board, undo);
        value = -full_search(
            board, -beta, -beta + 1, new_depth, height + 1, new_pv, -node_type);
        if (setjmp) return 0;

        move_undo_null(board, undo);

// verification search

        if (UseVer && depth > VerReduction) {
          if (value >= beta && ((!UseVerEndgame) || do_ver(board))) {
            new_depth = depth - VerReduction;
            //ASSERT(676, new_depth > 0);

            value = full_no_null(board, alpha, beta, new_depth, height, new_pv,
                NodeCut, tmove, bmove);
            move = bmove.v;

            if (setjmp) return 0;

            if (value >= beta) {
              //ASSERT(677, move == new_pv[0]);
              played[played_nb] = move;
              played_nb++;
              best_move = move;
              best_value = value;

// pv_copy(pv,new_pv);
              new_pv = []; // slow copy
              for (int w = 0; w < pv.length; w++) new_pv.add(pv[w]);

              gotocut = true;
            }
          }
        }

// pruning
        if ((!gotocut) && value >= beta) {
          if (value > ValueEvalInf) {
            value = ValueEvalInf; // do not return unproven mates
          }
          //ASSERT(678, !value_is_mate(value));

// pv_cat(pv,new_pv,Movenull);

          best_move = MoveNone;
          best_value = value;
          gotocut = true;
        }
      }
    }

    if (!gotocut) {
      // [1]

// Internal Iterative Deepening

      if (UseIID &&
          depth >= IIDDepth &&
          node_type == NodePV &&
          tmove == MoveNone) {
        new_depth = depth - IIDReduction;
        //ASSERT(679, new_depth > 0);

        value = full_search(
            board, alpha, beta, new_depth, height, new_pv, node_type);
        if (setjmp) return 0;

        if (value <= alpha) {
          value = full_search(
              board, -ValueInf, beta, new_depth, height, new_pv, node_type);
          if (setjmp) return 0;
        }

        tmove = new_pv[0];
      }

// move generation
      sort_init2(sort, board, attack, depth, height, tmove);

      single_reply = false;
      if (in_check && sort.list.size == 1) single_reply = true;

// move loop
      opt_value = ValueInf;

      for (;;) {
        move = sort_next(sort);
        if (move == MoveNone) break;

// extensions
        new_depth = full_new_depth(
            depth, move, board, single_reply, node_type == NodePV);

// history pruning
        reduced = false;

        if (UseHistory && depth >= HistoryDepth && node_type != NodePV) {
          if ((!in_check) && played_nb >= HistoryMoveNb && new_depth < depth) {
            //ASSERT(680, best_value != ValueNone);
            //ASSERT(681, played_nb > 0);
            //ASSERT(682, sort.pos > 0 && move == sort.list.move[sort.pos - 1]);
            value = sort.value; // history score
            if (value < HistoryValue) {
              //ASSERT(683, value >= 0 && value < 16384);
              //ASSERT(684, move != tmove);
              //ASSERT(685, !move_is_tactical(move, board));
              //ASSERT(686, !move_is_check(move, board));
              new_depth--;
              reduced = true;
            }
          }
        }

// futility pruning
        if (UseFutility && depth == 1 && node_type != NodePV) {
          if ((!in_check) &&
              new_depth == 0 &&
              (!move_is_tactical(move, board)) &&
              (!move_is_dangerous(move, board))) {
            //ASSERT(687, !move_is_check(move, board));

// optimistic evaluation

            if (opt_value == ValueInf) {
              opt_value = evalpos(board) + FutilityMargin;
              //ASSERT(688, opt_value < ValueInf);
            }

            value = opt_value;

// pruning
            if (value <= alpha) {
              if (value > best_value) {
                best_value = value;
                pv[0] = MoveNone;
              }

              cont = true;
            }
          }
        }

        if (cont) {
          // continue [1]
          cont = false;
        } else {
// recursive search
          move_do(board, move, undo);

          if (node_type != NodePV || best_value == ValueNone) {
            // first move
            value = -full_search(board, -beta, -alpha, new_depth, height + 1,
                new_pv, -node_type);
            if (setjmp) return 0;
          } else {
            // other moves
            value = -full_search(board, -alpha - 1, -alpha, new_depth,
                height + 1, new_pv, NodeCut);
            if (setjmp) return 0;

            if (value > alpha) {
              //  &&  value < beta
              value = -full_search(
                  board, -beta, -alpha, new_depth, height + 1, new_pv, NodePV);
              if (setjmp) return 0;
            }
          }

// history-pruning re-search
          if (HistoryReSearch && reduced && value >= beta) {
            //ASSERT(689, node_type != NodePV);
            new_depth++;
            //ASSERT(690, new_depth == depth - 1);
            value = -full_search(board, -beta, -alpha, new_depth, height + 1,
                new_pv, -node_type);
            if (setjmp) return 0;
          }

          move_undo(board, move, undo);

          played[played_nb] = move;
          played_nb++;

          if (value > best_value) {
            best_value = value;
            pv_cat(pv, new_pv, move);
            if (value > alpha) {
              alpha = value;
              best_move = move;
              if (value >= beta) {
                gotocut = true;
                break;
              }
            }
          }

          if (node_type == NodeCut) node_type = NodeAll;
        } // continue [1]
      }

      if (!gotocut) {
        // [2]

// ALL node
        if (best_value == ValueNone) {
          // no legal move
          if (in_check) {
            //ASSERT(691, board_is_mate(board));
            return (height - ValueMate);
          } else {
            //ASSERT(692, board_is_stalemate(board));
            return ValueDraw;
          }
        }
      } // goto cut [2]
    } // goto cut [1]

// cut:

    //ASSERT(693, value_is_ok(best_value));

// move ordering
    if (best_move != MoveNone) {
      good_move(best_move, board, depth, height);

      if (best_value >= beta && (!move_is_tactical(best_move, board))) {
        //ASSERT(694, played_nb > 0 && played[played_nb - 1] == best_move);

        for (i = 0; i <= played_nb - 2; i++) {
          move = played[i];
          //ASSERT(695, move != best_move);
          history_bad(move, board);
        }

        history_good(best_move, board);
      }
    }

// transposition table
    if (UseTrans && depth >= TransDepth) {
      tmove = best_move;
      tdepth = depth;
      TransRv.trans_min_value = (best_value > old_alpha
          ? value_to_trans(best_value, height)
          : -ValueInf);

      TransRv.trans_max_value =
          (best_value < beta ? value_to_trans(best_value, height) : ValueInf);

      trans_store(Trans, board.key, tmove, tdepth, TransRv);
    }

    return best_value;
  }

  sort_init2(sort_t sort, board_t board, attack_t attack, int depth, int height,
      int trans_killer) {
    //ASSERT(799, depth_is_ok(depth));
    //ASSERT(800, height_is_ok(height));
    //ASSERT(801, trans_killer == MoveNone || move_is_ok(trans_killer));

    sort.board = board;
    sort.attack = attack;

    sort.depth = depth;
    sort.height = height;

    sort.trans_killer = trans_killer;
    sort.killer_1 = Killer[sort.height][0];
    sort.killer_2 = Killer[sort.height][1];

    if (ATTACK_IN_CHECK(sort.attack)) {
      gen_legal_evasions(sort.list, sort.board, sort.attack);
      note_moves(sort.list, sort.board, sort.height, sort.trans_killer);
      list_sort(sort.list);

      sort.gen = PosLegalEvasion + 1;
      sort.test = TEST_NONE;
    } else {
      // not in check
      sort.list.size = 0;
      sort.gen = PosSEE;
    }

    sort.pos = 0;
  }

  int full_no_null(board_t board, int alpha, int beta, int depth, int height,
      List<int> pv, int node_type, int tmove, int_t b_move) {
    int value; // int
    int best_value; // int
    int move; // int
    int new_depth; // int

    attack_t attack = new attack_t(); // attack_t[1]
    sort_t sort = new sort_t(); // sort_t[1]
    undo_t undo = new undo_t(); // undo_t[1]
    List<int> new_pv = List.filled(HeightMax, 0); // int[HeightMax]
    bool gotocut = false;

    //ASSERT(697, range_is_ok(alpha, beta));
    //ASSERT(698, depth_is_ok(depth));
    //ASSERT(699, height_is_ok(height));
    //ASSERT(701, node_type == NodePV || node_type == NodeCut || node_type == NodeAll);
    //ASSERT(702, tmove == MoveNone || move_is_ok(tmove));

    //ASSERT(704, board_is_legal(board));
    //ASSERT(705, !board_is_check(board));
    //ASSERT(706, depth >= 1);

// init
    SearchCurrent.node_nb++;
    SearchInfo.check_nb--;
    pv[0] = MoveNone;

    if (height > SearchCurrent.max_depth) SearchCurrent.max_depth = height;

    if (SearchInfo.check_nb <= 0) {
      SearchInfo.check_nb += SearchInfo.check_inc;
      search_check();
      if (setjmp) return 0;
    }

    attack_set(attack, board);
    //ASSERT(707, !ATTACK_IN_CHECK(attack));

    b_move.v = MoveNone;
    best_value = ValueNone;

// move loop

    sort_init2(sort, board, attack, depth, height, tmove);

    for (;;) {
      move = sort_next(sort);
      if (move == MoveNone) break;

      new_depth = full_new_depth(depth, move, board, false, false);

      move_do(board, move, undo);
      value = -full_search(
          board, -beta, -alpha, new_depth, height + 1, new_pv, -node_type);
      if (setjmp) return 0;

      move_undo(board, move, undo);

      if (value > best_value) {
        best_value = value;
        pv_cat(pv, new_pv, move);
        if (value > alpha) {
          alpha = value;
          b_move.v = move;
          if (value >= beta) {
            gotocut = true;
            break;
          }
        }
      }
    }

    if (!gotocut) {
      // [1]

// ALL node

      if (best_value == ValueNone) {
        // no legal move => stalemate
        //ASSERT(708, board_is_stalemate(board));
        best_value = ValueDraw;
      }
    } // goto cut [1]

// cut:

    //ASSERT(709, value_is_ok(best_value));

    return best_value;
  }

  bool capture_is_dangerous(int move, board_t board) {
    int piece; // int
    int capture; // int

    //ASSERT(738, move_is_ok(move));

    //ASSERT(740, move_is_tactical(move, board));

    piece = MOVE_PIECE(move, board);

    if (PIECE_IS_PAWN(piece) && PAWN_RANK(MOVE_TO(move), board.turn) >= Rank7)
      return true;

    capture = move_capture(move, board);

    if (PIECE_IS_QUEEN(capture)) return true;

    if (PIECE_IS_PAWN(capture) && PAWN_RANK(MOVE_TO(move), board.turn) <= Rank2)
      return true;

    return false;
  }

  bool simple_stalemate(board_t board) {
    int me; // int
    int opp; // int
    int king; // int
    int opp_flag; // int
    int from; // int
    int to; // int
    int capture; // int
    int inc_ptr; // int
    int inc; // int

    //ASSERT(742, board_is_legal(board));
    //ASSERT(743, !board_is_check(board));

// lone king?
    me = board.turn;
    if (board.piece_size[me] != 1 || board.pawn_size[me] != 0)
      return false; // no

// king in a corner?
    king = KING_POS(board, me);
    if (king != A1 && king != H1 && king != A8 && king != H8)
      return false; // no

// init
    opp = COLOUR_OPP(me);
    opp_flag = COLOUR_FLAG(opp);

// king can move?
    from = king;

    inc_ptr = 0;
    for (;;) {
      inc = KingInc[inc_ptr];
      if (inc == IncNone) break;

      to = from + inc;
      capture = board.square[to];
      if (capture == Empty || FLAG_IS(capture, opp_flag)) {
        if (!is_attacked(board, to, opp)) return false; // legal king move
      }

      inc_ptr++;
    }

// no legal move
    //ASSERT(744, board_is_stalemate(board));
    return true;
  }

  sort_init_qs(sort_t sort, board_t board, attack_t attack, bool check) {
    sort.board = board;
    sort.attack = attack;

    if (ATTACK_IN_CHECK(sort.attack)) {
      sort.gen = PosEvasionQS;
    } else {
      sort.gen = (check ? PosCheckQS : PosCaptureQS);
    }

    LIST_CLEAR(sort.list);
    sort.pos = 0;
  }

  int mvv_lva(int move, board_t board) {
    int piece; // int
    int capture; // int
    int promote; // int
    int value; // int

    //ASSERT(875, move_is_ok(move));

    //ASSERT(877, move_is_tactical(move, board));

    if (MOVE_IS_EN_PASSANT(move)) {
      // en-passant capture

      value = 5; // PxP
    } else {
      capture = board.square[MOVE_TO(move)];

      if (capture != Empty) {
        // normal capture
        piece = board.square[MOVE_FROM(move)];
        value = (PieceOrder[capture] * 6) - PieceOrder[piece] + 5;
        //ASSERT(878, value >= 0 && value < 30);
      } else {
        // promote
        //ASSERT(879, MOVE_IS_PROMOTE(move));
        promote = move_promote(move);

        value = PieceOrder[promote] - 5;
        //ASSERT(880, value >= -4 && value < 0);
      }
    }

    //ASSERT(881, value >= -4 && value < 30);
    return value;
  }

  note_mvv_lva(list_t list, board_t board) {
    int size; // int
    int i; // int
    int move; // int

    //ASSERT(849, list_is_ok(list));
    size = list.size;

    if (size >= 2) {
      for (i = 0; i < size; i++) {
        move = list.move[i];
        list.value[i] = mvv_lva(move, board);
      }
    }
  }

  bool capture_is_good(int move, board_t board) {
    int piece; // int
    int capture; // int

    //ASSERT(871, move_is_ok(move));

    //ASSERT(873, move_is_tactical(move, board));

// special cases
    if (MOVE_IS_EN_PASSANT(move)) return true;

    if (move_is_under_promote(move)) return false; // REMOVE ME?

// captures && queen promotes
    capture = board.square[MOVE_TO(move)];

    if (capture != Empty) {
// capture

      //ASSERT(874, move_is_capture(move, board));

      if (MOVE_IS_PROMOTE(move)) return true; // promote-capture

      piece = board.square[MOVE_FROM(move)];
      if (ValuePiece[capture] >= ValuePiece[piece]) return true;
    }

    return (see_move(move, board) >= 0);
  }

  int move_value_simple(int move, board_t board) {
    int value; // int

    //ASSERT(863, move_is_ok(move));

    value = HistoryScore;
    if (move_is_tactical(move, board)) value = mvv_lva(move, board);

    return value;
  }

  note_moves_simple(list_t list, board_t board) {
    int size; // int
    int i; // int
    int move; // int

    //ASSERT(847, list_is_ok(list));
    size = list.size;

    if (size >= 2) {
      for (i = 0; i < size; i++) {
        move = list.move[i];
        list.value[i] = move_value_simple(move, board);
      }
    }
  }

  sort_next_qs(sort_t sort) {
    int move; // int
    int gen; // int
    bool nocont;
    bool ifelse;

    for (;;) {
      while (sort.pos < sort.list.size) {
        nocont = true;

// next move
        move = sort.list.move[sort.pos];
        sort.pos++;

        //ASSERT(818, move != MoveNone);

// test
        ifelse = true;

        if (ifelse && (sort.test == TEST_LEGAL)) {
          if (nocont && (!pseudo_is_legal(move, sort.board))) {
            nocont = false;
          }

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_CAPTURE_QS)) {
          //ASSERT(819, move_is_tactical(move, sort.board));

          if (nocont && (!capture_is_good(move, sort.board))) {
            nocont = false;
          }
          if (nocont && (!pseudo_is_legal(move, sort.board))) {
            nocont = false;
          }

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_CHECK_QS)) {
          //ASSERT(820, !move_is_tactical(move, sort.board));
          //ASSERT(821, move_is_check(move, sort.board));

          if (nocont && see_move(move, sort.board) < 0) {
            nocont = false;
          }
          if (nocont && (!pseudo_is_legal(move, sort.board))) {
            nocont = false;
          }

          ifelse = false;
        }

        if (ifelse) {
          //ASSERT(822, false);
          return MoveNone;
        }

        if (nocont) {
          //ASSERT(823, pseudo_is_legal(move, sort.board));
          return move;
        }
      }

// next stage
      gen = Code[sort.gen];
      sort.gen++;

      ifelse = true;

      if (ifelse && (gen == GEN_EVASION_QS)) {
        gen_pseudo_evasions(sort.list, sort.board, sort.attack);
        note_moves_simple(sort.list, sort.board);
        list_sort(sort.list);

        sort.test = TEST_LEGAL;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_CAPTURE_QS)) {
        gen_captures(sort.list, sort.board);
        note_mvv_lva(sort.list, sort.board);
        list_sort(sort.list);

        sort.test = TEST_CAPTURE_QS;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_CHECK_QS)) {
        gen_quiet_checks(sort.list, sort.board);

        sort.test = TEST_CHECK_QS;

        ifelse = false;
      }

      if (ifelse) {
        //ASSERT(824, gen == GEN_END);

        return MoveNone;
      }

      sort.pos = 0;
    }
  }

  int full_quiescence(
      board_t board, int alpha, int beta, int depth, int height, List<int> pv) {
    bool in_check; // bool
    int old_alpha; // int

    int value; // int
    int best_value; // int
    int opt_value; // int
    int move; // int

    int to; // int
    int capture; // int

    attack_t attack = new attack_t(); // attack_t[1]
    sort_t sort = new sort_t(); // sort_t[1]
    undo_t undo = new undo_t(); // undo_t[1]
    List<int> new_pv = List.filled(HeightMax, 0); // int[HeightMax]

    bool gotocut = false;
    bool cont = false;

    //ASSERT(711, range_is_ok(alpha, beta));
    //ASSERT(712, depth_is_ok(depth));
    //ASSERT(713, height_is_ok(height));

    //ASSERT(715, board_is_legal(board));
    //ASSERT(716, depth <= 0);

// init

    SearchCurrent.node_nb++;
    SearchInfo.check_nb--;
    pv[0] = MoveNone;

    if (height > SearchCurrent.max_depth) {
      SearchCurrent.max_depth = height;
    }

    if (SearchInfo.check_nb <= 0) {
      SearchInfo.check_nb = SearchInfo.check_nb + SearchInfo.check_inc;
      search_check();
      if (setjmp) return 0;
    }

// draw?
    if (board_is_repetition(board) || recog_draw(board)) return ValueDraw;

// mate-distance pruning
    if (UseDistancePruning) {
// lower bound
      // does not work if the current position is mate
      value = (height + 2 - ValueMate);
      if (value > alpha && board_is_mate(board)) value = (height - ValueMate);

      if (value > alpha) {
        alpha = value;
        if (value >= beta) return value;
      }

// upper bound
      value = -(height + 1 - ValueMate);

      if (value < beta) {
        beta = value;
        if (value <= alpha) return value;
      }
    }

// more init
    attack_set(attack, board);
    in_check = ATTACK_IN_CHECK(attack);

    if (in_check) {
      //ASSERT(717, depth < 0);
      depth++; // in-check extension
    }

// height limit
    if (height >= HeightMax - 1) return evalpos(board);

// more init
    old_alpha = alpha;
    best_value = ValueNone;

// if (UseDelta)
    opt_value = ValueInf;

    if (!in_check) {
// lone-king stalemate?
      if (simple_stalemate(board)) return ValueDraw;

// stand pat
      value = evalpos(board);

      //ASSERT(718, value > best_value);
      best_value = value;
      if (value > alpha) {
        alpha = value;
        if (value >= beta) gotocut = true;
      }

      if ((!gotocut) && UseDelta) {
        opt_value = value + DeltaMargin;
        //ASSERT(719, opt_value < ValueInf);
      }
    }

    if (!gotocut) {
      // [1]

// move loop
      sort_init_qs(sort, board, attack, depth >= CheckDepth);

      for (;;) {
        move = sort_next_qs(sort);
        if (move == MoveNone) break;

// delta pruning

        if (UseDelta && beta == old_alpha + 1) {
          if ((!in_check) &&
              (!move_is_check(move, board)) &&
              (!capture_is_dangerous(move, board))) {
            //ASSERT(720, move_is_tactical(move, board));

// optimistic evaluation
            value = opt_value;

            to = MOVE_TO(move);
            capture = board.square[to];

            if (capture != Empty)
              value += ValuePiece[capture];
            else {
              if (MOVE_IS_EN_PASSANT(move)) value += ValuePawn;
            }

            if (MOVE_IS_PROMOTE(move)) value += ValueQueen - ValuePawn;

// pruning
            if (value <= alpha) {
              if (value > best_value) {
                best_value = value;
                pv[0] = MoveNone;
              }

              cont = true;
            }
          }
        }

        if (cont) {
          // continue [1]
          cont = false;
        } else {
          move_do(board, move, undo);

          value = -full_quiescence(
              board, -beta, -alpha, depth - 1, height + 1, new_pv);
          if (setjmp) return 0;

          move_undo(board, move, undo);

          if (value > best_value) {
            best_value = value;
            pv_cat(pv, new_pv, move);
            if (value > alpha) {
              alpha = value;
              //best_move = move;
              if (value >= beta) {
                gotocut = true;
                break;
              }
            }
          }
        } // continue [1]
      }

      if (!gotocut) {
        // [2]

// ALL node

        if (best_value == ValueNone) {
          // no legal move
          //ASSERT(721, board_is_mate(board));
          return (height - ValueMate);
        }
      } // goto cut [2]
    } // goto cut [1]

// cut:

    //ASSERT(722, value_is_ok(best_value));

    return best_value;
  }

  int full_new_depth(
      int depth, int move, board_t board, bool single_reply, bool in_pv) {
    int new_depth; // int
    bool b = false; // bool

    //ASSERT(723, depth_is_ok(depth));
    //ASSERT(724, move_is_ok(move));

    //ASSERT(728, depth > 0);
    new_depth = depth - 1;

    b = b || (single_reply && ExtendSingleReply);
    b = b ||
        (in_pv &&
            MOVE_TO(move) == board.cap_sq &&
            see_move(move, board) > 0); // recapture
    b = b ||
        (in_pv &&
            PIECE_IS_PAWN(MOVE_PIECE(move, board)) &&
            PAWN_RANK(MOVE_TO(move), board.turn) == Rank7 &&
            see_move(move, board) >= 0);
    b = b || move_is_check(move, board);
    if (b) {
      new_depth++;
    }

    //ASSERT(729, new_depth >= 0 && new_depth <= depth);

    return new_depth;
  }

  bool do_null(board_t board) {
// use null move if the side-to-move has at least one piece
    return (board.piece_size[board.turn] >= 2); // king + one piece
  }

  bool do_ver(board_t board) {
// use verification if the side-to-move has at most one piece
    return (board.piece_size[board.turn] <= 2); // king + one piece
  }

  pv_fill(List<int> pv, int at, board_t board) {
    int move; // int
    int tmove; // int
    int tdepth; // int

    undo_t undo = new undo_t(); // undo_t[1]

    //ASSERT(734, UseTrans);
    move = pv[at];

    if (move != MoveNone && move != Movenull) {
      move_do(board, move, undo);
      pv_fill(pv, at + 1, board);
      move_undo(board, move, undo);

      tmove = move;
      tdepth = -127;
      TransRv.trans_min_value = -ValueInf;
      TransRv.trans_max_value = ValueInf;

      trans_store(Trans, board.key, tmove, tdepth, TransRv);
    }
  }

  bool move_is_dangerous(int move, board_t board) {
    int piece; // int

    //ASSERT(735, move_is_ok(move));
    //ASSERT(737, !move_is_tactical(move, board));
    piece = MOVE_PIECE(move, board);

    if (PIECE_IS_PAWN(piece) && PAWN_RANK(MOVE_TO(move), board.turn) >= Rank7)
      return true;

    return false;
  }

  int history_index(int move, board_t board) {
    int index; // int

    //ASSERT(882, move_is_ok(move));
    //ASSERT(884, !move_is_tactical(move, board));

    index = (PieceTo12[board.square[MOVE_FROM(move)]] << 6) +
        SquareTo64[MOVE_TO(move)];

    //ASSERT(885, index >= 0 && index < HistorySize);
    return index;
  }

  history_prob(int move, board_t board) {
    int value; // int
    int index; // int

    //ASSERT(865, move_is_ok(move));
    //ASSERT(867, !move_is_tactical(move, board));

    index = history_index(move, board);

    //ASSERT(868, HistHit[index] <= HistTot[index]);
    //ASSERT(869, HistTot[index] < HistoryMax);
    value = (HistHit[index] * 16384) ~/ HistTot[index];
    //ASSERT(870, value >= 0 && value <= 16384);

    return value;
  }

  int quiet_move_value(int move, board_t board) {
    int value; // int
    int index; // int

    //ASSERT(859, move_is_ok(move));
    //ASSERT(861, !move_is_tactical(move, board));

    index = history_index(move, board);
    value = HistoryScore + History[index];
    //ASSERT(862, value >= HistoryScore && value <= KillerScore - 4);

    return value;
  }

  note_quiet_moves(list_t list, board_t board) {
    int size; // int
    int i; // int
    int move; // int

    //ASSERT(845, list_is_ok(list));
    size = list.size;

    if (size >= 2) {
      for (i = 0; i < size; i++) {
        move = list.move[i];
        list.value[i] = quiet_move_value(move, board);
      }
    }
  }

  sort_next(sort_t sort) {
    int move; // int
    int gen; // int
    bool nocont;
    bool ifelse;

    for (;;) {
      while (sort.pos < sort.list.size) {
        nocont = true;

// next move
        move = sort.list.move[sort.pos];
        sort.value = 16384; // default score
        sort.pos++;

        //ASSERT(803, move != MoveNone);
// test
        ifelse = true;
        if (ifelse && (sort.test == TEST_NONE)) ifelse = false;

        if (ifelse && (sort.test == TEST_TRANS_KILLER)) {
          if (nocont && (!move_is_pseudo(move, sort.board))) nocont = false;

          if (nocont && (!pseudo_is_legal(move, sort.board))) nocont = false;

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_GOOD_CAPTURE)) {
          //ASSERT(804, move_is_tactical(move, sort.board));

          if (nocont && move == sort.trans_killer) nocont = false;

          if (nocont && (!capture_is_good(move, sort.board))) {
            LIST_ADD(sort.bad, move);
            nocont = false;
          }

          if (nocont && (!pseudo_is_legal(move, sort.board))) nocont = false;

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_BAD_CAPTURE)) {
          //ASSERT(805, move_is_tactical(move, sort.board));
          //ASSERT(806, (!capture_is_good(move, sort.board)));

          //ASSERT(807, move != sort.trans_killer);
          if (nocont && (!pseudo_is_legal(move, sort.board))) nocont = false;

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_KILLER)) {
          if (nocont && move == sort.trans_killer) nocont = false;

          if (nocont && (!quiet_is_pseudo(move, sort.board))) nocont = false;

          if (nocont && (!pseudo_is_legal(move, sort.board))) nocont = false;

          //ASSERT(808, (!nocont) || (!move_is_tactical(move, sort.board)));

          ifelse = false;
        }

        if (ifelse && (sort.test == TEST_QUIET)) {
          //ASSERT(809, !move_is_tactical(move, sort.board));

          if (nocont && move == sort.trans_killer) nocont = false;

          if (nocont && move == sort.killer_1) nocont = false;

          if (nocont && move == sort.killer_2) nocont = false;

          if (nocont && (!pseudo_is_legal(move, sort.board))) nocont = false;

          if (nocont) sort.value = history_prob(move, sort.board);

          ifelse = false;
        }

        if (ifelse) {
          //ASSERT(810, false);

          return MoveNone;
        }

        if (nocont) {
          //ASSERT(811, pseudo_is_legal(move, sort.board));
          return move;
        } // otherwise continue
      }

// next stage

      gen = Code[sort.gen];
      sort.gen++;

      ifelse = true;

      if (ifelse && (gen == GEN_TRANS)) {
        LIST_CLEAR(sort.list);
        if (sort.trans_killer != MoveNone) {
          LIST_ADD(sort.list, sort.trans_killer);
        }

        sort.test = TEST_TRANS_KILLER;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_GOOD_CAPTURE)) {
        gen_captures(sort.list, sort.board);
        note_mvv_lva(sort.list, sort.board);
        list_sort(sort.list);

        LIST_CLEAR(sort.bad);

        sort.test = TEST_GOOD_CAPTURE;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_BAD_CAPTURE)) {
        list_copy(sort.list, sort.bad);

        sort.test = TEST_BAD_CAPTURE;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_KILLER)) {
        LIST_CLEAR(sort.list);
        if (sort.killer_1 != MoveNone) {
          LIST_ADD(sort.list, sort.killer_1);
        }
        if (sort.killer_2 != MoveNone) {
          LIST_ADD(sort.list, sort.killer_2);
        }

        sort.test = TEST_KILLER;

        ifelse = false;
      }

      if (ifelse && (gen == GEN_QUIET)) {
        gen_quiet_moves(sort.list, sort.board);
        note_quiet_moves(sort.list, sort.board);
        list_sort(sort.list);

        sort.test = TEST_QUIET;

        ifelse = false;
      }

      if (ifelse) {
        //ASSERT(812, gen == GEN_END);

        return MoveNone;
      }

      sort.pos = 0;
    }
  }

  good_move(int move, board_t board, int depth, int height) {
    int index; // int
    int i; // int

    //ASSERT(825, move_is_ok(move));
    //ASSERT(827, depth_is_ok(depth));
    //ASSERT(828, height_is_ok(height));

    if (move_is_tactical(move, board)) return;

// killer
    if (Killer[height][0] != move) {
      Killer[height][1] = Killer[height][0];
      Killer[height][0] = move;
    }

    //ASSERT(829, Killer[height][0] == move);
    //ASSERT(830, Killer[height][1] != move);

// history
    index = history_index(move, board);

    History[index] += (depth * depth); // HISTORY_INC

    if (History[index] >= HistoryMax) {
      for (i = 0; i < HistorySize; i++) {
        History[i] = (History[i] + 1) ~/ 2;
      }
    }
  }

  history_good(int move, board_t board) {
    int index; // int

    //ASSERT(831, move_is_ok(move));
    if (move_is_tactical(move, board)) return;

// history
    index = history_index(move, board);

    HistHit[index]++;
    HistTot[index]++;

    if (HistTot[index] >= HistoryMax) {
      HistHit[index] = (HistHit[index] + 1) ~/ 2;
      HistTot[index] = (HistTot[index] + 1) ~/ 2;
    }

    //ASSERT(833, HistHit[index] <= HistTot[index]);
    //ASSERT(834, HistTot[index] < HistoryMax);
  }

  history_bad(int move, board_t board) {
    int index; // int

    //ASSERT(835, move_is_ok(move));

    if (move_is_tactical(move, board)) return;

// history
    index = history_index(move, board);

    HistTot[index]++;

    if (HistTot[index] >= HistoryMax) {
      HistHit[index] = (HistHit[index] + 1) ~/ 2;
      HistTot[index] = (HistTot[index] + 1) ~/ 2;
    }

    //ASSERT(837, HistHit[index] <= HistTot[index]);
    //ASSERT(838, HistTot[index] < HistoryMax);
  }

  capture_value(int move, board_t board) {
    //ASSERT(855, move_is_ok(move));
    //ASSERT(857, move_is_tactical(move, board));

    int value = mvv_lva(move, board);

    if (capture_is_good(move, board)) {
      value += GoodScore;
    } else {
      value += BadScore;
    }

    //ASSERT(858, value >= -30000 && value <= 30000);
    return value;
  }

  note_captures(list_t list, board_t board) {
    int size; // int
    int i; // int
    int move; // int

    //ASSERT(843, list_is_ok(list));
    size = list.size;

    if (size >= 2) {
      for (i = 0; i < size; i++) {
        move = list.move[i];
        list.value[i] = capture_value(move, board);
      }
    }
  }

  int move_value(move, board_t board, height, trans_killer) {
    int value; // int

    //ASSERT(851, move_is_ok(move));
    //ASSERT(853, height_is_ok(height));
    //ASSERT(854, trans_killer == MoveNone || move_is_ok(trans_killer));

    if (move == trans_killer) {
      // transposition table killer
      value = TransScore;
    } else {
      if (move_is_tactical(move, board)) {
        // capture || promote
        value = capture_value(move, board);
      } else {
        if (move == Killer[height][0]) {
          // killer 1
          value = KillerScore;
        } else {
          if (move == Killer[height][1]) {
            // killer 2
            value = KillerScore - 1;
          } else {
            // quiet move
            value = quiet_move_value(move, board);
          }
        }
      }
    }

    return value;
  }

  value_init() {
    ValuePiece[0] = -1;
    ValuePiece[1] = -1;

    ValuePiece[Empty] = 0; // needed?
    ValuePiece[Edge] = 0; // needed?

    ValuePiece[WP] = ValuePawn;
    ValuePiece[WN] = ValueKnight;
    ValuePiece[WB] = ValueBishop;
    ValuePiece[WR] = ValueRook;
    ValuePiece[WQ] = ValueQueen;
    ValuePiece[WK] = ValueKing;

    ValuePiece[BP] = ValuePawn;
    ValuePiece[BN] = ValueKnight;
    ValuePiece[BB] = ValueBishop;
    ValuePiece[BR] = ValueRook;
    ValuePiece[BQ] = ValueQueen;
    ValuePiece[BK] = ValueKing;
  }

  bool value_is_ok(int value) {
    if (value < -ValueInf || value > ValueInf) return false;

    return true;
  }

  bool range_is_ok(int min, int max) {
    if ((!value_is_ok(min)) || (!value_is_ok(max)) || (min >= max))
      return false; // alpha-beta-like ranges cannot be null

    return true;
  }

  bool value_is_mate(int value) {
    //ASSERT(954, value_is_ok(value));
    if (value < -ValueEvalInf || value > ValueEvalInf) return true;
    return false;
  }

  int value_to_trans(int value, int height) {
    //ASSERT(955, value_is_ok(value));
    //ASSERT(956, height_is_ok(height));

    if (value < -ValueEvalInf) {
      return (value - height);
    } else {
      if (value > ValueEvalInf) {
        return (value + height);
      }
    }
    return value;
  }

  int value_from_trans(int value, int height) {
    //ASSERT(958, value_is_ok(value));
    //ASSERT(959, height_is_ok(height));

    if (value < -ValueEvalInf) {
      return (value + height);
    } else {
      if (value > ValueEvalInf) {
        return (value - height);
      }
    }
    return value;
  }

  int value_to_mate(int value) {
    int dist; // int

    //ASSERT(961, value_is_ok(value));

    if (value < -ValueEvalInf) {
      dist = (ValueMate + value) ~/ 2;
      //ASSERT(962, dist > 0);

      return -dist;
    } else {
      if (value > ValueEvalInf) {
        dist = (ValueMate - value + 1) ~/ 2;
        //ASSERT(963, dist > 0);
        return dist;
      }
    }

    return 0;
  }

  main_init() {
// inits
    option_init();
    square_init();
    piece_init();
    pawn_init_bit();
    value_init();
    vector_init();
    attack_init();
    move_do_init();
    random_init();
    hash_init();
    inits();
    setstartpos();
  }

// randomized simplest opening case...
  bool randomopening(String mvlist) {
    int L = mvlist.length;

    if (L < 6) {
      int i = rnd.nextInt(10);

      String m = dumbOpeningBook[(L == 0 ? 0 : 1)][i];
      int j = (m.length > 5 ? 1 : 0);
      bestmv = substr(m, j, 2) + substr(m, 3 + j, 2);
      bestmv2 = m;

      return true;
    }

    return false;
  }

// AI vs AI game for testing...
  autogame() {
    String pgn = "";
    int mc = 0;
    String mlist = "";

    print_out("Autogame!");

    printboard();

    for (;;) {
      if (!randomopening(mlist)) {
        do_input("go movetime 4");
        //to see performance
        print_out("nodes: " + SearchCurrent.node_nb.toString());
      }

      if (mc % 2 == 0) {
        pgn += ((mc >>> 1) + 1).toString() + ".";
      }
      pgn += bestmv2 + " ";

      mlist += " " + bestmv;

      do_input("position moves" + mlist);
      printboard();

      print_out(pgn);

      if (board_is_mate(SearchInput.board)) {
        print_out(
            "Checkmate! " + (SearchInput.board.turn == White ? "0-1" : "1-0"));
        break;
      }
      if (board_is_stalemate(SearchInput.board)) {
        print_out("Stalemate  1/2-1/2");
        break;
      }

      if (mc > 400) {
        print_out("ups");
        break;
      }
      mc++;
    }
  }

//---

// The main program - all it starts here

  sample() {
//  do_input( "help" );
//  do_input( "position moves e2e4 e7e5 g1f3 g8f6 f1c4 f8c5 e1g1 e8g8" );
//  do_input( "go depth 5");
//  do_input( "go movetime 5");

// checkmate Qg7
//    do_input("position fen 7k/Q7/2P2K2/8/8/8/8/8 w - - 70 1");
//    printboard();
//    do_input("go");
//    print_out(bestmv2);

// checkmate in 3 moves    1.Bf7+ Kxf7 2.Qxg6+ Ke7 3.Qe6#
//    ShowInfo = true;
//    do_input("position fen r3kr2/pbq5/2pRB1p1/8/4QP2/2P3P1/PP6/2K5 w q - 0 36");
//    printboard();
//    do_input("go movetime 10");
//    print_out(bestmv2);

    autogame();
  }
}
