import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:location/location.dart';
import 'package:google_maps_webservice/places.dart';

class MapPage extends StatefulWidget {
  final String title;
  MapPage({@required this.title});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  var _keyWordController = TextEditingController();

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
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
        Positioned(
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

// Google Places APIを叩いて場所を検索する
  Future<void> searchPlaces() async{
    const kGoogleApiKey = "AIzaSyC2VCSOjFsBo9sPArzQde0aN_R5ZU8Rt0w";
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

    print("searchPlaces");
    if(_keyWordController.text.isEmpty){
      print("キーワードが空なので何もしない");
    }else{
      print("検索処理をする");
      PlacesAutocompleteResponse res =
        await _places.autocomplete(_keyWordController.text.toString(),language: "ja");

      print(res);
      res.predictions.map(
              (Prediction prediction) => print(prediction.description)
      );
      print("検索関数の終わり");
    }
  }
}