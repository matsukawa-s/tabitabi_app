import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:like_button/like_button.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:google_maps_webservice/places.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tabitabi_app/map_search_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tabitabi_app/model/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tabitabi_app/model/spot_model.dart';

import 'network_utils/api.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class MapPage extends StatefulWidget {
  final String title;
  MapPage({@required this.title});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  loc.Location location = loc.Location(); // 位置情報
  bool _serviceEnabled;
  loc.PermissionStatus _permissionGranted;
  loc.LocationData _locationData;
  Set<Marker> _markers = {}; //地図上のマーク
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _kGooglePlex; //マップの初期カメラ位置
  bool bottomSheetSwitchFlag = false; // true : 検索時,false : 最初の表示（現在値情報）
  Place place; //プレイス情報クラス変数
  List<PlacesSearchResult> places = []; //現在地周辺スポット
  TextEditingController _searchKeywordController; //検索キーワード用コントローラー

  var lat; // 緯度
  var lng; // 経度

  ///位置情報権限の許可を求める
  ///現在地周辺のスポット取得する
  Future initGetCurrentLocation() async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);

    final MapViewModel mapModel = Provider.of<MapViewModel>(context);
    _searchKeywordController = TextEditingController(text: mapModel.getSearchText());

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

    //周辺半径５００メートル以内のスポットを取得する
    PlacesSearchResponse response
      = await _places.searchNearbyWithRadius(Location(lat,lng), 500,language: "ja",type: "tourist_attraction");

    places = response.results;

    _kGooglePlex = CameraPosition(
      target: LatLng(lat,lng),
      zoom: 14.4746,
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.title;

    return FutureBuilder(
      future: initGetCurrentLocation(),
      builder: (BuildContext context,AsyncSnapshot snapshot) {
        if(snapshot.hasData){
          return Stack(
            children: [
              Positioned(
                child: GoogleMap(
                  mapType: MapType.terrain,
                  initialCameraPosition: _kGooglePlex,
                  markers: _markers,
                  zoomControlsEnabled: false, //拡大縮小ボタンを非表示
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    setState(() {
                      _markers.add(
                          Marker(
                              markerId: MarkerId("now point"),
                              position: LatLng(lat, lng)
                          )
                      );
                    });
                  },
                ),
              ),
              Positioned(
                //検索フォーム
                  child: Container(
                    margin: EdgeInsets.only(top: 16,left: 8,right: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(90)
                    ),
                    child: TextField(
                      autofocus: false,
                      readOnly: true,
                      controller: _searchKeywordController,
                      onTap: () => onFocusedTextForm(),
                      style: TextStyle(
                          fontSize: 18
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: '検索',
                        border: InputBorder.none,
                      ),
                    ),
                  )
              ),
              _buildPlaceDetailsSlidingSheet(place)
            ],
          );
        }else{
          return Center(
              child: CircularProgressIndicator()
          );
        }
      }
    );
  }

  void onFocusedTextForm() async{
    // resultには前画面からplaceIdが戻ってくる
    final result = await Navigator.push(
      context,
      PageTransition(
          type: PageTransitionType.fade,
          child: MapSearchPage(),
          inheritTheme: true,
          ctx: context
      ),
    );

    if(result != null){
      movePoint(result);
    }
  }

  //検索結果から選択した一つの地点へ移動する
  Future<void> movePoint(placeId) async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
    PlacesDetailsResponse placesDetailsResponse =
        await _places.getDetailsByPlaceId(
          placeId,
          language: "ja",
//          取得するデータを絞りたいけど上手く取れない
//          fields: ["name","formattedAddress","formattedPhoneNumber","photoReference","location","photos"],
        );

    String jsonString = await rootBundle.loadString('json/prefectures.json');
    Map<String,dynamic> prefectures = json.decode(jsonString);

    var data = placesDetailsResponse.result;

    var location = placesDetailsResponse.result.geometry.location;
    //座標を変更する
    setState(() {
      lat = placesDetailsResponse.result.geometry.location.lat;
      lng = placesDetailsResponse.result.geometry.location.lng;
    });

    List photoRequests = [];

    if(placesDetailsResponse.result.photos != null){
      List<Photo> photos = placesDetailsResponse.result.photos;
      //プレイスの画像を3枚取得
      for(int i = 0;i < 3;i++){
        photoRequests.add(photos[i].photoReference);
      }
    }

    print(placesDetailsResponse.result.types);

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
    final index = prefectures["prefectures"].indexWhere((item) => item["name"] == prefectureName);
    final prefectureId = index + 1;

    place = Place(
//      spotId: null,
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
//      isFavorite: null
    );

    //スポットがお気に入り登録されているかどうか取得する
    http.Response res = await Network().getData("getOneFavorite/${placesDetailsResponse.result.placeId}");

    var body = jsonDecode(res.body);

    place.isFavorite = body["isFavorite"];
    place.spotId = body["spot_id"];
    print("spotId : ${place.spotId}");

    //検索履歴を保存する
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var history = {};
    if (prefs.containsKey('history')) {
      history = jsonDecode(prefs.getString('history'));
    }
    history[place.placeId] = place.name;
    prefs.setString('history', jsonEncode(history));

    final MapViewModel mapModel = Provider.of<MapViewModel>(context,listen: false);
    mapModel.searchPlacesTextUpdate(place.name);
    print(mapModel.getSearchText());

    final _newPoint = CameraPosition(target: LatLng(lat,lng),zoom: 14.4746,);

    setState(() {
//      マーカーの位置を変更
      _markers.clear();
      _markers.add(
          Marker(
              markerId: MarkerId("now point"),
              position: LatLng(lat, lng)
          )
      );
    });

    FocusScope.of(context).unfocus(); //キーボード閉じる
    _moveCameraPosition(_newPoint);

    setState(() {
      //表示を切り替える
      bottomSheetSwitchFlag = true;
    });
  }

//  マップのカメラを移動させる
  Future<void> _moveCameraPosition(_newPoint) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_newPoint));
  }

  Widget _buildPlaceDetailsSlidingSheet(Place place){
    final dayOfWeek = ["日","月","火","水","木","金","土"];
    //区切り線の設定
    final borderDesign = BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.black12)
        )
    );

    return SlidingSheet(
      elevation: 8,
      cornerRadius: 16,
      snapSpec: const SnapSpec(
        snap: true,
        snappings: [140, 800, double.infinity],
        positioning: SnapPositioning.pixelOffset,
      ),
      headerBuilder: (context, state) {
        //初回起動時（未検索時、プレイス情報なし）
        if(bottomSheetSwitchFlag){
          return Container(
            height: 140,
            decoration: borderDesign,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  child: place.photos.length == 0
                      ? Container(
                        constraints: BoxConstraints.expand(),
                        color: Colors.black26,
                        child: Center(child: Text("画像がありません")),
                      )
                      : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: place.photos.length,
                      itemBuilder: (BuildContext context, int index){
                        return Container(
                          width: MediaQuery.of(context).size.width / 3,
//                          margin: EdgeInsets.only(right: 4.0),
                          child: Image.network(
                              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                              '&photoreference=${place.photos[index]}'
                              '&key=${_kGoogleApiKey}',
                            fit: BoxFit.fill,
                          ),
                        );
                      }
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
//                          height: 40,
                              child: Text(
                                place.name ?? '',
                                style: TextStyle(fontSize: 20),
                              )
                          ),
                          if(place.rating != null)
                            Row(
                              children: [
                                RatingBar.builder(
                                  itemSize: 16,
                                  initialRating: place.rating,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                                ),
                                Text(place.rating.toString())
                              ],
                            ),
                        ],
                      ),
                      Container(
                          margin: EdgeInsets.only(top: 4.0,right: 4.0),
                          child: LikeButton(
                            size: 36,
                            onTap: onLikeButtonTapped,
                            isLiked: place.isFavorite,
                          )
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }else{
          return Container(
            height: 140,
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  margin: EdgeInsets.all(2.0),
                  child: Text("この地域のスポット")
                ),
                if(places.isNotEmpty)
                Container(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: [
                      ListView.builder(
                          scrollDirection: Axis.horizontal,
                          //とりあえず３つ表示にしている
                          itemCount: 4,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context,int index){
                            return InkWell(
                              onTap: (){
                                movePoint(places[index].placeId);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    height: 80,
                                    width: 130,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=300'
                                            '&photoreference=${places[index].photos[0].photoReference}'
                                            '&key=${_kGoogleApiKey}',
                                        fit:BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 18,
                                    alignment: Alignment.bottomCenter,
                                    child: FittedBox(
                                      child: Text(
                                          places[index].name ?? '',
//                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        if(bottomSheetSwitchFlag){
          return Container(
              height: 800,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if(place.formattedAddress != null)
                      Container(
                          decoration: borderDesign,
                          child: ListTile(
                            leading: Icon(Icons.add_location),
                            title: Text(place.formattedAddress ?? ''),
                          )
                      ),
                    if(place.formattedPhoneNumber != null)
                      Container(
                          decoration: borderDesign,
                          child: ListTile(
                            leading: Icon(Icons.phone),
                            title: Text(place.formattedPhoneNumber ?? ''),
                          )
                      ),
                    if(place.weekdayText != null)
                      Theme(
                        data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            accentColor: Colors.black54
                        ),
                        child: Container(
                          decoration: borderDesign,
                          child: ExpansionTile(
                            leading: Icon(Icons.access_time),
                            title: Row(
                              children: [
                                Text("営業時間"),
                                place.nowOpen != null && place.nowOpen ? Text("(営業中)") : Text("(営業時間外)")
  //                              Icon(Icons.keyboard_arrow_down)
                              ],
                            ),
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if(place.weekdayText != null)
                                    for(int i = 0; i < 7; i++)
                                      Container(
                                        padding: EdgeInsets.only(left: 74),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(place.weekdayText[i])
                                            ],
//                                          children: [
//                                            Text(dayOfWeek[i] + "曜日"),
//                                            Text(
//                                                "${place.openingHours[i].open.time.toString().substring(0,2)}:"
//                                                    "${place.openingHours[i].open.time.toString().substring(2,4)} ~ "
//                                                "${place.openingHours[i].close.time.toString().substring(0,2)}:"
//                                                    "${place.openingHours[i].close.time.toString().substring(2,4)}"
//                                            )
//                                          ],
                                        ),
                                      )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      title: Text("このスポットが入っているプラン"),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0,right: 16.0),
                      child: SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for(int i = 0;i < 4;i++)
                              Container(
                                width: 160,
                                color: Colors.yellow,
                                margin: EdgeInsets.only(right: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text("レビュー"),
                    ),
                    if(place.reviews != null)
                      Container(
                        padding: EdgeInsets.only(left: 16.0,right: 16.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          itemCount: place.reviews.length,
                          itemBuilder: (BuildContext context, int index){
                            return InkWell(
                              onTap: (){
                                showReviewDialog(place.reviews[index]);
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 4.0),
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          place.reviews[index].authorName,
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        RatingBar.builder(
                                          itemSize: 12,
                                          initialRating: place.reviews[index].rating.toDouble(),
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          itemBuilder: (context, _) => Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      place.reviews[index].text ?? "",
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    Container()
                  ],
                ),
              )
          );
        }else{
          return Container(
            height: 700,
            color: Colors.pink,
            child: Text("-----------何か表示する------------"),
          );
        }

      },

    );
  }

  void showReviewDialog(review) {
    var formatter = DateFormat('yyyy/MM/dd(E) HH:mm', "ja_JP");
    var formatted = formatter.format(DateTime.fromMillisecondsSinceEpoch(review.time * 1000)); // DateからString

    showDialog(
      context: context,
      builder: (context){
        return SimpleDialog(
          children: [
            Container(
              padding: EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.authorName,style: TextStyle(fontWeight: FontWeight.w600),),
                  Text(formatted,style: TextStyle(fontSize: 10),),
                  Text(review.text)
                ],
              ),
            )
          ],
        );
      }
    );
  }

  //スポットをお気に入り登録ボタンを押したとき
  Future<bool> onLikeButtonTapped(bool isLiked) async{
    var data = place.toJson();
    print(data);

    http.Response res = await Network().postData(data, 'postFavoriteSpot');

    var body = json.decode(res.body);
    print(res.statusCode);
    print(res.body);

    if(res.statusCode == 200){
      place.isFavorite = !place.isFavorite;
      place.spotId = body["spot_id"];
      Provider.of<FavoriteSpotViewModel>(context,listen: false).getFavoriteSpots();
    }

    return place.isFavorite;

  }
}