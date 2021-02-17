/*
Name: Akshath Jain
Date: 3/18/2019 - 1/25/2020
Purpose: Example app that implements the package: sliding_up_panel
Copyright: © 2020, Akshath Jain. All rights reserved.
Licensing: More information can be found here: https://github.com/akshathjain/sliding_up_panel/blob/master/LICENSE
*/

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/pages/map_spot_details.dart';
import 'package:tabitabi_app/providers/map_provider.dart';
import 'map_search_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MapFixPage extends StatefulWidget {
  final bool addFlag;

  MapFixPage({this.addFlag});

  @override
  _MapFixPageState createState() => _MapFixPageState();
}

class _MapFixPageState extends State<MapFixPage> {
  double _panelHeightOpen;
  double _panelHeightClosed;

  Completer<GoogleMapController> _controller = Completer();
  @override
  void initState() {
    super.initState();
    Provider.of<MapProvider>(context,listen: false).addFlag = widget.addFlag ?? false;
  }

  @override
  Widget build(BuildContext context){
    final Size deviceSize = MediaQuery.of(context).size;
    _panelHeightClosed = deviceSize.height * .20;
    _panelHeightOpen = deviceSize.height * .70;

    return FutureBuilder(
        future: Provider.of<MapProvider>(context,listen: false).initGetCurrentLocation(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Material(
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                SlidingUpPanel(
                  maxHeight: _panelHeightOpen,
                  minHeight: _panelHeightClosed,
                  parallaxEnabled: true,
                  parallaxOffset: .5,
                  body: Selector<MapProvider, CameraPosition>(
                    selector: (context, model) => model.kGooglePlex,
                    builder: (context, model, child) => TestMap(),
                  ),
                  panelBuilder: (sc) => _panel(sc),
//                panelBuilder: (sc) => Selector<MapProvider, CameraPosition>(
//                  selector: (context, model) => model.kGooglePlex,
//                  builder: (context, model, child) => _panel(sc,true),
//                ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                ),
                Positioned(
                  //検索フォーム
                    child: Container(
                      margin: EdgeInsets.only(top: 8, left: 8, right: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(90)),
                      child: TextField(
                        autofocus: false,
                        readOnly: true,
                        controller: Provider.of<MapProvider>(context,listen: false).searchKeywordController,
                        onTap: () => onFocusedTextForm(),
                        style: TextStyle(fontSize: 16),
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
          );
        }
    );
  }

  Widget _panel(ScrollController sc){
    final model = Provider.of<MapProvider>(context,listen: false);

    return Padding(
      padding: const EdgeInsets.only(left: 4.0,right: 4.0),
      child: ListView(
        controller: sc,
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 12.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(Radius.circular(12.0))
                ),
              ),
            ],
          ),
          Container(
            height: MediaQuery.of(context).size.height * 1.3,
            child: Navigator(
              key: navigatorKey,
              onGenerateRoute: (context) => MaterialPageRoute(
                  builder: (context){
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                            alignment: Alignment.centerLeft,
                            height: 20,
                            margin: EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              "この地域のスポット",
                              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black87),
                            )
                        ),
                        if (model.places.isNotEmpty)
                          Container(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              children: [
                                ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: model.places.length > 4 ? 4 : model.places.length,
                                    shrinkWrap: true,
                                    itemBuilder:(BuildContext context, int index) {
                                      if(model.initPushFlag){
                                        Future.microtask(() => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => MapSpotDerailsPage())
                                        ));
                                        model.initPushFlag = false;
                                      }
                                      return InkWell(
                                        onTap: () async {
                                          await model.movePoint(model.places[index].placeId);
                                          FocusScope.of(context).unfocus(); //キーボード閉じる
                                          navigatorKey.currentState.push(
                                            MaterialPageRoute(
                                              builder: (context) => MapSpotDerailsPage(),
                                            ),
                                          );

//                                          Navigator.of(context).push(
//                                            MaterialPageRoute(
//                                              builder: (context) => MapSpotDerailsPage(),
//                                            ),
//                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(right: 4),
                                              height: 80,
                                              width: 130,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8.0),
                                                child: model.places[index].photos == null
                                                    ? Container(
                                                  color: Colors.black12,
                                                  child: Center(child: Text("NO IMAGE")),
                                                )
                                                    : CachedNetworkImage(
                                                  imageUrl: GoogleMapApi()
                                                      .fullPhotoPath(model.places[index].photos[0].photoReference),
                                                  progressIndicatorBuilder: (context,url,downloadProgress)
                                                  => Center(
                                                      child: CircularProgressIndicator(value: downloadProgress.progress)
                                                  ),
                                                  errorWidget: (context,url, error) => Center(child: Icon(Icons.error)),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 18,
                                              alignment: Alignment.bottomCenter,
                                              child: FittedBox(
                                                child: Text(
                                                  model.places[index].name ?? '',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    })
                              ],
                            ),
                          ),
                      ],
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(){
    final model = Provider.of<MapProvider>(context);
    print("_body rebuild");
    return GoogleMap(
      mapType: MapType.terrain,
      initialCameraPosition: model.kGooglePlex,
      markers: model.markers,
      zoomControlsEnabled: false, //拡大縮小ボタンを非表示
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
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
      await Provider.of<MapProvider>(context,listen: false).movePoint(result);
      navigatorKey.currentState.popUntil((route) => route.isFirst);
      navigatorKey.currentState.push(
        MaterialPageRoute(
          builder: (context) => MapSpotDerailsPage(),
        ),
      );
    }
  }
}

class TestMap extends StatefulWidget {
  @override
  _TestMapState createState() => _TestMapState();
}

class _TestMapState extends State<TestMap> {
  Completer<GoogleMapController> _controller = Completer();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<MapProvider>(context).moveCameraPosition(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MapProvider>(context);
    final markers = model.markers;

//  return FutureBuilder(
//    future: model.initGetCurrentLocation(),
//    builder: (context, snapshot) {
    return GoogleMap(
      mapType: MapType.terrain,
      initialCameraPosition: model.kGooglePlex,
      markers: markers,
      zoomControlsEnabled: false, //拡大縮小ボタンを非表示
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
//    }
//  );
  }
}
