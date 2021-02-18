//import 'dart:async';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/model/map.dart';
import 'package:tabitabi_app/model/plan.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class MapProvider extends ChangeNotifier {
  bool _serviceEnabled;
  loc.PermissionStatus _permissionGranted;
  loc.LocationData _locationData;
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
  List<PlacesSearchResult> places = []; //現在地周辺スポット
  loc.Location location = loc.Location(); // 位置情報
  Completer<GoogleMapController> mapController = Completer();
  Set<Marker> markers = {}; //地図上のマーク
  Place place; //プレイス情報クラス変数
  var planContainingSpots = []; //対象スポットが入っているプラン
  List<PlacesSearchResult> nearBySpots = []; //対象スポットの近くのスポット
  TextEditingController searchKeywordController; //検索キーワード用コントローラー

  bool addFlag; //trueなら地図からスポットを追加するページ
  bool initPushFlag = false; // SlidingUpPanel内のページをビルド時にスポットの詳細ページにpushするかのどうかのフラグ

  var lat; // 緯度
  var lng; // 経度
  CameraPosition kGooglePlex; //マップのカメラ位置

  String _searchText; //検索テキスト

  String getSearchText () => _searchText;

  MapProvider(){
//     () async => await initGetCurrentLocation();
  }

  Future initGetCurrentLocation() async {
    print("map pro init");
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);

    searchKeywordController = TextEditingController(text: getSearchText());

    await initializeDateFormatting("jp_JP");

    //パーミッション確認
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    //現在地情報の取得
    _locationData = await location.getLocation();
    lat = _locationData.latitude;
    lng = _locationData.longitude;

    setMapCamera();

//    setMarker();

    markers.clear();
    markers.add(
        Marker(
            markerId: MarkerId("NOW LOCATION"),
            position: LatLng(lat, lng)
        )
    );
    //周辺半径1000メートル以内のスポットを取得する
    PlacesSearchResponse response = await _places.searchNearbyWithRadius(
        Location(lat, lng), 1000,
        language: "ja", type: "tourist_attraction"
    );

    places = response.results;
    print("map pro init end");
//    notifyListeners();
    return true;
  }

  //検索時に検索バーの文字を更新する
  void searchPlacesTextUpdate(String searchText){
    print("searchPlacesTextUpdate : ${searchText}");
    _searchText = searchText;
//    notifyListeners();
  }

  void setMapCamera(){
    kGooglePlex = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 14.4746,
    );
//    notifyListeners();
  }

  void setMarker(){
    print("setMarker");
    print("lat:${lat},lng:${lng}");
    markers.clear();
    markers.add(
        Marker(
            markerId: MarkerId(place.name ?? "NOW LOCATION"),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: place.name ?? "NOW LOCATION")
        )
    );
    print(markers);
//    notifyListeners();
  }

  //スポットをお気に入り登録ボタンを押したとき
  Future<bool> onLikeButtonTapped(bool isLiked) async{
    var data = place.toJson();
    http.Response res = await Network().postData(data, 'postFavoriteSpot');
    var body = json.decode(res.body);

    if(res.statusCode == 200){
      place.isFavorite = !place.isFavorite;
      place.spotId = body["spot_id"];
    }

    return place.isFavorite;
  }

  Future addSpot() async{
    var data = place.toJson();
    http.Response res = await Network().postData(data, 'spot/store/if');

    List<Spot> returnValue = [];
    returnValue.add(
        Spot(
          spotId: int.parse(res.body),
          placeId: data["place_id"],
          spotName: data["name"],
          lat: data["lat"],
          lng: data["lng"],
          imageUrl: data["photo"],
          types: data["types"],
          prefectureId: 1,
          isLike: 0,
        )
    );
    return returnValue;
  }

  //検索結果から選択した一つの地点へ移動する
  Future<void> movePoint(placeId) async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
    PlacesDetailsResponse placesDetailsResponse =
      await _places.getDetailsByPlaceId( placeId, language: "ja", );

    //近くのスポットを取得する
    PlacesSearchResponse nearBySpotsResponse
      = await _places.searchNearbyWithRadius(
        Location(
          placesDetailsResponse.result.geometry.location.lat,
          placesDetailsResponse.result.geometry.location.lng,
        ),
        1000, //半径(m)
        language: "ja",
        type: "tourist_attraction",
      );

    if(nearBySpotsResponse.status == 'OK'){
      nearBySpots = nearBySpotsResponse.results;
    }

    String jsonString = await rootBundle.loadString('json/prefectures.json');
    Map<String,dynamic> prefectures = json.decode(jsonString);

    //座標を変更する
      lat = placesDetailsResponse.result.geometry.location.lat;
      lng = placesDetailsResponse.result.geometry.location.lng;

    List photoRequests = [];

    if(placesDetailsResponse.result.photos != null){
      List<Photo> photos = placesDetailsResponse.result.photos;
      //プレイスの画像を3枚取得
      for(int i = 0;i < 3;i++){
        photoRequests.add(photos[i].photoReference);
      }
    }

    var prefectureName; //都道府県名
    // スポットの都道府県を取得
    placesDetailsResponse.result.addressComponents.forEach((element) {
      element.types.forEach((type) {
        if(type == 'administrative_area_level_1'){
          //都道府県名を保存
          prefectureName = element.longName;
        }
      });
    });

    //都道府県名に一致する都道府県コードを検索・取得
    final index = prefectures["prefectures"].indexWhere((item) => item["prefectures_name"] == prefectureName);
    final prefectureId = index + 1;

    place = Place(
        placeId: placesDetailsResponse.result.placeId,
        photos: photoRequests.isNotEmpty ? photoRequests : [],
        name: placesDetailsResponse.result.name,
        lat: lat,
        lng: lng,
        formattedAddress: placesDetailsResponse.result.formattedAddress,
        formattedPhoneNumber: placesDetailsResponse.result.formattedPhoneNumber != null
            ? placesDetailsResponse.result.formattedPhoneNumber : null,
        rating: placesDetailsResponse.result.rating != null
            ? placesDetailsResponse.result.rating.toDouble() : null,
        reviews: placesDetailsResponse.result.reviews,
        nowOpen: placesDetailsResponse.result.openingHours != null
            ? placesDetailsResponse.result.openingHours.openNow : null,
        weekdayText: placesDetailsResponse.result.openingHours != null
            ? placesDetailsResponse.result.openingHours.weekdayText : null,
        prefectureId: prefectureId,
        types: placesDetailsResponse.result.types
    );

    //スポットがお気に入り登録されているかどうか取得する
    http.Response res = await Network().getData("getOneFavorite/${placesDetailsResponse.result.placeId}");

    var body = jsonDecode(res.body);

    place.isFavorite = body["isFavorite"];
    place.spotId = body["spot_id"];

    final List planContainingSpotsTmp = body["plan_containing_spots"];
    planContainingSpots = List.generate(
        planContainingSpotsTmp.length, (index) => Plan.fromJson(planContainingSpotsTmp[index])
    );

    //過去に見たスポット保存する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var history = {};
    if (prefs.containsKey('history')) {
      history = jsonDecode(prefs.getString('history'));
    }

    if(history.containsKey(place.placeId)){
      history.remove(place.placeId);
    }

    history[place.placeId] = place.name;
    prefs.setString('history', jsonEncode(history));

    searchPlacesTextUpdate(place.name);

    final _newPoint = CameraPosition(target: LatLng(lat,lng),zoom: 14.4746,);


//      マーカーの位置を変更
  setMarker();
    notifyListeners();
  }

  //  マップのカメラを移動させる
  Future<void> moveCameraPosition(_controller) async {
    setMapCamera();
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(kGooglePlex));
  }

}
