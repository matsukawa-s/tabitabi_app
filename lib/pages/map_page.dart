import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/pages/map_search_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tabitabi_app/model/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/pages/spot_details_page.dart';

import '../model/plan.dart';
import '../network_utils/api.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class MapPage extends StatefulWidget {
  final String title;
  final bool addFlag;
  MapPage({@required this.title, this.addFlag});

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
  var planContainingSpots = []; //対象スポットが入っているプラン
  List<PlacesSearchResult> nearBySpots = []; //対象スポットの近くのスポット

  var lat; // 緯度
  var lng; // 経度

  bool addFlag = false;

  @override
  void initState() {
    super.initState();
    if(widget.addFlag != null){
      addFlag = widget.addFlag;
    }
  }

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
      = await _places.searchNearbyWithRadius(Location(lat,lng), 1000,language: "ja",type: "tourist_attraction");

    places = response.results;

    _kGooglePlex = CameraPosition(
      target: LatLng(lat,lng),
      zoom: 14.4746,
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {

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
                              position: LatLng(lat, lng),
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

    final MapViewModel mapModel = Provider.of<MapViewModel>(context,listen: false);
    mapModel.searchPlacesTextUpdate(place.name);
    print(mapModel.getSearchText());

    final _newPoint = CameraPosition(target: LatLng(lat,lng),zoom: 14.4746,);

    setState(() {
//      マーカーの位置を変更
      _markers.clear();
      _markers.add(
          Marker(
              markerId: MarkerId(place.name),
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
                          child: CachedNetworkImage(
                            imageUrl: GoogleMapApi().fullPhotoPath(place.photos[index]),
                            progressIndicatorBuilder: (context, url, downloadProgress) =>
                                Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                            errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                            fit: BoxFit.fill,
//                            width: double.infinity,
//                            height: double.infinity,
                          ),
//                          child: Image.network(
//                            GoogleMapApi().fullPhotoPath(place.photos[index]),
//                            fit: BoxFit.fill,
//                          ),
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
                            width: MediaQuery.of(context).size.width - 60,
                            child: Text(
                              place.name ?? '',
                              style: TextStyle(fontSize: 20,) ,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      if(!addFlag)
                        Container(
                          margin: EdgeInsets.only(top: 4.0,right: 4.0),
                          child: LikeButton(
                            size: 36,
                            onTap: onLikeButtonTapped,
                            isLiked: place.isFavorite,
                          )
                        ),
                      if(addFlag)
                        Padding(
                          padding: EdgeInsets.only(top: 4.0,right: 4.0),
                          child: GestureDetector(
                            child: Icon(
                              Icons.add_circle_sharp,
                              size: 45.0 ,
                              color: Theme.of(context).primaryColor,
                            ),
                            onTap: (){
                              _addSpot();
                            },
                          ),
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
                  child: Text("この地域のスポット",style: TextStyle(fontWeight: FontWeight.bold),)
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
                          itemCount: places.length > 4 ? 4 : places.length,
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
                                      child: places[index].photos == null ?
                                          Container(
                                            color: Colors.black12,
                                            child: Center(child: Text("no image")),
                                          )
                                          : CachedNetworkImage(
                                            imageUrl: GoogleMapApi().fullPhotoPath(places[index].photos[0].photoReference),
                                            progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                            errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                                            fit: BoxFit.fill,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    height: 18,
                                    alignment: Alignment.bottomCenter,
                                    child: FittedBox(
                                      child: Text(
                                          places[index].name ?? '',
                                          overflow: TextOverflow.ellipsis,
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
        final size = MediaQuery.of(context).size;
        final double planContainingSpotsWidth = (size.width) * 2/5 * 4/5;
        final double planContainingSpotsHeight = (size.width) * 2/5;

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
                                    for(int i = 0; i < place.weekdayText.length; i++)
                                      Container(
                                        padding: EdgeInsets.only(left: 74),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(place.weekdayText[i])
                                            ],
                                        ),
                                      )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    if(planContainingSpots.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 8.0,right: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                margin: EdgeInsets.all(4.0),
                                child: Text("このスポットが入っているプラン")
                            ),
                            SizedBox(
                              height: planContainingSpotsHeight,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: planContainingSpots.length,
                                itemBuilder: (BuildContext context,int index){
                                  return Container(
                                    margin: EdgeInsets.only(right: 4.0),
                                    child: PlanItem(
                                      plan: planContainingSpots[index],
                                      width: planContainingSpotsWidth,
                                      height: planContainingSpotsHeight,
                                    ),
                                  );
//                                  return GestureDetector(
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    if(nearBySpots.isNotEmpty)
                      Padding(
                          padding: EdgeInsets.only(left: 8.0,right: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  margin: EdgeInsets.all(4.0),
                                  child: Text("周辺のスポット")
                              ),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: nearBySpots.length > 5 ? 5 : nearBySpots.length,
                                    itemBuilder: (BuildContext context,int index){
                                      return GestureDetector(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SpotDetailsPage(
                                                placeId: nearBySpots[index].placeId
                                              ),
                                            )
                                        ),
                                          child: Container(
                                            width: 100,
                                            margin: EdgeInsets.only(right: 4.0),
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  flex: 4,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(6.0),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: Image.network(
                                                      GoogleMapApi().fullPhotoPath(nearBySpots[index].photos[0].photoReference ?? ''),
                                                      fit: BoxFit.fill,
                                                      width: 100,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    nearBySpots[index].name,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                )
                                              ],
                                            ),
                                          )
                                      );
                                    }
                                ),
                              )
                            ],
                          ),
                      ),
                    if(place.reviews != null)
                      Padding(
                        padding: EdgeInsets.only(left: 8.0,right: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                margin: EdgeInsets.all(4.0),
                                child: Text("レビュー")
                            ),
                            Container(
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
                                            maxLines: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container()
                  ],
                ),
              )
          );
        }else{
          return Container(
            height: 1,
//            color: Colors.pink,
//            child: Text("-----------何か表示する------------"),
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

    http.Response res = await Network().postData(data, 'postFavoriteSpot');

    var body = json.decode(res.body);

    if(res.statusCode == 200){
      place.isFavorite = !place.isFavorite;
      place.spotId = body["spot_id"];
      Provider.of<FavoriteSpotViewModel>(context,listen: false).getFavoriteSpots();
    }

    return place.isFavorite;

  }

  Future<void> _addSpot() async{
    var data = place.toJson();
    print(data);
    http.Response res = await Network().postData(data, 'spot/store/if');
    print("tst" + res.body.toString());

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

    Navigator.of(context).pop(returnValue);

  }
}