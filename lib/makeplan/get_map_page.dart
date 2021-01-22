import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GetMap extends StatefulWidget {
  @override
  _GetMapState createState() => _GetMapState();
}

class _GetMapState extends State<GetMap> {
  GoogleMapController mapController;
  List<double> _latLang = [0.0, 0.0];
  Set<Marker> _markers = Set();

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        Navigator.of(context).pop(_latLang);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('地図'),
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
        body: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                onTap: (latLang){
                  _latLang.clear();
                  _latLang.add(latLang.latitude);
                  _latLang.add(latLang.longitude);
                  _markers.clear();
                  Marker locationMarker = Marker(
                      markerId: MarkerId("aa"),
                      position: latLang,
                      icon: BitmapDescriptor.defaultMarker
                  );
                  _markers.add(locationMarker);
                  mapController.animateCamera(CameraUpdate.newLatLng(latLang));
                  setState(() {

                  });
                  print(latLang.longitude.toString() + "," +latLang.latitude.toString());
                },
                markers: _markers,
                mapType: MapType.terrain,
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(35.6580339,139.7016358),
                  zoom: 15.0,
                ),
                scrollGesturesEnabled: true,
              )
            ),
            Positioned(
              top: 20.0,
              left: 0.0,
              height: 50.0,
              width: MediaQuery.of(context).size.width,
              child: Container(
                margin: EdgeInsets.only(left:10.0, right: 10.0,),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("タップで座標を取得します", style: TextStyle(color: Colors.white),),
                    Text("x : " + _latLang[0].toString() + " y : " +  _latLang[1].toString(), style: TextStyle(color: Colors.white),)
                  ],
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}

