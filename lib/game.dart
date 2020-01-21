import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_abstract_chess_board/flutter_abstract_chess_board.dart';

import 'dart:async';

class GamePage extends StatelessWidget {
  static const platform =
      const MethodChannel('loloof64.chess_utils/engine_discovery');

  @override
  Widget build(BuildContext context) {
    platform.setMethodCallHandler(_processEngineOutput);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chess exercises manager'),
      ),
      body: Center(
        child: ChessBoard(
            MediaQuery.of(context).size.width
        ),
      ),
    );
  }

  Future<void> _getEngineOutput() async {
    try {
      var positionFen = "8/6k1/8/6p1/6P1/4K2P/8/8 w - - 0 1";
      await platform.invokeMethod("sendCommandToEngine", 'ucinewgame');
      await platform.invokeMethod(
          "sendCommandToEngine", "position fen $positionFen");
      await platform.invokeMethod("sendCommandToEngine", "go depth 14");
    } catch (e) {
      print("Failed to get engine output: $e");
    }
  }

  Future<void> _processEngineOutput(MethodCall call) async {
    if (call.method != 'processEngineOutput') return;
    var line = call.arguments;
    print(line);
  }
}
