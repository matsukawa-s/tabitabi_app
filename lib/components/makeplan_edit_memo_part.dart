import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';

class MemoPart extends StatefulWidget {
  final String memoString;
  final bool confirmFlag;

  MemoPart({
    Key key,
    this.memoString,
    this.confirmFlag,
  }) : super(key: key);

  @override
  _MemoPartState createState() => _MemoPartState();
}

class _MemoPartState extends State<MemoPart> {
  double _opacity = 0.5;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      margin: BubbleEdges.only(right: MediaQuery.of(context).size.height / 40),
      alignment: Alignment.topRight,
      nip: BubbleNip.leftTop,
      color: widget.confirmFlag ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
      child: Text(
          widget.memoString,
          style: TextStyle(
            color: widget.confirmFlag ? Colors.white : Colors.white.withOpacity(_opacity),
            fontSize: 14.0,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.normal
          ),
      ),
    );
  }
}
