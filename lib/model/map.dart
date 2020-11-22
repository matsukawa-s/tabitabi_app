import 'package:flutter/cupertino.dart';
import 'package:google_maps_webservice/places.dart';

class MapViewModel extends ChangeNotifier{
  String _searchText; //検索テキスト

  void searchPlaces(){
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
  final openingHours; //営業時間(null:apiのレスポンスに存在しない)
  final nowOpen; //営業中フラグ(null:apiのレスポンスに存在しない)

  Place({
    this.placeId,
    this.photos,
    this.name,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.rating,
    this.reviews,
    this.openingHours,
    this.nowOpen
  });
}