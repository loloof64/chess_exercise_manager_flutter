import 'package:flutter/material.dart';

class ChessHistoryComponent extends StatefulWidget {
  final double size;

  ChessHistoryComponent(this.size);

  @override
  _ChessHistoryComponentState createState() => _ChessHistoryComponentState();
}

class _ChessHistoryComponentState extends State<ChessHistoryComponent> {
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

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
}
