import 'dart:ffi';

import 'package:flutter/cupertino.dart';

class MapViewModel extends ChangeNotifier{
  String _searchText; //検索テキスト

  String getSearchText () => _searchText;

  //検索時に検索バーの文字を更新する
  void searchPlacesTextUpdate(String searchText){
    print("searchPlacesTextUpdate : ${searchText}");
    _searchText = searchText;
    notifyListeners();
  }
}

// Google Map & Places Api Util Class
//class Map {
//  final photoUrl = "https://maps.googleapis.com/maps/api/place/photo";
//}

class Place {
  var spotId; //nullならスポットテーブルに未登録
  final String placeId;
  final List photos;
  final String name;
  final lat; //緯度
  final lng; //経度
  final String formattedAddress;
  final String formattedPhoneNumber;
  final double rating;
  final List reviews;
  final weekdayText; //営業時間(null:apiのレスポンスに存在しない)
  final nowOpen; //営業中フラグ(null:apiのレスポンスに存在しない)
  var isFavorite; //お気に入り登録フラグ
  final prefectureId; //都道府県コード
  final List types; //場所タイプ

  Place({
    this.spotId,
    this.placeId,
    this.photos,
    this.name,
    this.lat,
    this.lng,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.rating,
    this.reviews,
    this.weekdayText,
    this.nowOpen,
    this.isFavorite,
    this.prefectureId,
    this.types
  });

  Map<String,dynamic> toJson() =>
      {
        'spot_id' : spotId,
        'place_id' : placeId,
        'name' : name,
        'photo' : photos != [] ? photos[0] : '',
        'lat' : lat,
        'lng' : lng,
        'isFavorite' : isFavorite,
        'prefecture_id' : prefectureId,
        'types' : types
      };

}