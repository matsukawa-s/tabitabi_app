import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_select/smart_select.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:http/http.dart' as http;


// スポットのお気に入りページのProvider
class FavoriteSpotViewModel extends ChangeNotifier{
//  FavoriteSpotViewModel(){
//    getFavoriteSpots();
//  }

  List<Spot> spots;
  List<Spot> showSpots;
  List<S2Choice<int>> prefectures;
  List<int> selects = [];

  //絞り込み
  refine(List<int> selects){
    print("refine");
    print(selects);
    if(selects.isEmpty){
      showSpots = spots;
    }else{
      showSpots = spots.where((spot) => selects.indexOf(spot.prefectureId) != -1).toList();
    }
    print(showSpots);
    notifyListeners();
  }

  getFavoriteSpots() async{
    print("getFavoriteSpots");
    //都道府県データをjsonから取得する
    String jsonString = await rootBundle.loadString('json/prefectures.json');
    List prefecturesMap = json.decode(jsonString)["prefectures"];

    prefectures = List.generate(
        prefecturesMap.length,
        (index) => S2Choice<int>(
            value: prefecturesMap[index]["code"],
            title: prefecturesMap[index]["name"]
        )
    );

    //お気に入りしているスポットを全件取得する
    http.Response res = await Network().getData('getAllFavorite');
    if(res.statusCode == 200){
      List tmp = jsonDecode(res.body);
      spots = List.generate(
          tmp.length, (index) => Spot.fromJson(tmp[index])
      );
    }else{
      print(res.statusCode);
    }

    showSpots = spots;
    notifyListeners();
  }


}

class Spot {
  final spotName;
  final imageUrl;
  final int prefectureId;

  Spot({
    this.spotName,
    this.imageUrl,
    this.prefectureId
  });

  Spot.fromJson(Map<String,dynamic> json)
    : spotName = json["spot_name"],
      imageUrl = json["image_url"],
      prefectureId = json["prefecture_id"];
}

class Prefecture {
  Prefecture(this.code,this.name);
  final code;
  final name;

  Prefecture.fromJson(Map<String,dynamic> json)
      : code = json["code"],
        name = json["name"];
}