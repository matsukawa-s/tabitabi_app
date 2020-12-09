import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tabitabi_app/model/plan.dart';
import 'package:tabitabi_app/network_utils/api.dart';


class PlanSearchModel with ChangeNotifier {
  // プランリスト
  List _plans;
  get plans => _plans;
  void setPlans(planList) {
    _plans = planList;
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
  var _sortIndex = 0;
  get sortIndex => _sortIndex;
  void setSort(sort) {
    if(_sortIndex == sort){
      _sortIndex = 0;
    }else{
      _sortIndex = sort;
    }
    fetchPostPlansList();
    notifyListeners();
  }

  // plan search post送信
  Future fetchPostPlansList() async {
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
      url = 'search/' + _keyword;
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

    print(plans);
//    Map planMap = convert.jsonDecode(plansRes.body);
//    var plan = new Plan.fromJson(planMap);
    setPlans(plans);
    notifyListeners();
  }
}


//print(convert.jsonDecode(plansResponse.body));
//Map planMap = convert.jsonDecode(plansResponse.body);
//var plan = new Plan.fromJson(planMap);
//setSearchPlanList(plans);