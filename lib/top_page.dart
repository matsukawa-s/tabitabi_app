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

  Widget appBar(){
    Color iconColor = Colors.orange[300];
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          color: iconColor,
          icon: new Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined),
          color: iconColor,
          onPressed: () {

          },
        ),
      ],
    );
  }

  Widget floatingActionButton(){
    return FloatingActionButton(
      onPressed: (){},
      tooltip: 'Increment',
      child: Icon(Icons.add),
    );
  }
}