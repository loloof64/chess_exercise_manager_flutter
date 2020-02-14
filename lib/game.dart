import 'package:chess_exercise_manager/history_component.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_abstract_chess_board/flutter_abstract_chess_board.dart';
import 'package:flutter_abstract_chess_board/board_data_types.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'translations.dart';

import 'dart:async';

class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GamePageZone();
  }
}

class GamePageZone extends StatefulWidget {
  @override
  _GamePageZoneState createState() => _GamePageZoneState();
}

class _GamePageZoneState extends State<GamePageZone> {
  static const platform =
      const MethodChannel('loloof64.chess_utils/engine_discovery');
  ChessBoard _chessBoard;
  ChessHistoryComponent _historyComponent;
  IndexedStack _mainIndexStack;
  int _shownComponentIndex = 0;

  void _toggleShownComponent() {
    setState(() {
      _shownComponentIndex = 1 - _mainIndexStack.index;
    });
  }

  void _showHistoryComponent() {
    setState(() {
      _shownComponentIndex = 1;
    });
  }

  void _showBoardComponent() {
    setState(() {
      _shownComponentIndex = 0;
    });
  }

  String _toggleComponentButtonLabel() {
    return _mainIndexStack.index == 0
        ? allTranslations.text('game history')
        : allTranslations.text('game board');
  }

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
          title: Text(allTranslations.text('game_title')),
        ),
        body: Center(
            child: new OrientationBuilder(builder: (context, orientation) {
          _chessBoard = ChessBoard(
            orientation == Orientation.portrait
                ? screenDimensions.width - 20.0
                : screenDimensions.height - 90.0,
            gameEndedHandler: (type) => handleGameEnded(context, type),
            moveProducedCallback: (moveData) => print(moveData),
            startFen: startFen,
            whitePlayerType: whiteType,
            blackPlayerType: blackType,
            engineTurnCallback: _engineTurnHandler,
          );
          _historyComponent = ChessHistoryComponent(
            orientation == Orientation.portrait
                ? screenDimensions.width - 20.0
                : screenDimensions.height - 90.0,
          );
          _mainIndexStack = IndexedStack(
            children: <Widget>[
              _chessBoard,
              _historyComponent,
            ],
            index: _shownComponentIndex,
          );
          return Column(children: <Widget>[
            Row(
              children: <Widget>[
                RaisedButton(
                    onPressed: _toggleShownComponent,
                    child: Center(
                      child: Column(
                        children: <Widget>[
                          Icon(
                            CommunityMaterialIcons.history,
                            color: Colors.blue,
                          ),
                          Text(_toggleComponentButtonLabel()),
                        ],
                      ),
                    ))
              ],
            ),
            _mainIndexStack,
          ]);
        })));
  }

  void handleGameEnded(BuildContext context, EndType endType) {
    var message;
    switch (endType) {
      case EndType.WhiteCheckmate:
        message = allTranslations.text('white_checkmates');
        break;
      case EndType.BlackCheckmate:
        message = allTranslations.text('black_checkmates');
        break;
      case EndType.Stalemate:
        message = allTranslations.text('stalemate');
        break;
      case EndType.FiftyMovesDraw:
        message = allTranslations.text('fifty moves draw');
        break;
      case EndType.InsufficientMaterialDraw:
        message = allTranslations.text('insufficient material draw');
        break;
      case EndType.FoldRepetitionsDraw:
        message = allTranslations.text('three-fold repetitions draw');
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
    if (!line.startsWith('bestmove')) return;

    final moveStr = line.split(' ')[1];
    final CellCoordinates start =
        _coordinatesStringToCellCoordinates(moveStr.substring(0, 2));
    final CellCoordinates end =
        _coordinatesStringToCellCoordinates(moveStr.substring(2, 4));
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
