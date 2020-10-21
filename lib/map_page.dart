import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  final String title;
  MapPage({@required this.title});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  var _keyWordController = TextEditingController();
  LocationData currentLocation;
  Location _locationService = new Location();
  String error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    _locationService.onLocationChanged.listen((LocationData result) async {
      if(this.mounted) {
        setState(() {
          currentLocation = result;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _keyWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.title;
    Completer<GoogleMapController> _controller = Completer();
    final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(34.706452, 135.503327),
      zoom: 14.4746,
    );

    return Stack(
      children: [
        Positioned(
          child: GoogleMap(
            mapType: MapType.terrain,
            initialCameraPosition: _kGooglePlex,
//        initialCameraPosition: CameraPosition(
//          target: LatLng(currentLocation.latitude,currentLocation.longitude),
//          zoom: 1.7
//        ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
        Positioned(
//          child: Form(
//            child: TextFormField(
//              controller: _keyWordController,
//              onFieldSubmitted: searchPlaces(),
//            ),
//          ),
            child: Container(
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(90)
              ),
              child: TextField(
                onSubmitted: (String str){
                  searchPlaces();
                },
                controller: _keyWordController,
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
    );
  }

  void initPlatformState() async{
    LocationData myLocation;
    try {
      myLocation = await _locationService.getLocation();
      error = "";
    }on PlatformException catch(e){
      if(e.code == 'PERMISSION_DENITED')
        error = 'Permission denited';
      else if(e.code == 'PERMISSION_DENITED_NEVER_ASK')
        error = 'Permission denited - please ask the user to enable it from the app settings';
      myLocation = null;
    }
    if(this.mounted){
      setState(() {
        currentLocation = myLocation;
      });
    }
  }

// Google Places APIを叩いて場所を検索する
  searchPlaces() {
    print("searchPlaces");
    if(_keyWordController.text.isEmpty){
      print("キーワードが空なので何もしない");
    }else{
      print("検索処理をする");
      if(this.mounted){
        setState(() {
          _keyWordController.clear();
        });
      }
    }
  }
}