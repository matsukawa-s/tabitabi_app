import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/plan_search_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PlanSearchHistoryPage extends StatefulWidget {
  // textfield の　コントローラー
  @override
  _PlanSearchHistoryPageState createState() => _PlanSearchHistoryPageState();
}

class _PlanSearchHistoryPageState extends State<PlanSearchHistoryPage> {
  var _searchWord = TextEditingController();

  var prefsKey = 'plan_search_history';

  Color iconColor = Colors.orange[300];

  // プラン検索キーワードを保存
  Future setHistory(value) async {
    //検索履歴を保存する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    if (prefs.containsKey(prefsKey)) {
      history = prefs.getStringList(prefsKey);
      print(history);
      // すでに履歴に検索キーワードがあるとき
      if(history.contains(value)){
        // 検索キーワードのインデックスを取得
        var index = history.indexOf(value);
        // 既存のアイテムを削除
        history.removeAt(index);
      }
    }
    history.add(value);
    prefs.setStringList(prefsKey, history);
  }

  // プラン検索履歴を取得
  Future getHistory() async {
    //検索履歴を表示
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    if (prefs.containsKey(prefsKey)) {
      history = prefs.getStringList(prefsKey).reversed.toList();
    }
    return history;
  }

  // 1つのプラン検索履歴を削除
  Future removeHistory(keyword) async {
    //検索履歴を保存する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    if (prefs.containsKey(prefsKey)) {
      history = prefs.getStringList(prefsKey);
      // すでに履歴に検索キーワードがあるとき
      if(history.contains(keyword)){
        // 検索キーワードのインデックスを取得
        var index = history.indexOf(keyword);
        // 既存のアイテムを削除
        history.removeAt(index);
      }
    }
    prefs.setStringList(prefsKey, history);
  }

  // 全てのプラン検索履歴を削除
  Future removeAllHistory() async {
    //検索履歴を保存する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    prefs.setStringList(prefsKey, history);
  }

  @override
  Widget build(BuildContext context) {
    var _searchWord =
    TextEditingController(text: Provider.of<PlanSearchModel>(context).keyword);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          color: iconColor,
          icon: new Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          autofocus: true,
          controller: _searchWord,
          onSubmitted: (String value) {
            Provider.of<PlanSearchModel>(context,listen: false).setKeyword(value);
            // 検索キーワードが空じゃないとき履歴に保存
            if(value.isNotEmpty){
              setHistory(value);
            }
            Navigator.of(context).pop();
          },
//          cursorColor: iconColor,
          decoration: InputDecoration(
//              border: OutlineInputBorder(
//                borderRadius: BorderRadius.circular(25.0),
//                  borderSide: BorderSide(
//                    color: Colors.white,
//                  ),
//              ),
            border: InputBorder.none,
            filled: true,
            hintStyle: TextStyle(color: Colors.grey[500]),
            hintText: "Type in your text",
            suffixIcon: IconButton(
              onPressed: () => _searchWord.clear(),
              icon: Icon(Icons.clear),
            ),
//              fillColor: Colors.grey[100],
          ),
        ),
      ),
      body: FutureBuilder(
        future: getHistory(),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.hasData){
            final List<String>history = snapshot.data;
//            var history = snapshot.data;
            return (history.length == 0) ?
            Container() :
            Column(
              children: [
                allClearButton(),
                Expanded(
                  child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder:(BuildContext context, int index){
                        return Slidable(
                          // スライド表示する action の比率
                          actionExtentRatio: 0.2,
                          // スライド時のアニメーション
                          actionPane: SlidableScrollActionPane(),
                          // 右側に表示するWidget
                          secondaryActions: [
                            IconSlideAction(
                              caption: '削除',
                              color: Colors.red,
                              icon: Icons.remove,
                              onTap: () {
                                setState(() {
                                  removeHistory(history[index]);
                                });
                              },
                            ),
                          ],
                          child: ListTile(
                            title:Text(history[index]),
                            onTap: (){
                              Provider.of<PlanSearchModel>(context,listen: false).setKeyword(history[index]);
                              setHistory(history[index]);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      }
                  ),
                ),
              ],
            );
          }else{
            return CircularProgressIndicator();
          }
        }),
    );
  }
  Widget allClearButton(){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            setState(() {
              removeAllHistory();
            });
          },
          child: Text("全て削除",
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.grey
            ),
          ),
        )
    );
  }
}
