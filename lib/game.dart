import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_abstract_chess_board/flutter_abstract_chess_board.dart';

import 'dart:async';

class GamePage extends StatelessWidget {
  static const platform =
      const MethodChannel('loloof64.chess_utils/engine_discovery');
  ChessBoard _chessBoard;

  @override
  Widget build(BuildContext context) {
    platform.setMethodCallHandler(_processEngineOutput);

    final screenDimensions = MediaQuery.of(context).size;

    final startFen = '4k3/8/8/3KP3/8/8/8/8 w - - 0 1';
    final whiteToPlayFirst = startFen.split(' ')[1] == 'w';
    final whiteType = whiteToPlayFirst ? PlayerType.Human : PlayerType.Computer;
    final blackType = whiteToPlayFirst ? PlayerType.Computer : PlayerType.Human;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chess exercises manager'),
      ),
      body: Center(
        child: new OrientationBuilder(builder: (context, orientation) {
          _chessBoard = ChessBoard(
            orientation == Orientation.portrait ? screenDimensions.width - 20.0 : screenDimensions.height - 90.0,
            gameEndedHandler: (type) => handleGameEnded(context, type),
            startFen: startFen,
            whitePlayerType: whiteType,
            blackPlayerType: blackType,
            engineTurnCallback: _engineTurnHandler,
          );
          return _chessBoard;
        }),
      ),
    );
  }

  void handleGameEnded(BuildContext context, EndType endType) {
    var message;
    switch (endType) {
      case EndType.WhiteCheckmate:
        message = "Whites checkmate";
        break;
      case EndType.BlackCheckmate:
        message = "Blacks checkmate";
        break;
      case EndType.Stalemate:
        message = "Stalemate";
        break;
      case EndType.FiftyMovesDraw:
        message = "Draw by 50 moves rule";
        break;
      case EndType.InsufficientMaterialDraw:
        message = "Draw by insuficient material";
        break;
      case EndType.FoldRepetitionsDraw:
        message = "Draw by 3-folds repetitions";
        break;
      default:
        return;
    }
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _engineTurnHandler(String currentPosition) {
    _getEngineOutputAndProcessIt(currentPosition)
        .then((value) {})
        .catchError((err) {
          print("Failed to run engine turn handler: $err");
    });
  }

  Future<void> _getEngineOutputAndProcessIt(String currentPosition) async {
    try {
      await platform.invokeMethod("sendCommandToEngine", 'ucinewgame');
      await platform.invokeMethod(
          "sendCommandToEngine", "position fen $currentPosition");
      await platform.invokeMethod("sendCommandToEngine", "go depth 20");
    } catch (e) {
      print("Failed to get engine output: $e");
    }
  }

  Future<void> _processEngineOutput(MethodCall call) async {
    if (call.method != 'processEngineOutput') return;
    String line = call.arguments;
    if ( ! line.startsWith('bestmove') ) return;

    final moveStr = line.split(' ')[1];
    final CellCoordinates start = _coordinatesStringToCellCoordinates(moveStr.substring(0, 2));
    final CellCoordinates end = _coordinatesStringToCellCoordinates(moveStr.substring(2, 4));
    final MoveCoordinates move = MoveCoordinates(start: start, end: end);
    final String promotion = moveStr.length >= 5 ? moveStr[4] : null;

    _chessBoard.tryToCommitComputerMove(move, promotion);
  }

  CellCoordinates _coordinatesStringToCellCoordinates(String coordinates) {
    final asciiCodeA = 97;
    final asciiCode1 = 49;

    final file = coordinates.codeUnitAt(0) - asciiCodeA;
    final rank = coordinates.codeUnitAt(1) - asciiCode1;

    return CellCoordinates(file: file, rank: rank);
  }
}
