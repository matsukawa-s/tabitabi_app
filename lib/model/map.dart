import 'package:flutter/cupertino.dart';
import 'package:google_maps_webservice/places.dart';

class MapViewModel extends ChangeNotifier{
  String _searchText; //検索テキスト

  void searchPlaces(){
    notifyListeners();
  }
}

class Place {
  final String placeId;
  final List<Photo> photos;
  final String name;
  final String formattedAddress;
  final String formattedPhoneNumber;

  Place({
    this.placeId,
    this.photos,
    this.name,
    this.formattedAddress,
    this.formattedPhoneNumber
  });
}