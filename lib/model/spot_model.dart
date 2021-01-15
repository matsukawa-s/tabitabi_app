import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_select/smart_select.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:http/http.dart' as http;


// スポットのお気に入りページのProvider
class FavoriteSpotViewModel extends ChangeNotifier{
  List<Spot> spots; //お気に入りしているスポット
  List<Spot> showSpots; //表示するスポット
  List<S2Choice<int>> prefectures; //都道府県の選択Widgetリスト
  List<S2Choice<int>> types; //場所タイプの選択Widgetリスト
  List<Spot> selectedSpots = []; //選択モード時の選択しているスポット

  //プラン作成のスポット選択
  List<Spot> getSelectedSpots(List<int> selectedSpotItems){
    selectedSpots = spots.where((spot) => selectedSpotItems.indexOf(spot.spotId) != -1).toList();
    return selectedSpots;
  }

  //お気に入り解除
  unlikeSpot(spot) async{
    final data = {"spot_id" : spot.spotId};
    http.Response res = await Network().postData(data, 'postFavoriteSpot');
    this.getFavoriteSpots();
  }

  //都道府県とタイプ絞り込み
  narrowDownByPrefectureAndTypes(List<int> prefectures,List<int> types){
    List<Spot> tmp = [];//typesの絞り込みに使う仮変数

    //リセット
    showSpots = spots;

    if(prefectures.isNotEmpty){
      showSpots = showSpots.where((spot) => prefectures.indexOf(spot.prefectureId) != -1).toList();
    }

    if(types.isNotEmpty){
      List<Spot> ndList;
      types.forEach((type) {
        //都道府県で絞り込み済みのリストで更新
        ndList = showSpots;

        //typesにtype_idが存在するか検索
        ndList = ndList.where((spot) => spot.types.indexOf(type) != -1).toList();

        ndList.forEach((element) {
          //まだ追加されていなければ追加する
          if(tmp.indexOf(element) == -1){
            tmp.add(element);
          }
        });
      });

      //絞り込み結果を表示用変数に代入する
      showSpots = tmp;

      //並び順をスポットIDに戻す
      tmp.sort((a,b) => a.spotId - b.spotId);

    }

    notifyListeners();
  }

  getSpotTypes() async{
    http.Response res = await Network().getData("spot/get/types");
    List typesMap = json.decode(res.body);

    types = List.generate(
        typesMap.length,
        (index) => S2Choice<int>(
            value: typesMap[index]["id"],
            title: typesMap[index]["japanese_name"]
        )
    );
  }

  getFavoriteSpots() async{
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
  final spotId;
  final placeId;
  final spotName;
  final lat;
  final lng;
  final imageUrl;
  final int prefectureId;
  final types;
  final isLike;

  Spot({
    this.spotId,
    this.placeId,
    this.spotName,
    this.lat,
    this.lng,
    this.imageUrl,
    this.prefectureId,
    this.types,
    this.isLike
  });

  Spot.fromJson(Map<String,dynamic> json)
    : spotId = json["id"],
      placeId = json["place_id"],
      spotName = json["spot_name"],
      lat = json["memory_latitube"],
      lng = json["memory_longitube"],
      imageUrl = json["image_url"],
      prefectureId = json["prefecture_id"],
      types = json["types"],
      isLike = json["isLike"];
}

class Prefecture {
  Prefecture(this.code,this.name);
  final code;
  final name;

  Prefecture.fromJson(Map<String,dynamic> json)
      : code = json["code"],
        name = json["name"];
}

class Type {
  Type(this.id,this.englishName,this.japaneseName);
  final id;
  final englishName;
  final japaneseName;

  Type.fromJson(Map<String,dynamic> json)
      : id = json["id"],
        englishName = json["english_name"],
        japaneseName = json["japanese_name"];

}