import 'package:chess/chess.dart' as chess;

class ChessGame {
  final chess.Chess chessGame;

  ChessGame([chess.Chess? chessInstance])
      : chessGame = chessInstance ?? chess.Chess();
}
