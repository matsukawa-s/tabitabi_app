import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'result_provider.dart';

class TodaysPlanPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final titleTextStyle = Theme.of(context).textTheme.title;
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Route"),
      ),
      body: Column(
        children: <Widget>[
          Text(
            Provider.of<ResultProvider>(context).count.toString(),
            style: TextStyle(
              fontSize: titleTextStyle.fontSize,
              color: titleTextStyle.color,
            ),
          ),
          RaisedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Go back!'),
          ),
        ],
      ),
      floatingActionButton: Consumer<ResultProvider>(
          builder: (_, model, __) {
            return FloatingActionButton(
              onPressed: model.increment,
              tooltip: 'Increment',
              child: Icon(Icons.add),
            );
          }
      ),
    );
  }
}