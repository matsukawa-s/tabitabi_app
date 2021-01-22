import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/plan_search_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'model/Tag.dart';

class PlanSearchHistoryPage extends StatelessWidget {
  Color iconColor = Colors.orange[300];

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanSearchModel>(
        builder: (_, model, __) {
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
                  controller: model.searchController,
                  onChanged: (String keyword){
                    if(keyword.length <= 0){
                      model.changeTagFlag(false);
                    }else{
                      if(keyword.substring(0,1) == "#"){
                        String key = keyword.substring(1);
                        model.changeTagFlag(true);
                        model.setTagKeyword(keyword.substring(1));
                        model.fetchPostTags();
                      }else{
                        model.changeTagFlag(false);
                      }
                    }
                  },
                  onSubmitted: (String keyword) {
                    if(keyword.isEmpty){
                      model.setKeyword(keyword);
                      Navigator.of(context).pop();
                    }else{
                      if(keyword.substring(0,1) != "#"){
                        // 検索キーワードが isNotEmpty のとき履歴に保存
                        if(keyword.isNotEmpty){
                          model.setHistory(keyword);
                        }
                        model.setKeyword(keyword);
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  cursorColor: iconColor,
                  decoration: InputDecoration(
//              border: OutlineInputBorder(
//                borderRadius: BorderRadius.circular(25.0),
//                  borderSide: BorderSide
//                    color: Colors.white,
//                  ),
//              ),
                    border: InputBorder.none,
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    hintText: "先頭に # でタグ検索になります",
                    suffixIcon: IconButton(
                      onPressed: (){
                        model.searchController.clear();
                        model.changeTagFlag(false);
                      },
                      icon: Icon(Icons.clear),
                    ),
//              fillColor: Colors.grey[100],
                  ),
                ),
            ),
            body: (model.tagFlag) ?
//              FutureBuilder(
//                future:model.fetchPostTags(),
//                builder:  (BuildContext context, AsyncSnapshot snapshot){
//                  if(snapshot.hasData){
////                    final List<String>history = snapshot.data;
//                    if(model.sugTagKeys.length == 0){
//                      return Center(
//                          child: Text(model.searchController.text + ' に一致するタグは見つかりませんでした。')
//                      );
//                    }else{
//                      return ListView.builder(
//                        itemCount: model.sugTagKeys.length,
//                        itemBuilder: (BuildContext context, int index) {
//                          Tag tag = model.sugTagKeys[index];
//                          return keywordTag(tag, model, context);
//                        },
//                      );
//                    }
//                  }else{
//                    return Center(child: CircularProgressIndicator());
//                  }
//                }
//              )  :
              model.sugTagKeys.length == 0 ?
                Center(
                  child: Text(model.searchController.text + ' に一致するタグは見つかりませんでした。')
                ) :
                ListView.builder(
                  itemCount: model.sugTagKeys.length,
                  itemBuilder: (BuildContext context, int index) {
                    Tag tag = model.sugTagKeys[index];
                    return keywordTag(tag, model, context);
                  },
                ) :
              FutureBuilder(
                future: model.getHistory(),
                builder: (BuildContext context, AsyncSnapshot snapshot){
                  if(snapshot.hasData){
//                    final List<String>history = snapshot.data;
                    var history = snapshot.data;
                    return (history.length == 0) ?
                    Container() :
                    Column(
                      children: [
                        allClearButton(model),
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
                                          model.removeHistory(history[index]);
                                      },
                                    ),
                                  ],
                                  child: ListTile(
                                    title:Text(history[index]),
                                    onTap: (){
                                      model.setKeyword(history[index]);
                                      model.setHistory(history[index]);
                                      model.searchController.text = history[index];
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
                    return Center(child: CircularProgressIndicator());
                  }
                }),
          );
        }
    );
  }

  Widget keywordTag(Tag tag, model, context){
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (){
        // 検索履歴ページのテキストフィールドを更新
        model.searchController.text = "#" + tag.name;
        // 検索結果ページのテキストフィールドを更新
        model.setKeyword("#" + tag.name);
        // タグ候補を更新
        model.fetchPostTagsList(tag.name);
        // 検索結果ページに遷移
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 10,right: 20, left: 20, bottom: 2),
            child: Text(
              '# ' + tag.name,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 2,right: 20, left: 20, bottom: 10),
            child: Text(
              "投稿 " + tag.count.toString() + "件",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        ],
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

  Widget allClearButton(model){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            model.removeAllHistory();
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
