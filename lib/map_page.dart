import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:like_button/like_button.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_webservice/places.dart';
import 'package:page_transition/page_transition.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tabitabi_app/map_search_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tabitabi_app/model/map.dart';

final _kGoogleApiKey = "AIzaSyC2VCSOjFsBo9sPArzQde0aN_R5ZU8Rt0w";

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

  var lat; // 緯度
  var lng; // 経度

  ///位置情報権限の許可を求める
  ///現在地周辺のスポット取得する
  Future initGetCurrentLocation() async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);

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

//    if (await Permission.location.request().isGranted){
      //現在地情報の取得
      _locationData = await location.getLocation();
      lat = _locationData.latitude;
      lng = _locationData.longitude;
//    }else{
      // 位置情報が許可されなかった場合
//      lat = 34.7024898;
//      lng = 135.4937619;
//    }

    //周辺半径５００メートル以内のスポットを取得する
    PlacesSearchResponse response
      = await _places.searchNearbyWithRadius(Location(lat,lng), 500,language: "ja",type: "tourist_attraction");

    places = response.results;

//    response.results.forEach((element) {
//      print(element.name);
//      print(element.openingHours);
//      places.add(
//          Place(
//            placeId: element.placeId,
//            photos: [],
//            name: element.name,
//            formattedAddress: element.formattedAddress,
//            formattedPhoneNumber: "",
//            rating: element.rating,
//            reviews: [],
//            nowOpen: element.openingHours.openNow ?? null,
//            openingHours: [],
//          )
//      );
//      print("foreach end");
//    });

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

    var data = placesDetailsResponse.result;

    var location = placesDetailsResponse.result.geometry.location;
    //座標を変更する
    setState(() {
      lat = placesDetailsResponse.result.geometry.location.lat;
      lng = placesDetailsResponse.result.geometry.location.lng;
    });

    List<Photo> photos = placesDetailsResponse.result.photos;
    List photoRequests = [];
    //プレイスの画像を5枚取得
    for(int i = 0;i < 5;i++){
      photoRequests.add(
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
              '&photoreference=${photos[i].photoReference}'
              '&key=${_kGoogleApiKey}'
      );
    }

    place = Place(
      placeId: placesDetailsResponse.result.placeId,
      photos: photoRequests,
      name: placesDetailsResponse.result.name,
      formattedAddress: placesDetailsResponse.result.formattedAddress,
      formattedPhoneNumber: placesDetailsResponse.result.formattedPhoneNumber != null
        ? placesDetailsResponse.result.formattedPhoneNumber : null,
      rating: placesDetailsResponse.result.rating != null
        ? placesDetailsResponse.result.rating : null,
      reviews: placesDetailsResponse.result.reviews,
      nowOpen: placesDetailsResponse.result.openingHours != null
        ? placesDetailsResponse.result.openingHours.openNow : null,
      openingHours: placesDetailsResponse.result.openingHours != null
        ? placesDetailsResponse.result.openingHours.periods : null,
    );

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
        snappings: [140, 700, double.infinity],
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
                  child: place.photos.length == 0 ? Container() :ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: place.photos.length,
                      itemBuilder: (BuildContext context, int index){
                        return Container(
                          margin: EdgeInsets.only(right: 4.0),
                          child: Image.network(place.photos[index]),
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
                          RatingBar.builder(
                            itemSize: 16,
                            initialRating: 3.5,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                            onRatingUpdate: (rating) {
                              print(rating);
                            },
                          ),
                        ],
                      ),
                      Container(
                          margin: EdgeInsets.only(top: 4.0,right: 4.0),
                          child: LikeButton(size: 36,)
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
              height: 700,
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
                    if(place.openingHours != null)
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
                                  if(place.openingHours != null)
                                    for(int i = 0; i < 7; i++)
                                      Container(
                                        padding: EdgeInsets.only(left: 74,right: 74),//直接指定してるので端末によって変わる？？
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dayOfWeek[i] + "曜日"),
                                            Text(
                                                "${place.openingHours[i].open.time} ~ "
                                                    "${place.openingHours[i].close.time}"
                                            )
                                          ],
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
                    Container(
                      padding: EdgeInsets.only(left: 16.0,right: 16.0),
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: [
                          ListTile(title: Text("********"),tileColor: Colors.green,),
                          ListTile(title: Text("********"),tileColor: Colors.green,)
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text("++++++++++++"),
                    )
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
}