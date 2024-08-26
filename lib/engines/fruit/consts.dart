  //-----
  // Constants file for Fruit chess engine.
  //-----
  
  // Configurables

  // for move generator count of possible moves
  const int ListSize = 99; // int

  // can turn hashings on or off
  const bool UseTable = true; // bool
  const int MaterialTableSize = 64 * 1024; // size of Material hashing (array elements to use)
  const int PawnTableSize = 64 * 1024; // size of Pawn hashing (array elements to use)
  const bool UseTrans = true; // bool
  const int TransSize = 64 * 1024; // size of transp-table (array elements to use)
  const int TransDepth = 1; // int  transposition table

  const bool UseShortSearch = true; // bool
  const int ShortSearchDepth = 1; // int

  const bool DispBest = true; // bool
  const bool DispDepthStart = true; // bool
  const bool DispDepthEnd = true; // bool
  const bool DispRoot = true; // bool
  const bool DispStat = true; // bool

  const bool UseEasy = true; // bool  singular move
  const int EasyThreshold = 150; // int
  const double EasyRatio = 0.20; // double

  const bool UseEarly = true; // bool  early iteration end
  const double EarlyRatio = 0.60; // double

  const bool UseBad = true; // bool
  const int BadThreshold = 50; // int
  const bool UseExtension = true; // bool

  const bool UseDistancePruning = true; // bool  main search

  const bool UseMateValues = true; // bool   use mate values from shallower searches?

  const bool UseOpenFile = true; // bool
  const int RookSemiOpenFileOpening = 10; // int
  const int RookSemiOpenFileEndgame = 10; // int
  const int RookOpenFileOpening = 20; // int
  const int RookOpenFileEndgame = 20; // int
  const int RookSemiKingFileOpening = 10; // int
  const int RookKingFileOpening = 20; // int

  const bool UseKingAttack = true; // bool
  const int KingAttackOpening = 20; // int

  const bool UseShelter = true; // bool
  const int ShelterOpening = 256; // 100%  int
  const bool UseStorm = true; // bool
  const int StormOpening = 10; // int

  const bool UseIID = true; // bool move ordering
  const int IIDDepth = 3; // int
  const int IIDReduction = 2; // int

  const bool ExtendSingleReply = true; // bool

  const int HistoryDepth = 3; // int 
  const int HistoryMoveNb = 3; // int
  const bool HistoryReSearch = true; // bool

  const bool UseStrict = true; // bool
  const bool Strict = false; // bool
  const bool UseModulo = false; // bool

  // not sure it can be set less
  const int DepthMax = 64; // int
  const int HeightMax = 256; // int
  
  // Constants
  
  const int MAX_SAFE_INTEGER_52bit = 9007199254740991; // for JS conversion

  const int FileNb = 16; // int
  const int RankNb = 16; // int

  const int SquareNb = FileNb * RankNb; // int

  const int FileInc = 1; // int
  const int RankInc = 16; // int

  const int FileNone = 0; // int

  const int FileA = 0x4; // int
  const int FileB = 0x5; // int
  const int FileC = 0x6; // int
  const int FileD = 0x7; // int
  const int FileE = 0x8; // int
  const int FileF = 0x9; // int
  const int FileG = 0xA; // int
  const int FileH = 0xB; // int

  const int RankNone = 0; // int

  const int Rank1 = 0x4; // int
  const int Rank2 = 0x5; // int
  const int Rank3 = 0x6; // int
  const int Rank4 = 0x7; // int
  const int Rank5 = 0x8; // int
  const int Rank6 = 0x9; // int
  const int Rank7 = 0xA; // int
  const int Rank8 = 0xB; // int

  const int SquareNone = 0; // int

  // int
  const int A1=0x44, B1=0x45, C1=0x46, D1=0x47, E1=0x48, F1=0x49, G1=0x4A, H1=0x4B;
  const int A2=0x54, B2=0x55, C2=0x56, D2=0x57, E2=0x58, F2=0x59, G2=0x5A, H2=0x5B;
  const int A3=0x64, B3=0x65, C3=0x66, D3=0x67, E3=0x68, F3=0x69, G3=0x6A, H3=0x6B;
  const int A4=0x74, B4=0x75, C4=0x76, D4=0x77, E4=0x78, F4=0x79, G4=0x7A, H4=0x7B;
  const int A5=0x84, B5=0x85, C5=0x86, D5=0x87, E5=0x88, F5=0x89, G5=0x8A, H5=0x8B;
  const int A6=0x94, B6=0x95, C6=0x96, D6=0x97, E6=0x98, F6=0x99, G6=0x9A, H6=0x9B;
  const int A7=0xA4, B7=0xA5, C7=0xA6, D7=0xA7, E7=0xA8, F7=0xA9, G7=0xAA, H7=0xAB;
  const int A8=0xB4, B8=0xB5, C8=0xB6, D8=0xB7, E8=0xB8, F8=0xB9, G8=0xBA, H8=0xBB;

  const int Dark = 0; // int
  const int Light = 1; // int

  const int WhitePawnFlag = (1 << 2); // int
  const int BlackPawnFlag = (1 << 3); // int
  const int KnightFlag = (1 << 4); // int
  const int BishopFlag = (1 << 5); // int
  const int RookFlag = (1 << 6); // int
  const int KingFlag = (1 << 7); // int

  const int PawnFlags = (WhitePawnFlag | BlackPawnFlag); // int
  const int QueenFlags = (BishopFlag | RookFlag); // int

  const int PieceNone64 = 0; // int
  const int WhitePawn64 = WhitePawnFlag; // int
  const int BlackPawn64 = BlackPawnFlag; // int
  const int Knight64 = KnightFlag; // int
  const int Bishop64 = BishopFlag; // int
  const int Rook64 = RookFlag; // int
  const int Queen64 = QueenFlags; // int
  const int King64 = KingFlag; // int

  const int PieceNone256 = 0; // int
  const int WhitePawn256 = (WhitePawn64 | WhiteFlag); // int
  const int BlackPawn256 = (BlackPawn64 | BlackFlag); // int
  const int WhiteKnight256 = (Knight64 | WhiteFlag); // int
  const int BlackKnight256 = (Knight64 | BlackFlag); // int
  const int WhiteBishop256 = (Bishop64 | WhiteFlag); // int
  const int BlackBishop256 = (Bishop64 | BlackFlag); // int
  const int WhiteRook256 = (Rook64 | WhiteFlag); // int
  const int BlackRook256 = (Rook64 | BlackFlag); // int
  const int WhiteQueen256 = (Queen64 | WhiteFlag); // int
  const int BlackQueen256 = (Queen64 | BlackFlag); // int
  const int WhiteKing256 = (King64 | WhiteFlag); // int
  const int BlackKing256 = (King64 | BlackFlag); // int
  const int PieceNb = 256; // int

  const int WhitePawn12 = 0; // int
  const int BlackPawn12 = 1; // int
  const int WhiteKnight12 = 2; // int
  const int BlackKnight12 = 3; // int
  const int WhiteBishop12 = 4; // int
  const int BlackBishop12 = 5; // int
  const int WhiteRook12 = 6; // int
  const int BlackRook12 = 7; // int
  const int WhiteQueen12 = 8; // int
  const int BlackQueen12 = 9; // int
  const int WhiteKing12 = 10; // int
  const int BlackKing12 = 11; // int

  const List<int> PawnMake = [WhitePawn256, BlackPawn256]; // int[ColourNb]

  const List<int> PieceFrom12 = [
	WhitePawn256, BlackPawn256, WhiteKnight256, BlackKnight256,
	WhiteBishop256, BlackBishop256, WhiteRook256, BlackRook256,
	WhiteQueen256,  BlackQueen256, WhiteKing256, BlackKing256
  ]; // int[12]

  const String PieceString = "PpNnBbRrQqKk"; // char[12+1]

  const List<int> PawnMoveInc = [16, -16]; // int[ColourNb]

  const List<int> KnightInc = [-33, -31, -18, -14, 14, 18, 31, 33, 0]; // int[8+1]

  const List<int> BishopInc = [-17, -15, 15, 17, 0]; // int[4+1]

  const List<int> RookInc = [-16, -1, 1, 16, 0]; // int[4+1]

  const List<int> QueenInc = [-17, -16, -15, -1, 1, 15, 16, 17, 0]; // int[8+1]

  const List<int> KingInc = [-17, -16, -15, -1, 1, 15, 16, 17, 0]; // int[8+1]

  const List<int> SquareFrom64 = [
	A1, B1, C1, D1, E1, F1, G1, H1,
	A2, B2, C2, D2, E2, F2, G2, H2,
	A3, B3, C3, D3, E3, F3, G3, H3,
	A4, B4, C4, D4, E4, F4, G4, H4,
	A5, B5, C5, D5, E5, F5, G5, H5,
	A6, B6, C6, D6, E6, F6, G6, H6,
	A7, B7, C7, D7, E7, F7, G7, H7,
	A8, B8, C8, D8, E8, F8, G8, H8
  ]; // int[64]


  const int MAT_NONE = 0;
  const int MAT_KK = 1;
  const int MAT_KBK = 2;
  const int MAT_KKB = 3;
  const int MAT_KNK = 4;
  const int MAT_KKN = 5;
  const int MAT_KPK = 6;
  const int MAT_KKP = 7;
  const int MAT_KQKQ = 8;
  const int MAT_KQKP = 9;
  const int MAT_KPKQ = 10;
  const int MAT_KRKR = 11;
  const int MAT_KRKP = 12;
  const int MAT_KPKR = 13;
  const int MAT_KBKB = 14;
  const int MAT_KBKP = 15;
  const int MAT_KPKB = 16;
  const int MAT_KBPK = 17;
  const int MAT_KKBP = 18;
  const int MAT_KNKN = 19;
  const int MAT_KNKP = 20;
  const int MAT_KPKN = 21;
  const int MAT_KNPK = 22;
  const int MAT_KKNP = 23;
  const int MAT_KRPKR = 24;
  const int MAT_KRKRP = 25;
  const int MAT_KBPKB = 26;
  const int MAT_KBKBP = 27;
  const int MAT_NB = 28;

  const int DrawNodeFlag = (1 << 0); // int
  const int DrawBishopFlag = (1 << 1); // int
  const int MatRookPawnFlag = (1 << 0); // int
  const int MatBishopFlag = (1 << 1); // int
  const int MatKnightFlag = (1 << 2); // int
  const int MatKingFlag = (1 << 3); // int

  const int PawnPhase = 0; // int
  const int KnightPhase = 1; // int
  const int BishopPhase = 1; // int
  const int RookPhase = 2; // int
  const int QueenPhase = 4; // int
  const int TotalPhase = (PawnPhase * 16) + (KnightPhase * 4) + (BishopPhase * 4) +
	(RookPhase * 4) + (QueenPhase * 2); // int

  const int PawnOpening = 80; // was 100 int
  const int PawnEndgame = 90; // was 100 int
  const int KnightOpening = 325; // int
  const int KnightEndgame = 325; // int
  const int BishopOpening = 325; // int
  const int BishopEndgame = 325; // int
  const int RookOpening = 500; // int
  const int RookEndgame = 500; // int
  const int QueenOpening = 1000; // int
  const int QueenEndgame = 1000; // int

  const int BishopPairOpening = 50; // int
  const int BishopPairEndgame = 50; // int

  const int RandomPiece = 0;		// 12 * 64   int
  const int RandomCastle = 768;	// 4         int
  const int RandomEnPassant = 772;	// 8         int
  const int RandomTurn = 780;	// 1         int
  const int RandomNb = 781; // max size

  const int DateSize = 16; // int
  const int DepthNone = -128; // int
  const int ClusterSize = 4; // int, not a hash size

  const int MoveNone = 0; // int    a1a1 cannot be a legal move
  const int Movenull = 11; // int    a1d2 cannot be a legal move

  const int MoveNormal = (0 << 14); // int
  const int MoveCastle = (1 << 14); // int
  const int MovePromote = (2 << 14); // int
  const int MoveEnPassant = (3 << 14); // int
  const int MoveFlags = (3 << 14); // int

  const int MovePromoteKnight = (MovePromote | (0 << 12)); // int
  const int MovePromoteBishop = (MovePromote | (1 << 12)); // int
  const int MovePromoteRook = (MovePromote | (2 << 12)); // int
  const int MovePromoteQueen = (MovePromote | (3 << 12)); // int

  const List<int> PromotePiece = [Knight64, Bishop64, Rook64, Queen64]; // int[4]

  const int MoveAllFlags = (0xF << 12); // int

  const int TRUE = 1;
  const int FALSE = 0;

  const int ColourNone = -1; // int
  const int White = 0;
  const int Black = 1; // int
  const int ColourNb = 2; // int

  const int WhiteFlag = (1 << White); // int
  const int BlackFlag = (1 << Black); // int
  const int WxorB = (White ^ Black);
  const int bnot1 = (~1);
  const int bnot3 = (~3);
  const int bnotx77 = (~0x77);
  const int bnotxF = (~0xF);

  const int V07777 = 4095; // int
  const int bnotV07777 = (~V07777); // int

  const List<int> RankMask = [0, 0xF]; // int[ColourNb]
  const List<int> PromoteRank = [0xB0, 0x40]; // int[ColourNb]

  const int Empty = 0; // int
  const int Edge = Knight64; // int    uncoloured knight

  const int WP = WhitePawn256; // int
  const int WN = WhiteKnight256; // int
  const int WB = WhiteBishop256; // int
  const int WR = WhiteRook256; // int
  const int WQ = WhiteQueen256; // int
  const int WK = WhiteKing256; // int

  const int BP = BlackPawn256; // int
  const int BN = BlackKnight256; // int
  const int BB = BlackBishop256; // int
  const int BR = BlackRook256; // int
  const int BQ = BlackQueen256; // int
  const int BK = BlackKing256; // int

  const int FlagsNone = 0; // int
  const int FlagsWhiteKingCastle = (1 << 0); // int
  const int FlagsWhiteQueenCastle = (1 << 1); // int
  const int FlagsBlackKingCastle = (1 << 2); // int
  const int FlagsBlackQueenCastle = (1 << 3); // int

  const int StackSize = 4096; // int

  const int doubledOpening = 10; // int
  const int doubledEndgame = 20; // int

  const int IsolatedOpening = 10; // int
  const int IsolatedOpeningOpen = 20; // int
  const int IsolatedEndgame = 20; // int

  const int BackwardOpening = 8; // int
  const int BackwardOpeningOpen = 16; // int
  const int BackwardEndgame = 10; // int

  const int CandidateOpeningMin = 5; // int
  const int CandidateOpeningMax = 55; // int
  const int CandidateEndgameMin = 10; // int
  const int CandidateEndgameMax = 110; // int


  const int Opening = 0; // int
  const int Endgame = 1; // int
  const int StageNb = 2; // int

  // int
  const int pA1 = 0,  pB1 = 1,  pC1 = 2,  pD1 = 3,  pE1 = 4,  pF1 = 5,  pG1 = 6,  pH1 = 7;
  const int pA2 = 8,  pB2 = 9,  pC2 = 10, pD2 = 11, pE2 = 12, pF2 = 13, pG2 = 14, pH2 = 15;
  const int pA3 = 16, pB3 = 17, pC3 = 18, pD3 = 19, pE3 = 20, pF3 = 21, pG3 = 22, pH3 = 23;
  const int pA4 = 24, pB4 = 25, pC4 = 26, pD4 = 27, pE4 = 28, pF4 = 29, pG4 = 30, pH4 = 31;
  const int pA5 = 32, pB5 = 33, pC5 = 34, pD5 = 35, pE5 = 36, pF5 = 37, pG5 = 38, pH5 = 39;
  const int pA6 = 40, pB6 = 41, pC6 = 42, pD6 = 43, pE6 = 44, pF6 = 45, pG6 = 46, pH6 = 47;
  const int pA7 = 48, pB7 = 49, pC7 = 50, pD7 = 51, pE7 = 52, pF7 = 53, pG7 = 54, pH7 = 55;
  const int pA8 = 56, pB8 = 57, pC8 = 58, pD8 = 59, pE8 = 60, pF8 = 61, pG8 = 62, pH8 = 63;

  const int PawnFileOpening = 5; // int
  const int KnightCentreOpening = 5; // int
  const int KnightCentreEndgame = 5; // int
  const int KnightRankOpening = 5; // int
  const int KnightBackRankOpening = 0; // int
  const int KnightTrapped = 100; // int
  const int BishopCentreOpening = 2; // int
  const int BishopCentreEndgame = 3; // int
  const int BishopBackRankOpening = 10; // int
  const int BishopDiagonalOpening = 4; // int
  const int RookFileOpening = 3; // int
  const int QueenCentreOpening = 0; // int
  const int QueenCentreEndgame = 4; // int
  const int QueenBackRankOpening = 5; // int
  const int KingCentreEndgame = 12; // int
  const int KingFileOpening = 10; // int
  const int KingRankOpening = 10; // int


  const List<int> PawnFile = [-3, -1, 0, 1, 1, 0, -1, -3]; // int[8]

  const List<int> KnightLine = [-4, -2, 0, 1, 1, 0, -2, -4]; // int[8]

  const List<int> KnightRank = [-2, -1, 0, 1, 2, 3, 2, 1]; // int[8]

  const List<int> BishopLine = [-3, -1, 0, 1, 1, 0, -1, -3]; // int[8]

  const List<int> RookFile = [-2, -1, 0, 1, 1, 0, -1, -2]; // int[8]

  const List<int> QueenLine = [-3, -1, 0, 1, 1, 0, -1, -3]; // int[8]

  const List<int> KingLine = [-3, -1, 0, 1, 1, 0, -1, -3]; // int[8]

  const List<int> KingFile = [3, 4, 2, 0, 0, 2, 4, 3]; // int[8]

  const List<int> KingRank = [1, 0, -2, -3, -4, -5, -6, -7]; // int[8]


  const int SearchNormal = 0; // int
  const int SearchShort = 1; // int

  const int SearchUnknown = 0; // int
  const int SearchUpper = 1; // int
  const int SearchLower = 2; // int
  const int SearchExact = 3; // int

  const int NodeAll = -1; // int
  const int NodePV = 0; // int
  const int NodeCut = 1; // int

  const String StartFen =
      "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

  const int KillerNb = 2; // int

  const int HistorySize = 12 * 64; // int
  const int HistoryMax = 16384; // int

  const int TransScore = 32766; // int
  const int GoodScore = 4000; // int
  const int KillerScore = 4; // int
  const int HistoryScore = -24000; // int
  const int BadScore = -28000; // int

  const int CODE_SIZE = 256; // int

  const int GEN_ERROR = 0;
  const int GEN_LEGAL_EVASION = 1;
  const int GEN_TRANS = 2;
  const int GEN_GOOD_CAPTURE = 3;
  const int GEN_BAD_CAPTURE = 4;
  const int GEN_KILLER = 5;
  const int GEN_QUIET = 6;
  const int GEN_EVASION_QS = 7;
  const int GEN_CAPTURE_QS = 8;
  const int GEN_CHECK_QS = 9;
  const int GEN_END = 10;

  const int TEST_ERROR = 0;
  const int TEST_NONE = 1;
  const int TEST_LEGAL = 2;
  const int TEST_TRANS_KILLER = 3;
  const int TEST_GOOD_CAPTURE = 4;
  const int TEST_BAD_CAPTURE = 5;
  const int TEST_KILLER = 6;
  const int TEST_QUIET = 7;
  const int TEST_CAPTURE_QS = 8;
  const int TEST_CHECK_QS = 9;


  const int ValuePawn = 100; // was 100   int
  const int ValueKnight = 325; // was 300   int
  const int ValueBishop = 325; // was 300   int
  const int ValueRook = 500; // was 500   int
  const int ValueQueen = 1000; // was 900   int
  const int ValueKing = 10000; // was 10000 int

  const int ValueNone = -32767; // int
  const int ValueDraw = 0; // int
  const int ValueMate = 30000; // int
  const int ValueInf = ValueMate; // int
  const int ValueEvalInf = ValueMate - 256; // int handle mates upto 255 plies


  const int KnightUnit = 4; // int
  const int BishopUnit = 6; // int
  const int RookUnit = 7; // int
  const int QueenUnit = 13; // int

  const int MobMove = 1; // int
  const int MobAttack = 1; // int
  const int MobDefense = 0; // int

  const int KnightMobOpening = 4; // int
  const int KnightMobEndgame = 4; // int
  const int BishopMobOpening = 5; // int
  const int BishopMobEndgame = 5; // int
  const int RookMobOpening = 2; // int
  const int RookMobEndgame = 4; // int
  const int QueenMobOpening = 1; // int
  const int QueenMobEndgame = 2; // int
  const int KingMobOpening = 0; // int
  const int KingMobEndgame = 0; // int

  const int Rook7thOpening = 20; // int
  const int Rook7thEndgame = 40; // int
  const int Queen7thOpening = 10; // int
  const int Queen7Endgame = 20; // int

  const int TrappedBishop = 100; // int

  const int BlockedBishop = 50; // int
  const int BlockedRook = 50; // int

  const int PassedOpeningMin = 10; // int
  const int PassedOpeningMax = 70; // int
  const int PassedEndgameMin = 20; // int
  const int PassedEndgameMax = 140; // int

  const int UnstoppablePasser = 800; // int
  const int FreePasser = 60; // int

  const int AttackerDistance = 5; // int
  const int DefenderDistance = 20; // int

  const List<int> KingAttackWeight = [
	0, 0, 128, 192, 224, 240, 248, 252, 254, 255, 256, 256 ,256, 256, 256, 256
	];  // const int[16]

  const int IncNone = 0; // int
  const int IncNb = (2 * 17) + 1; // int
  const int IncOffset = 17; // int

  const int DeltaNone = 0; // int
  const int DeltaNb = (2 * 119) + 1; // int
  const int DeltaOffset = 119; // int

  const int BackRankFlag = (1 << 0); // int

  const List<List<String>> dumbOpeningBook = [
      [ "e2-e4", "d2-d4", "Ng1-f3", "Nb1-c3", "c2-c4", "g2-g3", "e2-e4", "c2-c3", "e2-e4", "d2-d4" ],
      [ "e7-e5", "d7-d5", "Ng8-f6", "Nb8-c6", "c7-c5", "g7-g6", "c7-c5", "c7-c6", "e7-e6", "g7-g6" ]
	];
