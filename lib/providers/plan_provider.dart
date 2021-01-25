import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:tabitabi_app/model/plan.dart';
import 'package:tabitabi_app/network_utils/api.dart';

class PlanProvider extends ChangeNotifier{
  List<Plan> _plans = [];

  get plans => _plans;

  //お気に入り登録しているプランを取得
  getFavoritePlans() async{
    http.Response res = await Network().getData('plan/favorite/get');
    if(res.statusCode == 200){
      print("statusCode : ${res.statusCode}");
      print(res.body);
      List tmp = jsonDecode(res.body);
      if(tmp.isNotEmpty){
        _plans = List.generate(
            tmp.length, (index) => Plan.fromJson(tmp[index])
        );
      }
    }else{
      print("statusCode : ${res.statusCode}");
    }
  }

  //プランのお気に入り解除
  deleteFavoritePlan(Plan plan) async{
    final data = {
      'plan_id' : plan.id
    };
    http.Response res = await Network().postData(data, 'plan/favorite/delete');
    if(res.statusCode == 200){

    }
  }

  // プランのお気に入り登録
  storeFavoritePlan(Plan plan) async{
    final data = {
      'plan_id' : plan.id
    };
    http.Response res = await Network().postData(data, 'plan/favorite/store');
    if(res.statusCode == 200){

    }
  }
}