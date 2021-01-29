import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bubble/bubble.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:tabitabi_app/components/map_marker.dart';
import 'package:tabitabi_app/data/itinerary_part_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_spot_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_plan_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_memo_part.dart';
import 'package:tabitabi_app/data/spot_data.dart';
import 'package:tabitabi_app/data/itinerary_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_traffic_part.dart';
import 'package:tabitabi_app/makeplan/makeplan_add_spot_page.dart';
import 'package:tabitabi_app/makeplan/direction_api.dart';

//ドラッグ&ドロップ時にデータ
class DragAndDropData{
  int dataType;   //0:spot, 1:traffic, 2:memo
  int iniId;
  int dataId;   //各データのID
  String memo;  //メモの時使う
  bool alreadyFlag; //既にプラン一覧にあるかどうか

  DragAndDropData(this.dataType, this.iniId, this.dataId, this.memo, this.alreadyFlag);
}

//パレットの交通データ
class TrafficPartData{
  IconData icon;
  String trafficType;

  TrafficPartData(this.icon, this.trafficType);
}

class MakePlanEdit extends StatefulWidget {
  final int planId;
  final DateTime startDateTime;
  final DateTime endDateTime;

  MakePlanEdit({
    Key key,
    this.planId,
    this.startDateTime,
    this.endDateTime,
  }):super(key: key);

  @override
  _MakePlanEditState createState() => _MakePlanEditState();
}

class _MakePlanEditState extends State<MakePlanEdit> with TickerProviderStateMixin {

  GoogleMapController mapController;
  TabController _tabController;
  TabController _menuTabController;
  //開始日
  DateTime _startDateTime;
  DateTime _endDateTime;

  //行程のリスト
  List<ItineraryData> _itineraries = [];
  //行程スポットのリスト
  List<SpotItineraryData> _spotItineraries = [];
  //行程メモのリスト
  List<MemoItineraryData> _memoItineraries = [];
  //行程交通機関のリスト
  List<TrafficItineraryData> _trafficItineraries = [];
  //スポットのリスト(DBから取ってきて入れる感じ？)
  List<SpotData> _spots = [];

  //メニューパレットの交通のリスト
  List<TrafficPartData> _trafficPartData =[
    TrafficPartData(Icons.directions_walk, "徒歩"),
    TrafficPartData(Icons.directions_car, "自動車"),
    TrafficPartData(Icons.directions_transit, "電車"),
    TrafficPartData(Icons.airplanemode_active, "飛行機"),
  ];

  //spot入れてるこの方法よくない
  DragAndDropData _dragAndDropData;

  //Dragしてるかどうかのフラグ
  bool _dragFlag = false;
  //下の部分のフラグ
  bool _underFlag = false;

  //旅行の日程　とりあえず仮
  List<DateTime> _travelDateTime = [];


  //マーカー
  Set<Marker> _markers = Set();

  List<String> _hourList = ["0", "1", "2", "3", "4", "5", "6"];
  List<String> _minutesList = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

  //選択している日付削除できるかフラグ
  bool _dateDeleteFlag = true;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  @override
  void initState(){
    super.initState();
    _spots.clear();
    _itineraries.clear();
    _spotItineraries.clear();
    _memoItineraries.clear();
    _getSpot();
    _getItiData();

   // _memoItineraries.add(MemoItineraryData(2, "メモですメモです"));

    _travelDateTime = _getDateTimeList(widget.startDateTime, widget.endDateTime);

    _tabController = TabController(length: _travelDateTime.length, vsync: this);
    _tabController.addListener(_handleDateTabSelection);
    _menuTabController = TabController(length: 3, vsync: this);

    _startDateTime = widget.startDateTime;
    _endDateTime = widget.endDateTime;
  }

  void _getItiData() async{
    //行程データ取得
    http.Response response = await Network().getData("itinerary/get/" + widget.planId.toString());
    List<dynamic> list = json.decode(response.body);
    List<int> ids = [];
    for(int i=0; i<list.length; i++){
      DateTime date = DateTime.parse(list[i]["day"]);
      _itineraries.add(ItineraryData(list[i]["id"], list[i]["itinerary_order"], list[i]["spot_order"], list[i]["plan_id"], date, false));
      ids.add(list[i]["id"]);
      print(list[i]["id"].toString());
    }
    
    final data = {
      "ids" : ids,
    };

    //List<String> id = [];
    http.Response responseSpot = await Network().postData(data, "itinerary/get/spot");
    print(responseSpot.body);
    List list2 = json.decode(responseSpot.body);
    int flag = 0;
    for(int i=0; i<list2.length; i++){
      DateTime startDate = list2[i]["start_date"] == null ? null :DateTime.parse(list2[i]["start_date"]);
      DateTime endDate = list2[i]["end_date"] == null ? null :DateTime.parse(list2[i]["end_date"]);
      _spotItineraries.add(SpotItineraryData(list2[i]["id"], list2[i]["itinerary_id"], list2[i]["spot_id"], list2[i]["spot_name"], list2[i]["latitube"], list2[i]["longitube"], list2[i]["image_url"], startDate , endDate, 0));

      //最初の日付だけマーカをつける
      if(_itineraries[_itineraries.indexWhere((element) => element.itineraryID == list2[i]["itinerary_id"])].itineraryDateTime == _travelDateTime[0]){
        final Uint8List markerIcon = await getBytesFromCanvas(80, 80, _itineraries[i].spotOrder);
        Marker locationMarker = Marker(
          markerId: MarkerId(list2[i]["itinerary_id"].toString()),
          position: LatLng(list2[i]["latitube"],list2[i]["longitube"]),
          icon: BitmapDescriptor.fromBytes(markerIcon)
        );
        _markers.add(locationMarker);
        if(flag == 0){
          mapController.animateCamera(CameraUpdate.newLatLng(LatLng(list2[i]["latitube"],list2[i]["longitube"])));
          flag = 1;
        }
      }
    }

    http.Response responseTraffic = await Network().postData(data, "itinerary/get/traffic");
    List list3 = json.decode(responseTraffic.body);
    for(int i=0; i<list3.length; i++){
      _trafficItineraries.add(TrafficItineraryData(list3[i]["id"], list3[i]["itinerary_id"], list3[i]["traffic_class"], list3[i]["travel_time"], list3[i]["traffic_cost"]));
    }

    http.Response responseMemo = await Network().postData(data, "itinerary/get/note");
    List list4 = json.decode(responseMemo.body);
    for(int i=0; i<list4.length; i++){
      _memoItineraries.add(MemoItineraryData(list4[i]['id'], list4[i]['itinerary_id'], list4[i]['memo']));
    }

    setState(() {
      _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
    });
  }

  //スポットデータ取得
  void _getSpot() async{
    http.Response response = await Network().getData("planspot/get/" + widget.planId.toString());
    List<dynamic> list = json.decode(response.body);

    for(int i=0; i<list.length; i++){
      _spots.add(
          SpotData(list[i]["spot_id"], list[i]["spot_name"], list[i]["latitube"], list[i]["longitube"], list[i]["image_url"], list[i]["place_id"], 1)
      );
    }

    setState(() {

    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuTabController.dispose();
    super.dispose();
  }

  //日付のリストを作る
  List<DateTime> _getDateTimeList(DateTime startDate, DateTime endDate){
    List<DateTime> dateList = [];
    print("aa");

    //1日だけのとき
    if(startDate == endDate){
      dateList.add(startDate);
      return dateList;
    }

    //2日以上あるとき
    DateTime date = startDate;
    DateTime lastDate = DateTime(endDate.year, endDate.month, endDate.day+1);
    while(date != lastDate){
      dateList.add(date);
      date = DateTime(date.year, date.month, date.day+1);
    }

    return dateList;
  }

  //日付追加の処理
  _addDateTime() async{
    _endDateTime = DateTime(_endDateTime.year, _endDateTime.month, _endDateTime.day+1);

    String startDate = DateFormat('yy-MM-dd').format(_startDateTime);
    String endDate = DateFormat('yy-MM-dd').format(_endDateTime);

    final data = {
      "id" : widget.planId,
      "start_day" : startDate,
      "end_day" : endDate,
    };

    http.Response response = await Network().postData(data, "plan/update/date");

    setState(() {
      _travelDateTime.add(_endDateTime);
      _tabController = _createNewTabController();
      _tabController.addListener(_handleDateTabSelection);
    });
    _tabController.animateTo(_tabController.length-1);

  }

  //日付削除の処理
  _deleteDateTime() async{
    //確認ダイアログ
    bool flg = false;

    await showDialog(
        context: context,
        builder:(context){
          return StatefulBuilder(
              builder: (_, setState) {
                return AlertDialog(
                  content: SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top:10 ,bottom: 15.0),
                            child: Text(_travelDateTime[_tabController.index].month.toString() + "/" +  _travelDateTime[_tabController.index].day.toString() + "の予定を削除してよろしいでしょうか？" ,style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 30.0),
                              child: Text("※削除したプランは元に戻りません" ,style: TextStyle(color: Colors.red, fontSize: 13.0,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            height: 40,
                            width: 250,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  child: Container(
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.grey,
                                    ),
                                    child: Center(
                                      child: Text("いいえ", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                ),
                                GestureDetector(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 10.0),
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.orange,
                                    ),
                                    child: Center(
                                      child: Text("はい", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    flg = true;
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      )
                    )
                  ),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32.0)))
                );
              }
          );
        }
    );

    if(!flg){
      return null;
    }

    //削除する日付の行程データを削除
    String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);
    print(day);
    http.Response res = await Network().getData("itinerary/day/delete/" + day);
    print(res.body);

    var removeId = [];

    _itineraries.forEach((element) {
      if(_dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
        removeId.add(element.itineraryID);
      }
    });

    _itineraries.removeWhere((element) => removeId.contains(element.itineraryID));

    //リストから日付削除
    _travelDateTime.removeAt(_tabController.index);

    _startDateTime = _travelDateTime[0];
    _endDateTime = _travelDateTime[_travelDateTime.length-1];

    String startDate = DateFormat('yy-MM-dd').format(_startDateTime);
    String endDate = DateFormat('yy-MM-dd').format(_endDateTime);

    final data = {
      "id" : widget.planId,
      "start_day" : startDate,
      "end_day" : endDate,
    };

    http.Response response = await Network().postData(data, "plan/update/date");
    print(response.body);

    if(_travelDateTime.length == 1){
      _dateDeleteFlag = false;
    }

    //タブから日付削除
    _tabController = _createNewTabController();
    setState(() {

    });

  }

  TabController _createNewTabController() => TabController(
    vsync: this,
    length: _travelDateTime.length,
  );

  //スポットパレットからプランに追加したときの処理
  _addSpotToPlan(int index) async{
    if(_dragAndDropData.alreadyFlag){
      print("add_index"+ index.toString());
      //並び替え時
      //iniIDからindex求める
      int iniIndex = _itineraries.indexWhere((element) => element.itineraryID == _dragAndDropData.dataId);
      ItineraryData tempItineraryData = _itineraries[iniIndex];

      print("temp:" + tempItineraryData.itineraryID.toString() + "," + tempItineraryData.spotOrder.toString());
      print("go:" + _itineraries[index].itineraryID.toString() + "," + _itineraries[index].spotOrder.toString());

      //移動予定のorder
      int goOrder = _itineraries[index].itineraryOrder;
      int goSpotOrder = _itineraries[index].spotOrder;
      if(tempItineraryData.itineraryOrder > goOrder){
        goOrder++;
        goSpotOrder++;
        if(goOrder == tempItineraryData.itineraryOrder){
          return null;
        }
      }else if(goOrder == tempItineraryData.itineraryOrder){
        return null;
      }
      print("goOrder:" + goOrder.toString());
      //一覧から対象のスポットを取り除く
      //_itineraries.removeAt(iniIndex);

      //並び替え
      for(int i=0; i < _itineraries.length; i++){
        //現在の位置から上に並び替えしているか、下に並び替えしているか
        if(_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          if(tempItineraryData.itineraryOrder > goOrder){
            //下から上
            if(_itineraries[i].itineraryOrder >= goOrder && _itineraries[i].itineraryOrder < tempItineraryData.itineraryOrder){
              print("test5");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder +1;
              _itineraries[i].spotOrder = _itineraries[i].spotOrder +1;
            }
          }else {
            //上から下
            //print("i:" + "id:" +  _itineraries[i].itineraryID.toString() + " order:" + _itineraries[i].itineraryOrder.toString());
            if(_itineraries[i].itineraryOrder <= goOrder && _itineraries[i].itineraryOrder > tempItineraryData.itineraryOrder){
              print("test4");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
              _itineraries[i].spotOrder = _itineraries[i].spotOrder -1;
            }
          }
        }
      }

      http.Response res = await Network().getData("itinerary/rearrange/" + _dragAndDropData.dataId.toString() + "/" + goOrder.toString() + "/" + goSpotOrder.toString() + "/" + _dragAndDropData.dataType.toString());

      _handleDateTabSelection();
      print(res.body);
      setState(() {
        //行程リストに追加
        _itineraries[iniIndex].itineraryOrder = goOrder;
        _itineraries[iniIndex].spotOrder = goSpotOrder;
       // _spotItineraries.add(SpotItineraryData(len, _spots[_dragAndDropData.dataId].spotId, _spots[_dragAndDropData.dataId].spotName, _spots[_dragAndDropData.dataId].spotImagePath, null, null, 0));
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      _dragAndDropData = null;

    }else{
      print("追加します！");

      //追加
      //index以下のitineraryOrderの値を1ふやす
      for(int i=index+1; i < _itineraries.length; i++){
        if(_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          ItineraryData tempItineraryData = _itineraries[i];
          _itineraries.removeAt(i);
          _itineraries.insert(i, ItineraryData(tempItineraryData.itineraryID, tempItineraryData.itineraryOrder+1, tempItineraryData.spotOrder+1, 1, tempItineraryData.itineraryDateTime, tempItineraryData.accepting));
        }
      }
      //int len = _id;
      String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);

      int order = 0;
      int spotOrder = 0;

      if(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) == -1){
        order = 1;
        spotOrder = 1;
      }else{
        order = _itineraries[index].itineraryOrder+1;
        spotOrder = _itineraries[index].spotOrder+1;
      }

      //DBに登録
      final data = {
        "order" : order,
        "day" : day,
        "plan_id" : widget.planId,
        "spot_order" : spotOrder,
        "spot_id" : _spots[_dragAndDropData.dataId].spotId,
        "type" : 0
      };
      http.Response res = await Network().postData(data, "itinerary/store");
      print("id" + res.body);
      List<dynamic> ids = jsonDecode(res.body);

      //行程リストに追加
      print(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])).toString());
      if(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) == -1){
        if(_itineraries.length == 0){
          _itineraries.insert(0, ItineraryData(int.parse(ids[0]), 1, 1, widget.planId, _travelDateTime[_tabController.index], false));
        }else{
          _itineraries.insert(index + 1, ItineraryData(int.parse(ids[0]), 1, 1, widget.planId, _travelDateTime[_tabController.index], false));
        }
      }else{
        _itineraries.insert(index + 1, ItineraryData(int.parse(ids[0]), _itineraries[index].itineraryOrder + 1, _itineraries[index].spotOrder + 1, widget.planId, _travelDateTime[_tabController.index], false));
      }
      //_itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder + 1, 1, _travelDateTime[_tabController.index], false));
      //行程スポットリストに追加
      _spotItineraries.add(SpotItineraryData(int.parse(ids[1]), int.parse(ids[0]), _spots[_dragAndDropData.dataId].spotId, _spots[_dragAndDropData.dataId].spotName, _spots[_dragAndDropData.dataId].latitude, _spots[_dragAndDropData.dataId].longitude, _spots[_dragAndDropData.dataId].spotImagePath, null, null, 0));
      
      int spotIndex = _spotItineraries.indexWhere((element) => element.itineraryId == int.parse(ids[0].toString()));

      //マーカーを追加
      final Uint8List markerIcon = await getBytesFromCanvas(80, 80, spotOrder);

      Marker locationMarker = Marker(
          markerId: MarkerId(_spotItineraries[spotIndex].itineraryId.toString()),
          position: LatLng(_spotItineraries[spotIndex].latitude,_spotItineraries[spotIndex].longitude),
          icon: BitmapDescriptor.fromBytes(markerIcon)
      );
      _markers.add(locationMarker);
      mapController.animateCamera(CameraUpdate.newLatLng(LatLng(_spotItineraries[spotIndex].latitude,_spotItineraries[spotIndex].longitude)));

      setState(() {

      });
      print("test : " + day + " , " + order.toString());

      //print(jsonEncode(data));
      //print("aa" + res.body.toString());
      
      _dragAndDropData = null;
    }
  }

  //交通パレットからプランに追加したときの処理
  _addTrafficToPlan(int trafficType, int index) async{
    int iniIndex = _itineraries.indexWhere((element) => element.itineraryID == _dragAndDropData.dataId);

    String trafficTime = "";
    int cost = 400;

    int type = trafficType;
    int traId = _trafficItineraries.indexWhere((element) => element.itineraryId == _dragAndDropData.dataId);
    if(_dragAndDropData.alreadyFlag){
      type = _trafficItineraries[traId].trafficClass;
    }

    print("traffic iniIndex : " + iniIndex.toString());
    //スポットの合間にあるかどうか
    int upIniIndex = _itineraries.indexWhere((element){
      if(element.itineraryDateTime == _itineraries[index].itineraryDateTime && element.itineraryOrder == _itineraries[index].itineraryOrder){
        if(_spotItineraries.indexWhere((element) => element.itineraryId == _itineraries[index].itineraryID) != -1){
          return true;
        }
      }
      return false;
    });

    int downIniIndex = _itineraries.indexWhere((element){
      if(element.itineraryDateTime == _itineraries[index].itineraryDateTime && element.itineraryOrder == _itineraries[index].itineraryOrder + 1){
        if(_spotItineraries.indexWhere((element) => element.itineraryId == _itineraries[index].itineraryID) != -1){
          return true;
        }
      }
      return false;
    });

    int upSpotIndex = -1;
    int downSpotIndex = -1;

    if(upIniIndex > -1 && downIniIndex > -1){
      upSpotIndex = _spotItineraries.indexWhere((element) => element.itineraryId == _itineraries[upIniIndex].itineraryID);
      downSpotIndex = _spotItineraries.indexWhere((element) => element.itineraryId == _itineraries[downIniIndex].itineraryID);
    }

    if(upSpotIndex > -1 && downSpotIndex > -1){

      print("up down Spot: " + upSpotIndex.toString() + "," + downSpotIndex.toString());
      String start = _spotItineraries[upSpotIndex].latitude.toString() + "," + _spotItineraries[upSpotIndex].longitude.toString();
      String end = _spotItineraries[downSpotIndex].latitude.toString() + "," + _spotItineraries[downSpotIndex].longitude.toString();

      print("start end:" + start + "," + end);
      trafficTime = await DirectionApi().getDirection(start, end, type-1);
    }

    print("up down :" + upIniIndex.toString() + "," + downIniIndex.toString());

    if(_dragAndDropData.alreadyFlag){
      int goOrder = _itineraries[index].itineraryOrder;
      ItineraryData tempItineraryData = _itineraries[iniIndex];
      if(tempItineraryData.itineraryOrder > goOrder){
        goOrder++;
        if(goOrder == tempItineraryData.itineraryOrder){
          return null;
        }
      }else if(goOrder == tempItineraryData.itineraryOrder){
        return null;
      }

      print("あああgoOrder:" + goOrder.toString() + " dataId:" + _dragAndDropData.dataId.toString());

      //orderの値変更
      for(int i=0; i < _itineraries.length; i++) {
        //現在の位置から上に並び替えしているか、下に並び替えしているか
        if (_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) {
          if (tempItineraryData.itineraryOrder > goOrder) {
            //下から上
            if (_itineraries[i].itineraryOrder >= goOrder && _itineraries[i].itineraryOrder < tempItineraryData.itineraryOrder) {
              print("test5");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder + 1;
            }
          } else {
            //上から下
            //print("i:" + "id:" +  _itineraries[i].itineraryID.toString() + " order:" + _itineraries[i].itineraryOrder.toString());
            if (_itineraries[i].itineraryOrder <= goOrder && _itineraries[i].itineraryOrder > tempItineraryData.itineraryOrder) {
              print("test4");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
            }
          }
        }
      }

      print("traffictest: " + _dragAndDropData.dataId.toString());
      if(trafficTime != ""){
        _trafficItineraries[traId].travelTime = trafficTime;
        final data = {
          "id" : _trafficItineraries[traId].id,
          "travel_time" : trafficTime,
        };

        http.Response res = await Network().postData(data, "itinerary/update/traffic/time");
        print(res.body);

      }

      //並び替え時
      setState(() {
        _itineraries[iniIndex].itineraryOrder = goOrder;
        _itineraries[iniIndex].spotOrder = _itineraries[index].spotOrder;
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      http.Response res = await Network().getData("itinerary/rearrange/" + _dragAndDropData.dataId.toString() + "/" + goOrder.toString() + "/" + _itineraries[index].spotOrder.toString() + "/"+ _dragAndDropData.dataType.toString());
    }else{
      //追加時
      String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);

      //APIから時間取れなかったとき
      if(trafficTime == ""){
        trafficTime = await _showTrafficTimeDialog();
      }
      if(trafficTime == ""){
        return null;
      }

      print("trafficTime:" + trafficTime);

      print("test : " + day + " , " + _itineraries[index].itineraryOrder.toString());
      final data = {
        "order" : _itineraries[index].itineraryOrder + 1,
        "spot_order" : _itineraries[index].spotOrder,
        "day" : day,
        "plan_id" : widget.planId,
        "type" : 1,
        "traffic_class" : _dragAndDropData.dataId,
        "travel_time" : trafficTime,
        "traffic_cost" : 0,
      };

      http.Response res = await Network().postData(data, "itinerary/store");
      print(res.body);

      //orderの値変更
      for(int i=0; i<_itineraries.length; i++){
        if(_itineraries[i].itineraryOrder > _itineraries[index].itineraryOrder &&_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder + 1;
        }
      }

      List<dynamic> ids = jsonDecode(res.body);

      setState(() {
        //行程リストに追加
        _itineraries.insert(index + 1, ItineraryData(int.parse(ids[0]), _itineraries[index].itineraryOrder + 1, _itineraries[index].spotOrder, widget.planId,  _travelDateTime[_tabController.index], false));
        //行程交通リストに追加
        _trafficItineraries.add(TrafficItineraryData(int.parse(ids[1]), int.parse(ids[0]), _dragAndDropData.dataId, trafficTime, cost));
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      _dragAndDropData = null;
    }
  }

  Future<String> _showTrafficTimeDialog() async{
    String time = "";
    String hour = "0";
    String minutes1 = "0";
    String minutes2 = "0";
    //文字入力
    await showDialog(
        context: context,
        builder:(context){
          return StatefulBuilder(
              builder: (_, setState) {
                return AlertDialog(
                  title: Text("時間の設定", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  content: SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 40.0,
                                width: 60.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Center(
                                  child: DropdownButton<String>(
                                    value: hour,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                    onChanged: (String newValue) {
                                      setState(() {
                                        hour = newValue;
                                      });
                                    },
                                    items: _hourList
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                child: Text("時間"),
                              ),
                              Container(
                                  height: 40.0,
                                  width: 120.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      DropdownButton<String>(
                                        value: minutes1,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        onChanged: (String newValue) {
                                          setState(() {
                                            minutes1 = newValue;
                                          });
                                        },
                                        items: _minutesList
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                          );
                                        }).toList(),
                                      ),
                                      DropdownButton<String>(
                                        value: minutes2,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        onChanged: (String newValue) {
                                          setState(() {
                                            minutes2 = newValue;
                                          });
                                        },
                                        items: _minutesList
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  )
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text("分"),
                              )
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top:20.0),
                            height: 40,
                            width: 250,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  child: Container(
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.grey,
                                    ),
                                    child: Center(
                                      child: Text("キャンセル", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                ),
                                GestureDetector(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 10.0),
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.orange,
                                    ),
                                    child: Center(
                                      child: Text("確定", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                  ),
                   shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)))
                );
              }
          );
        }
    );
    return time;
  }

  //その他パレットからプランに追加したときの処理
  _addMemoToPlan(int index) async{
    int iniIndex = _itineraries.indexWhere((element) => element.itineraryID == _dragAndDropData.iniId);

    if(_dragAndDropData.alreadyFlag){
      //メモ並び替え時

      int goOrder = _itineraries[index].itineraryOrder;
      ItineraryData tempItineraryData = _itineraries[iniIndex];

      if(tempItineraryData.itineraryOrder > goOrder){
        goOrder++;
        if(goOrder == tempItineraryData.itineraryOrder){
          return null;
        }
      }else if(goOrder == tempItineraryData.itineraryOrder){
        return null;
      }

      print("あああgoOrder:" + goOrder.toString() + " dataId:" + _dragAndDropData.dataId.toString());

      //orderの値変更
      for(int i=0; i < _itineraries.length; i++) {
        //現在の位置から上に並び替えしているか、下に並び替えしているか
        if (_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) {
          if (tempItineraryData.itineraryOrder > goOrder) {
            //下から上
            if (_itineraries[i].itineraryOrder >= goOrder && _itineraries[i].itineraryOrder < tempItineraryData.itineraryOrder) {
              print("test5");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder + 1;
            }
          } else {
            //上から下
            //print("i:" + "id:" +  _itineraries[i].itineraryID.toString() + " order:" + _itineraries[i].itineraryOrder.toString());
            if (_itineraries[i].itineraryOrder <= goOrder && _itineraries[i].itineraryOrder > tempItineraryData.itineraryOrder) {
              print("test4");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
            }
          }
        }
      }

      //並び替え時
      setState(() {
        _itineraries[iniIndex].itineraryOrder = goOrder;
        _itineraries[iniIndex].spotOrder = _itineraries[index].spotOrder;
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      http.Response res = await Network().getData("itinerary/rearrange/" + _dragAndDropData.iniId.toString() + "/" + goOrder.toString() + "/" + _itineraries[index].spotOrder.toString() + "/"+ _dragAndDropData.dataType.toString());

      print(res.body);
    }else{
      String memo = "";
      //文字入力
      await showDialog(
          context: context,
          builder: (_){
            return AlertDialog(
              title: Text("メモの内容",style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 40.0,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color:Color(0xffACACAC),),
                          focusColor: Theme.of(context).primaryColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Color(0xffACACAC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                        onChanged: (value){
                          memo = value;
                        },
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top:20.0),
                      height: 40,
                      width: 250,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            child: Container(
                              height: 40.0,
                              width: 100.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30.0),
                                color: Colors.grey,
                              ),
                              child: Center(
                                child: Text("キャンセル", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            onTap: (){
                              Navigator.of(context, rootNavigator: true).pop(context);
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(left: 10.0),
                              height: 40.0,
                              width: 100.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30.0),
                                color: Colors.orange,
                              ),
                              child: Center(
                                child: Text("確定", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            onTap: (){
                              Navigator.of(context, rootNavigator: true).pop(context);
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32.0)))
            );
          }
      );

      if(memo == ""){
        return null;
      }

      String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);

      //メモ追加時
      final data = {
        "order" : _itineraries[index].itineraryOrder + 1,
        "spot_order" : _itineraries[index].spotOrder,
        "day" : day,
        "plan_id" : widget.planId,
        "type" : 2,
        "memo" : memo,
      };

      http.Response res = await Network().postData(data, "itinerary/store");
      print(res.body);
      List<dynamic> ids = jsonDecode(res.body);

      //orderの値変更
      for(int i=0; i<_itineraries.length; i++){
        if(_itineraries[i].itineraryOrder > _itineraries[index].itineraryOrder &&_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder + 1;
        }
      }

      setState(() {
        //行程リストに追加
        _itineraries.insert(index + 1, ItineraryData(int.parse(ids[0]), _itineraries[index].itineraryOrder + 1, _itineraries[index].spotOrder, widget.planId,  _travelDateTime[_tabController.index], false));
        //行程メモリストに追加
        _memoItineraries.add(MemoItineraryData(int.parse(ids[1]), int.parse(ids[0]), memo));
         _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      _dragAndDropData = null;

    }


  }

  //削除
  _deletePartPlan(int iniId) async{
    if(_dragAndDropData.alreadyFlag){
      ItineraryData tempIti;
      if(_dragAndDropData.dataType == 0){
        //スポットのとき
        int index = _itineraries.indexWhere((element) => element.itineraryID == iniId);
        tempIti = _itineraries[index];
        _itineraries.removeAt(index);
        _spotItineraries.removeAt(_spotItineraries.indexWhere((element) => element.itineraryId == iniId));

        _handleDateTabSelection();
        setState(() {

        });

      }else if(_dragAndDropData.dataType == 1){
        //交通のとき
        setState(() {
          tempIti = _itineraries[_itineraries.indexWhere((element) => element.itineraryID == iniId)];
          _itineraries.removeAt(_itineraries.indexWhere((element) => element.itineraryID == iniId));
          _trafficItineraries.removeAt(_trafficItineraries.indexWhere((element) => element.itineraryId == iniId));
        });
      }else{
        //メモのとき
        setState(() {
          tempIti = _itineraries[_itineraries.indexWhere((element) => element.itineraryID == iniId)];
          _itineraries.removeAt(_itineraries.indexWhere((element) => element.itineraryID == iniId));
          _memoItineraries.removeAt(_memoItineraries.indexWhere((element) => element.itineraryId == iniId));
        });
      }

      //順番の変更
      for(int i=0; i<_itineraries.length; i++){
        if(_itineraries[i].itineraryOrder > tempIti.itineraryOrder && _dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
          if(_dragAndDropData.dataType == 0){
            _itineraries[i].spotOrder = _itineraries[i].spotOrder - 1;
          }
        }
      }

      http.Response res = await Network().getData("itinerary/delete/" + iniId.toString() + "/" + _dragAndDropData.dataType.toString());
      print(res.body);

      _dragAndDropData = null;
    }
  }
  
  DateTime _dataTimeFunc(DateTime date){
    return DateTime(date.year, date.month, date.day);
  }

  //日付変える度にマーカを変える
  void _handleDateTabSelection() async{
    _markers.clear();
    int flag = 0;
    for(int i=0; i<_itineraries.length; i++){
      if(_itineraries[i].itineraryDateTime == _travelDateTime[_tabController.index]){
        int spotIndex = _spotItineraries.indexWhere((element) => element.itineraryId == _itineraries[i].itineraryID);
        print("spotIndex:" + spotIndex.toString());
        if(spotIndex != -1){
          //マーカーを追加
          final Uint8List markerIcon = await getBytesFromCanvas(80, 80,  _itineraries[i].spotOrder);

          Marker locationMarker = Marker(
              markerId: MarkerId(_itineraries[i].itineraryID.toString()),
              position: LatLng(_spotItineraries[spotIndex].latitude,_spotItineraries[spotIndex].longitude),
              icon: BitmapDescriptor.fromBytes(markerIcon)
          );
          _markers.add(locationMarker);
          if(flag == 0){
            mapController.animateCamera(CameraUpdate.newLatLng(LatLng(_spotItineraries[spotIndex].latitude,_spotItineraries[spotIndex].longitude)));
            flag = 1;
          }
        }
      }
      if(_tabController.index == 0 || _tabController.index == _travelDateTime.length - 1){
        if(_travelDateTime.length > 1){
          _dateDeleteFlag = true;
        }
      }else{
        _dateDeleteFlag = false;
      }
    }
    setState(() {
      print("flg:" + _dateDeleteFlag.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              //GoogleMap表示
              Container(
                constraints: BoxConstraints.expand(height: 150.0),
                child: GoogleMap(
                  onTap: (latLang){
                    print(latLang.longitude.toString() + "," +latLang.latitude.toString());
                  },
                  markers: _markers,
                  mapType: MapType.terrain,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(35.6580339,139.7016358),
                    zoom: 11.0,
                  ),
                  scrollGesturesEnabled: true,
                ),
              ),
              //日程一覧タブ表示
              Row(
                children: [
                  GestureDetector(
                    child: Container(
                      height: 50.0,
                      width: MediaQuery.of(context).size.width/6,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(4, 4), // changes position of shadow
                            ),
                          ]
                      ),
                      child: Container(
                        child: _dateDeleteFlag ? Icon(Icons.remove_circle_outline, size: 30.0,) : Icon(Icons.remove_circle_outline, size: 30.0, color: Colors.black.withOpacity(0.2),),
                      ),
                    ),
                    onTap: (){
                      if(_dateDeleteFlag){
                        _deleteDateTime();
                      }
                    },
                  ),
                  Container(
                    height: 50.0,
                    width: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width/6 * 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(4, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: TabBar(
                      isScrollable: true,
                      controller: _tabController,
                      labelColor: Colors.black,
                      labelStyle: TextStyle(fontSize: 18.0),
                      tabs: [
                        for(int i=0;i<_travelDateTime.length; i++)
                          Container(
                            child: Text(_travelDateTime[i].month.toString() + "/" + _travelDateTime[i].day.toString()),
                          ),
                        // Container(
                        //   //width: 70.0,
                        //   child: Icon(Icons.add_circle_outline, size: 30.0,),
                        // )
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: Container(
                      height: 50.0,
                      width: MediaQuery.of(context).size.width/6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(4, 4), // changes position of shadow
                          ),
                        ]
                      ),
                      child: Container(
                        child: Icon(Icons.add_circle_outline, size: 30.0,),
                      ),
                    ),
                    onTap: _addDateTime,
                  )
                ],
              ),
              //行程表示
              Expanded(
                child: Container(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for(int i=0; i<_tabController.length; i++)
                        _buildPlanPalette(i),
                    ],
                  ),
                ),
              )
            ],
          ),
          if(!_dragFlag)
          //パレットタブ部分
            Positioned(
              bottom: MediaQuery.of(context).size.height / 5,
              left: 0.0,
              width: MediaQuery.of(context).size.width,
              child: TabBar(
                controller: _menuTabController,
                indicatorWeight: 1,
                tabs: [
                  _buildMenuItem(Icons.place, "スポット"),
                  _buildMenuItem(Icons.directions_car, "交通"),
                  _buildMenuItem(Icons.adb, "その他"),
                ],
              ),
            ),
          if(!_dragFlag)
            //パレットメイン部分
            Positioned(
                bottom: 0.0,
                height: MediaQuery.of(context).size.height / 5,
                width: MediaQuery.of(context).size.width,
                child: TabBarView(
                  controller: _menuTabController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildMenuPalette(1),
                    _buildMenuPalette(2),
                    _buildMenuPalette(3),
                  ],
                )
            ),
          Positioned(
            top: 40.0,
            left: 10.0,
            height: 40.0,
            width: 40.0,
            child: GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle
                ),
                child: Center(
                  child: Icon(Icons.arrow_back_ios_outlined, color: Colors.black,),
                ),
              ),
              onTap: (){
                Navigator.of(context).pop();
              },
            ),
          ),
          if(_dragFlag)
          //削除パレット部分
            Positioned(
                bottom: 0.0,
                height: MediaQuery.of(context).size.height / 5,
                width: MediaQuery.of(context).size.width,
                child: _buildDeletePalette()
            ),
        ],
      ),
    );
  }

  //プランの一覧作るところ
  Widget _buildPlanPalette(int index){
    int testId = 1;
    return SingleChildScrollView(
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //まだ何も入ってないとき
          if(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[index])) == -1)
            DragTarget <DragAndDropData>(
              onAccept: (receivedItem){
                setState(() {
                  switch(_dragAndDropData.dataType){
                    case 0:
                      _addSpotToPlan(0);
                      break;
                  }
                });
              },
              onWillAccept: (receivedItem){
                setState(() {
                  _dragAndDropData = receivedItem;
                  //_itineraries[i].accepting = true;
                });
                print("dataId" + _dragAndDropData.dataId.toString());
                return true;
              },
              onLeave: (receivedItem){
                setState(() {
                  _dragAndDropData = null;
                  //_itineraries[i].accepting = false;
                });
              },
              builder: (context, acceptedItem, rejectedItem){
                Widget planListWidget;
                if(_dragAndDropData !=null){
                  if(_dragAndDropData.dataType == 0){
                    planListWidget = Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 15.0, top: 20.0),
                          child: PlanPart(
                            id: 1,
                            number: 1,
                            spotName: _spots[_dragAndDropData.dataId].spotName,
                            spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                            spotStartDateTime: null,
                            spotEndDateTime: null,
                            spotParentFlag: 0,
                            confirmFlag: false,
                            width: MediaQuery.of(context).size.width,
                            flg: true,
                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height/2,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ],
                    );
                  }else{
                    planListWidget = Container(
                      height: MediaQuery.of(context).size.height/2,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Text("先にスポットを入れてね！"),
                      ),
                    );
                  }
                }else{
                  planListWidget = Container(
                    height: MediaQuery.of(context).size.height/2,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Text("ここにスポットをドロップ！"),
                    ),
                  );
                }

                return planListWidget;
              },
            ),
          for(int i=0; i < _itineraries.length; i++)
           if(_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[index]))
             DragTarget <DragAndDropData>(
               onAccept: (receivedItem){
                 setState(() {
                   _itineraries[i].accepting = false;
                   switch(_dragAndDropData.dataType){
                     case 0:
                       _addSpotToPlan(i);
                       break;
                     case 1:
                       _addTrafficToPlan(_dragAndDropData.dataId, i);
                       break;
                     case 2:
                       _addMemoToPlan(i);
                       break;
                   }
                 });
               },
                 onWillAccept: (receivedItem){
                   setState(() {
                     _dragAndDropData = receivedItem;
                     _itineraries[i].accepting = true;
                   });
                   print("dataId" + _dragAndDropData.dataId.toString());
                   return true;
                 },
                 onLeave: (receivedItem){
                   setState(() {
                     _dragAndDropData = null;
                     _itineraries[i].accepting = false;
                   });
                 },
                 builder: (context, acceptedItem, rejectedItems) {
                   testId = i;
                   //print("testId" + testId.toString());
                   Widget dragTargetBuilder = Container();
                   if(!_itineraries[i].accepting){
                     dragTargetBuilder = Container(
                       margin: EdgeInsets.only(left: 15.0, top: 20.0),
                       child:_buildPlanPart(
                         _itineraries[i].itineraryID,
                         _itineraries[i].spotOrder
                       ),
                     );
                   }else{
                     switch(_dragAndDropData.dataType){
                     //dataTypeによって振り分ける
                     // 0 : プラン
                       case 0:
                         int itiId = _spotItineraries.indexWhere((element) => element.itineraryId == _dragAndDropData.dataId);
                         print("itiId : " + itiId.toString());
                         dragTargetBuilder = Column(
                           children: [
                             Container(
                               margin: EdgeInsets.only(left: 15.0, top: 10.0),
                               child: _buildPlanPart(
                                   _itineraries[i].itineraryID,
                                   _itineraries[i].spotOrder
                               ),
                             ),
                             //追加時
                             if(_dragAndDropData.alreadyFlag == false)
                               Container(
                                 margin: EdgeInsets.only(left: 15.0, top: 10.0),
                                 child: PlanPart(
                                   id:1,
                                   //number: _itineraries[i].itineraryOrder + 1,
                                   number: _itineraries[i].spotOrder + 1,
                                   spotName: _spots[_dragAndDropData.dataId].spotName,
                                   spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                                   spotStartDateTime: null,
                                   spotEndDateTime: null,
                                   spotParentFlag: 0,
                                   confirmFlag: false,
                                   width: MediaQuery.of(context).size.width,
                                   flg: false,
                                   day: DateTime.now(),
                                 ),
                               ),
                             //並び替え時
                             if(_dragAndDropData.alreadyFlag == true)
                               Container(
                                 margin: EdgeInsets.only(left: 15.0, top: 10.0),
                                 child: PlanPart(
                                   id:1,
                                   number: _itineraries[i].spotOrder + 1,
                                   spotName: _spotItineraries[itiId].spotName,
                                   spotPath: _spotItineraries[itiId].spotImagePath,
                                   spotStartDateTime: _spotItineraries[itiId].spotStartDateTime,
                                   spotEndDateTime: _spotItineraries[itiId].spotEndDateTime,
                                   spotParentFlag: 0,
                                   confirmFlag: false,
                                   width: MediaQuery.of(context).size.width,
                                   flg: false,
                                   day: DateTime.now(),
                                 ),
                               ),
                           ],
                         );
                         break;
                       case 1 :
                         int itiId = _trafficItineraries.indexWhere((element) => element.itineraryId == _dragAndDropData.dataId);
                       // 1 : 交通
                         dragTargetBuilder = Column(
                           children: [
                             Container(
                               margin: EdgeInsets.only(left: 15.0, top: 10.0),
                               child: _buildPlanPart(
                                 _itineraries[i].itineraryID,
                                 _itineraries[i].itineraryOrder
                               ),
                             ),
                             Container(
                               margin: EdgeInsets.only(left: 15.0, top: 10.0),
                               child: _dragAndDropData.alreadyFlag?
                                 TrafficPart(
                                   id: _trafficItineraries[itiId].id,
                                   trafficType: _trafficItineraries[itiId].trafficClass,
                                   minutes: "",
                                   confirmFlag: false,
                                   flg: false,
                                 ):
                                 TrafficPart(
                                   id: 1,
                                   trafficType: _dragAndDropData.dataId,
                                   minutes: "",
                                   confirmFlag: false,
                                   flg: false,
                                 ),
                             ),
                           ],
                         );
                         break;
                       case 2:
                       // 2 : コメント
                         dragTargetBuilder = Column(
                           children: [
                             Container(
                               margin: EdgeInsets.only(left: 15.0, top: 10.0),
                               child: _buildPlanPart(
                                   _itineraries[i].itineraryID,
                                   _itineraries[i].itineraryOrder
                               ),
                             ),
                             Container(
                                 margin: EdgeInsets.only(left: 15.0, top: 10.0),
                                 child: MemoPart(
                                   memoString: _dragAndDropData.alreadyFlag ? _dragAndDropData.memo : "　　　　　",
                                   confirmFlag: false,
                                 )
                             ),
                           ],
                         );
                     }
                   }
                   return dragTargetBuilder;
                 }
             ),
          DragTarget <DragAndDropData>(
            onAccept: (receivedItem){
              setState(() {
                _itineraries[testId].accepting = false;
                switch(_dragAndDropData.dataType){
                  case 0:
                    _addSpotToPlan(testId);
                    break;
                  case 1:
                    _addTrafficToPlan(_dragAndDropData.dataId, testId);
                    break;
                  case 2:
                    _addMemoToPlan(testId);
                }
                _underFlag = false;
              });
            },
            onWillAccept: (receivedItem){
              setState(() {
                _dragAndDropData = receivedItem;
                //_itineraries[i].accepting = true;
                _underFlag = true;
              });
              return true;
            },
            onLeave: (receivedItem){
              setState(() {
                _dragAndDropData = null;
                _underFlag = false;
              });
            },
            builder: (context, acceptedItem, rejectedItem){
              Widget planListWidget;
              if(_dragAndDropData != null && _dragAndDropData.alreadyFlag == false && _underFlag){
                switch(_dragAndDropData.dataType){
                  case 0:
                    planListWidget = Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 15.0, top: 10.0),
                          child: PlanPart(
                            id:1,
                            number: _itineraries[testId].spotOrder + 1,
                            spotName: _spots[_dragAndDropData.dataId].spotName,
                            spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                            spotStartDateTime: null,
                            spotEndDateTime: null,
                            spotParentFlag: 0,
                            confirmFlag: false,
                            width: MediaQuery.of(context).size.width,
                            flg: true,
                            day: _travelDateTime[_tabController.index],
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints.expand(height: 300.0),
                        )
                      ],
                    );
                    break;
                  case 1:
                    planListWidget = Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 15.0, top: 10.0),
                          child: TrafficPart(
                            id: 1,
                            trafficType: _dragAndDropData.dataId,
                            minutes: "0",
                            confirmFlag: false,
                            flg: true,
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints.expand(height: 300.0),
                        )
                      ],
                    );

                }

              }else{
                planListWidget = Container(
                  constraints: BoxConstraints.expand(height: 300.0),
                );
              }
              return planListWidget;
            },
          ),
        ],
      ),
    );
  }

  //行程のパーツを返すWidget
  Widget _buildPlanPart(int id, int order){
    Widget planPart = Container();
    Widget part = Container();
    Widget part2 = Container();

    int itinerariesType = -1;  //0:スポット　1:メモ　2:交通
    int index = -1;

    //スポット・メモ・交通から、行程IDと一致するものを探す
    for(int i=0; i<_spotItineraries.length; i++){
      if(_spotItineraries[i].itineraryId == id){
        itinerariesType = 0;
        index = i;
        break;
      }
    }
    if(itinerariesType == -1){
      for(int i=0; i<_trafficItineraries.length; i++){
        if(_trafficItineraries[i].itineraryId == id){
          itinerariesType = 1;
          index = i;
          break;
        }
      }
    }
    if(itinerariesType == -1){
      for(int i=0; i<_memoItineraries.length; i++){
        if(_memoItineraries[i].itineraryId == id){
          itinerariesType = 2;
          index = i;
          break;
        }
      }
    }

    switch (itinerariesType){
      case 0 :
       part = GestureDetector(
         onTap: (){
           mapController.animateCamera(CameraUpdate.newLatLng(LatLng(_spotItineraries[index].latitude,_spotItineraries[index].longitude)));
         },
         child: PlanPart(
            id: _spotItineraries[index].id,
            number: order,
            spotName: _spotItineraries[index].spotName,
            spotPath: _spotItineraries[index].spotImagePath,
            spotStartDateTime: _spotItineraries[index].spotStartDateTime,
            spotEndDateTime: _spotItineraries[index].spotEndDateTime,
            spotParentFlag: _spotItineraries[index].parentFlag,
            confirmFlag: true,
            width: MediaQuery.of(context).size.width,
            flg: true,
            day: _travelDateTime[_tabController.index],
          ),
       );
       part2 = PlanPart(
         id: _spotItineraries[index].id,
         number: order,
         spotName: _spotItineraries[index].spotName,
         spotPath: _spotItineraries[index].spotImagePath,
         spotStartDateTime: _spotItineraries[index].spotStartDateTime,
         spotEndDateTime: _spotItineraries[index].spotEndDateTime,
         spotParentFlag: _spotItineraries[index].parentFlag,
         confirmFlag: true,
         width: MediaQuery.of(context).size.width,
         flg: false,
         day: _travelDateTime[_tabController.index],
       );

       break;
      case 1 :
        part = TrafficPart(
          id: _trafficItineraries[index].id,
          trafficType: _trafficItineraries[index].trafficClass,
          minutes: _trafficItineraries[index].travelTime.toString(),
          confirmFlag: true,
          flg: true,
        );
        break;
      case 2 :
        part = MemoPart(
          memoString: _memoItineraries[index].memo,
          confirmFlag: true,
        );
        part2 = Container(
          width: MediaQuery.of(context).size.width,
          child: MemoPart(
            memoString: _memoItineraries[index].memo,
            confirmFlag: true,
          ),
        );
    }

    planPart = LongPressDraggable(
      child: part,
      feedback: itinerariesType == 1 ? part : part2,
      childWhenDragging: Container(),
      axis: Axis.vertical,
      data: itinerariesType == 2 ?
          _memoItineraries.length == 0 ?
            DragAndDropData(itinerariesType, id, 0, "      ", true):
            DragAndDropData(itinerariesType, id, 0, _memoItineraries[index].memo, true):
          itinerariesType == 1 ?
              _trafficItineraries.length == 0 ?
                DragAndDropData(itinerariesType, id, 0, null, true):
                DragAndDropData(itinerariesType, id, _trafficItineraries[index].itineraryId, null, true):
              _spotItineraries.length == 0?
                DragAndDropData(itinerariesType, id, 0, null, true):
                DragAndDropData(itinerariesType, id, _spotItineraries[index].itineraryId, null, true),
      onDragStarted: (){
        setState(() {
          _dragFlag = true;
        });
      },
      onDragCompleted: (){
        setState(() {
          _dragFlag = false;
        });
      },
      onDraggableCanceled: (a,b){
        setState(() {
          _dragFlag = false;
        });
      },
    );

    return planPart;
  }

  //スポットが入っているパレットのタブの部分
  Widget _buildMenuItem(IconData icon, String text){
    return Container(
      padding: EdgeInsets.only(top: 8.0),
      height: 35.0,
      width: MediaQuery.of(context).size.width / 3,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft:  const  Radius.circular(20.0),
          topRight: const  Radius.circular(20.0),
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
            children: [
              WidgetSpan(
                child: Icon(icon, color: Colors.white, size: 18.0,),
              ),
              TextSpan(
                text: " " + text,
                style: TextStyle(color: Colors.white, fontSize: 14.0),
              ),
            ]
        ),
      ),
    );
  }

  //パーツが入っているパレット
  Widget _buildMenuPalette(int number){
    Widget addPart = Container();

    switch(number){
      case 1:
        addPart = _buildSpotMenuPalette();
        break;
      case 2:
        addPart = _buildTrafficMenuPalette();
        break;
      case 3:
        addPart = _buildOtherMenuPalette();
        break;
    }

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: addPart,
      )
    );
  }

  //スポットのパーツを並べる
  Widget _buildSpotMenuPalette(){
    return  Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for(int i=0; i < _spots.length; i++)
          Padding(
            padding: EdgeInsets.only(left: 15.0, bottom: 20.0),
            child: Draggable(
              child: SpotPart(
                spotName: _spots[i].spotName,
                spotPath: _spots[i].spotImagePath,
              ),
              feedback: SpotPart(
                spotName: _spots[i].spotName,
                spotPath: _spots[i].spotImagePath,
               ),
              childWhenDragging: Container(),
              data: DragAndDropData(0,null, i, null, false),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: 15.0, bottom: 20.0),
          child: GestureDetector(
            child:  SizedBox(
              height: 100.0,
              width: 100.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  color: Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 40.0,),
                        Text("スポット追加", style: TextStyle(color: Colors.white),)
                      ],
                    )
                ),
              ),
            ),
            onTap: () async {
              var result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddSpotPage(),
                  )
              );
              //print("a" + result[0].spotName);
              if(result != null){
                List<Map<String, int>> data = [];
                for(int i=0; i<result.length; i++){
                  if(_spots.indexWhere((element) => element.spotId == result[i].spotId) == -1){
                    print(i.toString() + ":" + result[i].spotName);
                    Map<String,int> planSpot = {
                      "plan_id" : widget.planId,
                      "spot_id" : result[i].spotId,
                    };
                    data.add(planSpot);
                    _spots.add(SpotData(result[i].spotId, result[i].spotName, result[i].lat, result[i].lng, result[i].imageUrl,result[i].placeId, 0));
                  }
                }

                http.Response res = await Network().postData(data, "planspot/store");
                print("a" + res.body.toString());

              }
            },
          ),
        ),
      ],
    );
  }

  //交通のパーツ並べる
  Widget _buildTrafficMenuPalette(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for(int i=0; i < _trafficPartData.length-1; i++)
          Padding(
            padding: EdgeInsets.all(5.0),
            child: Draggable(
              child: TrafficEditPart(
                icon: _trafficPartData[i].icon,
                trafficType: _trafficPartData[i].trafficType,
              ),
              feedback: TrafficEditPart(
                icon: _trafficPartData[i].icon,
                trafficType: _trafficPartData[i].trafficType,
              ),
              childWhenDragging: Container(),
              data: DragAndDropData(1,null, i+1, null, false),
              // onDragStarted: (){
              //   setState(() {
              //     _dragFlag = true;
              //   });
              // },
              // onDragCompleted: (){
              //   setState(() {
              //     _dragFlag = false;
              //   });
              // },
              // onDraggableCanceled: (a,b){
              //   setState(() {
              //     _dragFlag = false;
              //   });
              // },
            ),
          ),
      ],
    );
  }

  //その他のパーツ並べる
  Widget _buildOtherMenuPalette(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
        ),
        Draggable(
          child: Bubble(
            nip: BubbleNip.leftTop,
            color: Theme.of(context).primaryColor,
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(Icons.edit, color: Colors.white, size: 18.0,),
                  ),
                  TextSpan(
                     text: "　メモ　",
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 14.0,
                       decoration: TextDecoration.none,
                       fontWeight: FontWeight.normal
                     ),
                   ),
                 ]
               ),
            )
          ),
          feedback: Bubble(
              nip: BubbleNip.leftTop,
              color: Theme.of(context).primaryColor,
              child: RichText(
                text: TextSpan(
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.edit, color: Colors.white, size: 18.0,),
                      ),
                      TextSpan(
                        text: "　メモ　",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ]
                ),
              )
          ),
          childWhenDragging: Container(),
          data: DragAndDropData(2,null, 0, '', false),
          // onDragStarted: (){
          //   setState(() {
          //     _dragFlag = true;
          //   });
          // },
          // onDragCompleted: (){
          //   setState(() {
          //     _dragFlag = false;
          //   });
          // },
          // onDraggableCanceled: (a,b){
          //   setState(() {
          //     _dragFlag = false;
          //   });
          // },
        )
      ],
    );
  }

  //削除するパレット
  Widget _buildDeletePalette(){
    return DragTarget <DragAndDropData>(
      onAccept: (receivedItem){
        _deletePartPlan(_dragAndDropData.iniId);
        _dragAndDropData = null;
      },
      onWillAccept: (receivedItem){
        setState(() {
          _dragAndDropData = receivedItem;
        });
        return true;
      },
      onLeave: (receivedItem){
        setState(() {
          _dragAndDropData = null;
        });
      },
      builder: (context, acceptedItem, rejectedItems){
        return Container(
          padding: EdgeInsets.only(top: 10.0),
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.delete, size: 80.0, color: Colors.white,),
                Text("ここにドロップで削除", style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),)
              ],
            ),
          ),
        );
      },
    );
  }

}