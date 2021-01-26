import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tabitabi_app/components/add_tag_part.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:tabitabi_app/data/tag_data.dart';

class AddTagPage extends StatefulWidget {
  @override
  _AddTagPageState createState() => _AddTagPageState();
}

class _AddTagPageState extends State<AddTagPage> {

  //追加済タグ
  List<TagData> _addTag = [];
  //オススメタグ
  List<TagData> _recommendTag = [];

  String text;
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();

    _addTag = context.read<TagDataProvider>().tagData;
    _textEditingController = TextEditingController();
    _getTag();
  }

  void _getTag() async{
    http.Response res = await Network().getData("tag/all/get");
    var list = jsonDecode(res.body);
    print(res.body);

    setState(() {
      for(int i=0; i<list.length; i++){
        _recommendTag.add(TagData(list[i]["id"], list[i]["tag_name"]));
      }
    });
  }

  //タグ追加
  void _onTapAddButton() async{
    //入力が何もないときは何もしない
    if(text == null || text == "" || text.length < 2){
      return null;
    }
    //既に同じ名前のタグが入っていないか調べる
    if(_addTag.indexWhere((element) => element.tagName == text) != -1){
      _textEditingController.text = "";
      return null;
    }

    //タグをDBに追加
    final tagData = {
      "tag_name" : text,
    };

    http.Response res2 = await Network().postData(tagData, "tag/store");
    print("res2" + res2.body);

    var list = jsonDecode(res2.body);


    //プロバイダーに追加
    setState(() {
      context.read<TagDataProvider>().addTagData(TagData(list["id"], text));
      _addTag = context.read<TagDataProvider>().tagData;
      _textEditingController.text = "";
    });
  }

  //タグの削除
  _removeTag(int index){
    TagData data = _addTag[index];
    context.read<TagDataProvider>().removeTagData(index);
    print("消すよ"+index.toString());
    setState(() {
      _addTag = context.read<TagDataProvider>().tagData;
      _recommendTag.add(data);
    });
  }

  //リコメンドからタグ追加
  _addToRecommend(TagData tagData){
    //既にタグに追加されているか判定
    if(_addTag.indexWhere((element) => element.tagName == tagData.tagName) != -1){
      return null;
    }

    context.read<TagDataProvider>().addTagData(tagData);
    setState(() {
      _addTag = context.read<TagDataProvider>().tagData;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("タグの追加"),
        backgroundColor: Colors.white.withOpacity(0.7),
        actions: [
          Align(
            widthFactor: 1.0,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                child: Text("決定", style: TextStyle(fontSize: 17.0),),
                onTap: (){
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text("目的に合ったタグを追加しよう！"),
            )
          ),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 20.0, top: 20.0),
                height: 50.0,
                width: MediaQuery.of(context).size.width - MediaQuery.of(context).size.width / 3 + 30,
                child: TextField(
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    hintText: "追加したいタグを入力",
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xffACACAC),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  style: TextStyle(color: Colors.black),
                  onChanged: (value){text = value;},
                  onSubmitted: (value){_onTapAddButton();},
                ),
              ),
              GestureDetector(
                child: Container(
                  margin: EdgeInsets.only(left: 10.0, top: 20.0, right: 20.0),
                  height: 48,
                  width: MediaQuery.of(context).size.width / 3 - 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text("追加", style: TextStyle(color: Colors.white),),
                  ),
                ),
                onTap: (){
                  _onTapAddButton();
                },
              )
            ],
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              height: 3,
              width: MediaQuery.of(context).size.width - 50,
              child: Divider(
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0, left: 20.0),
            child: Text("追加済(タップで削除！)"),
          ),
          if(_addTag.length != 0)
            Container(
              margin: EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
              child: Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: [
                  for(int i=0; i<_addTag.length; i++)
                    GestureDetector(
                      child: AddTagPart(title: _addTag[i].tagName),
                      onTap: (){
                        _removeTag(i);
                      },
                    )
                ],
              ),
            ),
          if(_addTag.length == 0)
            Center(
              child: Container(
                color: Color(0xffE5E5E5),
                height: 100,
                width: 300,
                margin: EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("まだタグは追加されていません！"),
                    Text("新しいタグを追加しよう！"),
                  ],
                ),
              ),
            ),
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              height: 3,
              width: MediaQuery.of(context).size.width - 50,
              child: Divider(
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0, left: 20.0),
            child: Text("よく使われるタグ　(タップで追加！)"),
          ),
          Container(
            margin: EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                for(int i=0; i<_recommendTag.length; i++)
                  GestureDetector(
                    child: RecommendTagPart(title: _recommendTag[i].tagName),
                    onTap: (){
                      _addToRecommend(_recommendTag[i]);
                      setState(() {
                        _recommendTag.removeAt(i);
                      });
                    },
                  )
              ],
            ),
          ),
        ],
      )
    );
  }
}
