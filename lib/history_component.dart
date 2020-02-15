import 'package:flutter/material.dart';
import 'package:flutter_abstract_chess_board/board_data_types.dart';

class ChessHistoryComponent extends StatefulWidget {
  final double size;
  _ChessHistoryComponentState _state;

  ChessHistoryComponent(this.size){
    _state = _ChessHistoryComponentState();
  }

  addMove(MoveData move) {
    _state.addMove(move);
  }

  clear() {
    _state.clear();
  }

  @override
  _ChessHistoryComponentState createState() => _state;
}

class _ChessHistoryComponentState extends State<ChessHistoryComponent> {

  List<MoveData> _historyMoves = [];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    bool firstMove = true;

    for (MoveData moveData in _historyMoves) {
      if ((firstMove && ! moveData.whiteToPlay()) || moveData.whiteToPlay()) {
        children.add(Text(_moveLabel(moveData.moveNumber, moveData.whiteToPlay())));
      }
      children.add(FlatButton(child: Text(moveData.fan), onPressed: null,));
      if (firstMove &&  ! moveData.whiteToPlay()){
        children.add(Text(_moveLabel(moveData.moveNumber+1, ! moveData.whiteToPlay())));
      }
      firstMove = false;
    }

    return Container(
      width: widget.size, height: widget.size,
      color: Colors.black12,
      child: Wrap(
        spacing: 5.0,
        runSpacing: 9.0,
        children: children,
      ),
    );
  }

  _moveLabel(int moveNumber, bool whiteToPlay) {
    return whiteToPlay ? "$moveNumber." : "$moveNumber...";
  }

  clear() {
    setState(() {
      _historyMoves = [];
    });
  }

  addMove(MoveData move) {
    setState(() {
      _historyMoves.add(move);
    });
  }
}
