import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:location/location.dart' as loc;

import 'model/map.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class MapPageSecond extends StatefulWidget {
  @override
  _MapPageSecondState createState() => _MapPageSecondState();
}

class _MapPageSecondState extends State<MapPageSecond> {
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
  var planContainingSpots = []; //対象スポットが入っているプラン

  var lat; // 緯度
  var lng; // 経度

  @override
  void initState() {
    super.initState();
    initGetCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        maxHeight: MediaQuery.of(context).size.height * 6/7,
        minHeight: MediaQuery.of(context).size.height * 2/7,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
//        panel:  Navigator(
//          onGenerateRoute: (RouteSettings settings) {
//            return MaterialPageRoute(
//              builder: (_) => SpotDetailsPage(placeId: 'ChIJAQDAo5PmAGARcMqvnh2Reqs',),
//            );
//          },
//        ),
        panel: Center(
          child: Text("This is the sliding Widget"),
        ),
        body: Stack(
          children: [
            GoogleMap(
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
                          position: LatLng(34.7064368,135.5010341)
                      )
                  );
                });
              },
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
//                    onTap: () => onFocusedTextForm(),
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
          ],
        ),
      ),
    );
  }

  void initGetCurrentLocation() async{
    _kGooglePlex = CameraPosition(
      target: LatLng(34.7064368,135.5010341),
      zoom: 14.4746,
    );
  }
}
