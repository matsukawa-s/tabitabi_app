import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/plan_search_provider.dart';

class PlanSearchDetailPage extends StatelessWidget {
  final double space = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('検索フィルタ'),
      ),
      body: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.all(space),
//        height: ,
        child: Container(
//          height: 100,
          child: ListView(
            children: [
              _listTitle('並べ替え'),
              _listItem('アップロード'),
              _listItem('お気に入り数'),
              _listItem('閲覧数'),
              _listItem('参考数'),
            ],
          ),
        ),
//        child: ListView.separated(
//            itemBuilder: (BuildContext context, int index) {
//              return _listItem(context,index);
//            },
//            separatorBuilder: (BuildContext context, int index) {
//              return _separatorItem();
//            },
//            itemCount: 1
//        ),
      ),
    );
  }

  Widget _listTitle(String title) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
              color:Colors.black,
              fontSize: 18.0
          ),
        ),
        onTap: () {
          print("onTap called.");
        }, // タップ
        onLongPress: () {
          print("onLongTap called.");
        }, // 長押し
      ),
    );
  }

  Widget _listItem(String name) {
    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
              color:Colors.black,
              fontSize: 18.0
          ),
        ),
        onTap: () {
          print("onTap called.");
        }, // タップ
        onLongPress: () {
          print("onLongTap called.");
        },
      ),
    );
  }

  Widget _separatorItem() {
    return Container(
      height: space,
//      color: Colors.orange,
    );
  }
}
