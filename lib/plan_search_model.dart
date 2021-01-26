import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/model/plan.dart';
import 'package:tabitabi_app/network_utils/api.dart';

import 'model/Tag.dart';


class PlanSearchModel with ChangeNotifier {
  //検索履歴を保存するローカルストレージ
  var prefsKey = 'plan_search_history';
  var searchController = TextEditingController();
  void setSearchControllerText(text){
    searchController.text = text;
    notifyListeners();
  }
  // プランリスト
  List<Plan> _plans;
  get plans => _plans;
  void setPlans(planList) {
    _plans = planList;
  }

  // 検索キーワード
  String _keyword = "";
  get keyword => _keyword;
  void setKeyword(keyword){
    _keyword = keyword;
    fetchPostPlans();
    notifyListeners();
  }

//   タグ検索キーワード
  String _tagKeyword = "";
  get tagKeyword => _tagKeyword;
  void setTagKeyword(keyword){
    _tagKeyword = keyword;
    notifyListeners();
  }

  //タグ検索なら true
  bool _tagFlag = false;
  get tagFlag => _tagFlag;
  void changeTagFlag(bool flag){
    _tagFlag = flag;
    notifyListeners();
  }

  // ソートのインデックス
  var _sortIndex = 0;
  get sortIndex => _sortIndex;
  void setSort(sort) {
    if(_sortIndex == sort){
      _sortIndex = 0;
    }else{
      _sortIndex = sort;
    }
    fetchPostPlans();
    notifyListeners();
  }
  // suggested tag keywords
  var _sugTagKeys = [];
  get sugTagKeys => _sugTagKeys;
  void setSugTagKeys(tags){
    _sugTagKeys = tags;
  }

  // plan search post送信
  Future fetchPostPlans() async {
    var url;
    var plansRes;
    var plans;
    Map data;

    var _sortItems = ["created_at","favorite_count","number_of_views","referenced_number"];
//    var _orders = ["asc","desc","desc","desc"];
    data = {
      "column" : _sortItems[_sortIndex],
      "order" : "desc",
    };

    print(_keyword);
    // 検索キーワードなし、あり
    if(_keyword == ""){
      url = 'index';
      plansRes = await Network().postData(data, url);
    }else{
      if(_keyword.substring(0,1) == "#"){
        url = 'tagSearch/' + _keyword.substring(1);
      }else{
        url = 'search/' + _keyword;
      }
      plansRes = await Network().postData(data, url);
    }

    if(plansRes.statusCode == 200){
      List tmp = jsonDecode(plansRes.body);
      plans = List.generate(
          tmp.length, (index) => Plan.fromJson(tmp[index])
      );
    }else{
      print(plansRes.statusCode);
    }
    setPlans(plans);
    notifyListeners();
  }

  // post送信 タグ検索候補を取得
  Future fetchPostTags() async {
    var url;
    var plansRes;
    var tags = [];

    if(_tagKeyword.length > 0){
      url = 'tag/' + _tagKeyword;
    }else{
      url = 'tag';
    }
    plansRes = await Network().getData(url);

//    print(url);
//    print(plansRes.statusCode);
    if(plansRes.statusCode == 200){
      List tmp = jsonDecode(plansRes.body);
      tags = List.generate(
          tmp.length, (index) => Tag.fromJson(tmp[index])
      );
    }else{
      print(plansRes.statusCode);
      print(plansRes.body);
    }
    setSugTagKeys(tags);
    notifyListeners();

    return _sugTagKeys;
  }

  // お気に入り処理
  void setFavoriteChange(index){
    var _plan = _plans[index];
    if(_plan.isFavorite){
      _plan.favoriteCount -= 1;
    }else{
      _plan.favoriteCount += 1;
    }
    _plan.isFavorite = !_plan.isFavorite;
    notifyListeners();
  }

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
      notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }

  // 全てのプラン検索履歴を削除
  Future removeAllHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = [];
    // 空のリストで上書きして検索履歴を削除
    prefs.setStringList(prefsKey, history);
    notifyListeners();
  }
}