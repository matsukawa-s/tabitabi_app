import 'package:flutter/cupertino.dart';
import 'package:google_maps_webservice/places.dart';

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
class Map {
  final photoUrl = "https://maps.googleapis.com/maps/api/place/photo";
}

class Place {
  final String placeId;
  final List photos;
  final String name;
  final String formattedAddress;
  final String formattedPhoneNumber;
  final double rating;
  final List reviews;
  final weekdayText; //営業時間(null:apiのレスポンスに存在しない)
  final nowOpen; //営業中フラグ(null:apiのレスポンスに存在しない)

  Place({
    this.placeId,
    this.photos,
    this.name,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.rating,
    this.reviews,
    this.weekdayText,
    this.nowOpen
  });
}