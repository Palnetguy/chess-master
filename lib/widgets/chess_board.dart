import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

class ChessBoard extends StatelessWidget {
  final String fen;

  ChessBoard({required this.fen});

  @override
  Widget build(BuildContext context) {
    chess.Chess chessGame = chess.Chess.fromFEN(fen);
    List<chess.Piece?> board = chessGame.board;

    return GridView.builder(
      itemCount: 64,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemBuilder: (context, index) {
        int x = index % 8;
        int y = (index / 8).floor();
        var piece = board[index];
        bool isLightSquare = (x + y) % 2 == 0;
        return Container(
          color: isLightSquare ? Colors.white : Colors.grey,
          child: piece != null
              ? Center(
                  child: Text(_getPieceSymbol(piece.type.name, piece.color)))
              : null,
        );
      },
    );
  }

  String _getPieceSymbol(String pieceType, chess.Color color) {
    Map<String, String> symbols = {
      'p': '♟',
      'r': '♜',
      'n': '♞',
      'b': '♝',
      'q': '♛',
      'k': '♚'
    };
    String symbol = symbols[pieceType.toLowerCase()]!;
    return color == chess.Color.WHITE ? symbol.toUpperCase() : symbol;
  }
}
