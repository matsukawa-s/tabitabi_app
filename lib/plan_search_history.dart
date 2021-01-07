import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/plan_search_model.dart';

class PlanSearchHistoryPage extends StatelessWidget {
  // textfield の　コントローラー
  var _searchWord = TextEditingController();
  var prefsKey = 'plan_search_history';
  Color iconColor = Colors.orange[300];

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

  Future getHistory() async {
    //検索履歴を表示する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    if (prefs.containsKey(prefsKey)) {
      history = prefs.getStringList(prefsKey).reversed.toList();
      return history;
    } else {
      return [];
    }
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
            setHistory(value);
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
            final List<String> history = snapshot.data;
            return (history.length == null) ? Container() : ListView.builder(
                itemCount: history.length,
                itemBuilder:(BuildContext context, int index){
                  return ListTile(
                    title:Text(history[index]),
                    onTap: (){
                      Provider.of<PlanSearchModel>(context,listen: false).setKeyword(history[index]);
                      setHistory(history[index]);
                      Navigator.of(context).pop();
                    },
                  );
                }
            );
          }else{
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
