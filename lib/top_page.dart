import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TopPage extends StatelessWidget {
  final String title;

  TopPage({@required this.title});

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.title;
    return Container(
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleTextStyle.fontSize,
                color: titleTextStyle.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
//          FloatingActionButton(
//            onPressed: (){},
//            tooltip: 'Increment',
//            child: Icon(Icons.add),
//          ),
}