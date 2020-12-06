import 'package:flutter/material.dart';

class AddTagPart extends StatelessWidget {
  final String title;

  AddTagPart({
    Key key,
    this.title,
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 40,
      width:  (title.length.toDouble() * 20) + 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).primaryColor,
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(left: 10.0, top: 3.0,bottom: 3.0),
            padding: EdgeInsets.only(right: 10.0),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white,
                  width: 1
                )
              )
            ),
            child: Text("×", style: TextStyle(color: Colors.white, fontSize: 24.0),)
          ),
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text("#" + title, style: TextStyle(color: Colors.white),),
          ),
        ],
      )
    );
  }
}

class RecommendTagPart extends StatelessWidget {

  final String title;

  RecommendTagPart({
    Key key,
    this.title
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1),
      ),
      child: Text("#" + title),
    );
  }
}

class TagPart extends StatelessWidget {
  final String title;
  TagPart({
    Key key,
    this.title
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).primaryColor,
      ),
      child: Text("#" + title, style: TextStyle(color: Colors.white),),
    );
  }
}


