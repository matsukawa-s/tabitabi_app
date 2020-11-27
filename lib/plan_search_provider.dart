import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';

class PlanSearchProvider with ChangeNotifier {

  SearchProvider(){
    fetchPlansList();
//    fetchPostPlansList();
  }

  List _searchplanlist;
  get searchplanlist => _searchplanlist;
  String _keyword;
  get keyword => _keyword;

  void setSearchPlanList(planList) {
    _searchplanlist = planList;
  }

  Future fetchPlansList() async {
    var url = 'http://10.0.2.2:8000/api/index';
    http.Response response = await http.get(url);

    print(convert.jsonDecode(response.body));
    var plans = convert.jsonDecode(response.body);
    setSearchPlanList(plans);
    notifyListeners();
//    return plans;
  }

  Future fetchPostPlansList(keyword) async {
    print(keyword);
    if(keyword == ''){
      fetchPlansList();
    }else{
      var url = 'http://10.0.2.2:8000/api/search/' + keyword;
      http.Response response = await http.get(url);
      _keyword = keyword;

      print(convert.jsonDecode(response.body));
      var plans = convert.jsonDecode(response.body);
      setSearchPlanList(plans);
      notifyListeners();
    }
  }

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