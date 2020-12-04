import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tabitabi_app/network_utils/api.dart';


class PlanSearchProvider with ChangeNotifier {
  SearchProvider(){
    fetchPostPlansList();
  }

  // プランリスト
  List _searchplanlist;
  get searchplanlist => _searchplanlist;
  void setSearchPlanList(planList) {
    _searchplanlist = planList;
  }

  // 検索キーワード
  String _keyword = "";
  get keyword => _keyword;
  void setKeyword(keyword){
    _keyword = keyword;
    fetchPostPlansList();
    notifyListeners();
  }

  // ソートのインデックス
  var _sortIndex = null;
  get sortIndex => _sortIndex;
  void setSort(sort) {
    if(_sortIndex == sort){
      _sortIndex = null;
    }else{
      _sortIndex = sort;
    }
    fetchPostPlansList();
    notifyListeners();
  }

  // plan search post送信
  Future fetchPostPlansList() async {
    var url;
    var response;
    Map data;

    if(_sortIndex != null){
      var _sortItems = ["created_at","favorite_count","number_of_views","referenced_number"];
      var _orders = ["asc","desc","desc","desc"];
      data = {
        "column" : _sortItems[_sortIndex],
        "order" : _orders[_sortIndex],
      };
      print(data["col-index"]);
    }

    print(_keyword);

    if(_keyword == ""){
      url = 'index';
      response = await Network().postData(data, url);
    }else{
      url = 'test/' + _keyword;
      response = await Network().postData(data, url);
    }

    print(convert.jsonDecode(response.body));
    var plans = convert.jsonDecode(response.body);
    setSearchPlanList(plans);
    notifyListeners();
  }

  // お気に入りカウントアップ
  favoritePlan(userId,favoritePlanId) async {
    Map data = {
      'user_id' : userId,
      'favorite_plan_id' : favoritePlanId,
    };
    var url = 'http://10.0.2.2:8000/api/favoritePlan';
    var response = await Network().postData(data, 'favoritePlan');

    print(jsonDecode(response.body));
    var plans = convert.jsonDecode(response.body);
    setSearchPlanList(plans);
    notifyListeners();
    return plans;
  }
}