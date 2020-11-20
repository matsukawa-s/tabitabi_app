import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:like_button/like_button.dart';
import 'package:location/location.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tabitabi_app/map_search_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

final _kGoogleApiKey = "AIzaSyC2VCSOjFsBo9sPArzQde0aN_R5ZU8Rt0w";

class MapPage extends StatefulWidget {
  final String title;
  MapPage({@required this.title});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  Set<Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _kGooglePlex;
  bool isView = false;
  Map placeDetails = {
    'name' : '',
    'address' : '',
    'phone_number' : '',
    'reviews' : '',
    'photos' : [],
    'openingHours' : [],
    'nowOpen' : null
  };

  var lat; // 緯度
  var lng; // 経度

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    lat = 34.706452;
    lng = 135.503327;
    _kGooglePlex = CameraPosition(
      target: LatLng(lat,lng),
      zoom: 14.4746,
    );
}

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.title;

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
//        if(isView) _buildPlaceInfo(placeDetails),
        _buildPlaceDetailsSlidingSheet(placeDetails)
      ],
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

    setState(() {
      isView = true;
    });
  }

  //検索結果から選択した一つの地点へ移動する
  Future<void> movePoint(placeId) async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
    var placesDetailsResponse =
        await _places.getDetailsByPlaceId(
          placeId,
          language: "ja",
//          取得するデータを絞りたいけど上手く取れない
//          fields: ["name","formattedAddress","formattedPhoneNumber","photoReference","location","photos"],
        );
    print(placesDetailsResponse.result.name);
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
//    photos.forEach((element) { });

    if(placesDetailsResponse.result.openingHours != null){
      setState(() {
        placeDetails["openingHours"] = placesDetailsResponse.result.openingHours.periods;
      });
      print("test : ${placeDetails["openingHours"][0].open.time}");
      placesDetailsResponse.result.openingHours.periods.forEach(
              (e) => print(e.open.day.toString() + e.open.time.toString()??'')
      );
    }

    setState(() {
      placeDetails["name"] = placesDetailsResponse.result.name;
      placeDetails["address"] = placesDetailsResponse.result.formattedAddress;
      placeDetails["phone_number"] = placesDetailsResponse.result.formattedPhoneNumber;
      placeDetails["nowOpen"] = placesDetailsResponse.result.openingHours.openNow;
      placeDetails["photos"] = photoRequests;
    });
    print(placeDetails);

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
    _goToTheLake(_newPoint);

    setState(() {
      isView = true;
    });
  }

//  マップを移動させる
  Future<void> _goToTheLake(_newPoint) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_newPoint));
  }

  bool isExpandedOpeningHoursTiles = false;

  Widget _buildPlaceDetailsSlidingSheet(placeDetails){
    final dayOfWeek = ["日","月","火","水","木","金","土"];
    //区切り線の設定
    final borderDesign = BoxDecoration(
        border: Border(
//            top: BorderSide(color: Colors.black12),
            bottom: BorderSide(color: Colors.black12)
        )
    );

    final ratingIcon = Icon(Icons.star_border,size: 2,);

    return SlidingSheet(
      elevation: 8,
      cornerRadius: 16,
      snapSpec: const SnapSpec(
        snap: true,
        snappings: [140, 600, double.infinity],
        positioning: SnapPositioning.pixelOffset,
      ),
      builder: (context, state) {
        return Container(
          height: 600,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                    decoration: borderDesign,
                    child: ListTile(leading: Icon(Icons.add_location),title: Text(placeDetails["address"])??'',)
                ),
                Container(
                    decoration: borderDesign,
                    child: ListTile(leading: Icon(Icons.phone),title: Text(placeDetails["phone_number"])??'',)
                ),
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
                          Icon(Icons.keyboard_arrow_down)
                        ],
                      ),
                      trailing: Container(
                        child: placeDetails["nowOpen"] != null && placeDetails["nowOpen"] ? Text("営業中") : Text("営業時間外")
                      ),
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if(placeDetails["openingHours"].isNotEmpty)
//                          if(false)
                              for(int i = 0; i < 7; i++)
                                Container(
                                  padding: EdgeInsets.only(left: 74,right: 74),//直接指定してるので端末によって変わる？？
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(dayOfWeek[i] + "曜日"),
                                      Text(
                                          "${placeDetails["openingHours"][i].open.time} ~ "
                                              "${placeDetails["openingHours"][i].close.time}"
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
                        Container(
                          width: 160,
                          color: Colors.yellow,
                          margin: EdgeInsets.only(right: 10),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        );
      },
      headerBuilder: (context, state) {
          return Container(
            height: 140,
            decoration: borderDesign,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  child: placeDetails['photos'].length == 0 ? Container() :ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: placeDetails['photos'].length,
                      itemBuilder: (BuildContext context, int index){
                        return Container(
                          margin: EdgeInsets.only(right: 4.0),
                          child: Image.network(placeDetails['photos'][index]),
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
                                placeDetails["name"]??'',
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
      },
    );
  }


  //　＊＊＊＊＊＊＊＊＊＊　以下不要物　＊＊＊＊＊＊＊＊＊＊＊＊＊
  Widget _buildPlaceInfo(placeDetails){
    return Positioned(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 3,
        bottom: 0,
        child: Container(
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 1.0,
                  blurRadius: 10.0,
              )
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 4.0),
                        child: Image.network(placeDetails["photo"]),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 4.0),
                        child: Image.network(placeDetails["photo"]),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 4.0),
                        child: Image.network(placeDetails["photo"]),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(placeDetails["name"]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}