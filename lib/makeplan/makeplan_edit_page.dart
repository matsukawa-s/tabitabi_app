import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bubble/bubble.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';

import 'package:tabitabi_app/data/itinerary_part_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_spot_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_plan_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_memo_part.dart';
import 'package:tabitabi_app/data/spot_data.dart';
import 'package:tabitabi_app/data/itinerary_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_traffic_part.dart';
import 'package:tabitabi_app/makeplan/makeplan_add_spot_page.dart';
import 'package:tabitabi_app/model/spot_model.dart';

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

  //ItineraryDataのIDあとでDBからとってくるようにする。
  int _id = 1;

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

    //_trafficItineraries.add(TrafficItineraryData(4, 1, 60, 400));

    _travelDateTime = _getDateTimeList(widget.startDateTime, widget.endDateTime);

    _tabController = TabController(length: _travelDateTime.length, vsync: this);
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
      _itineraries.add(ItineraryData(list[i]["id"], list[i]["itinerary_order"], list[i]["plan_id"], date, false));
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
    for(int i=0; i<list2.length; i++){
      _spotItineraries.add(SpotItineraryData(list2[i]["itinerary_id"], list2[i]["spot_id"], list2[i]["spot_name"], list2[i]["latitube"], list2[i]["longitube"], list2[i]["image_url"], null , null, 0));
     // print(_spotItineraries[i].spotName);
    }

    http.Response responseTraffic = await Network().postData(data, "itinerary/get/traffic");
    List list3 = json.decode(responseTraffic.body);
    for(int i=0; i<list3.length; i++){
      _trafficItineraries.add(TrafficItineraryData(list3[i]["itinerary_id"], list3[i]["traffic_class"], list3[i]["travel_time"], list3[i]["traffic_cost"]));
    }

    http.Response responseMemo = await Network().postData(data, "itinerary/get/note");
    List list4 = json.decode(responseMemo.body);
    for(int i=0; i<list4.length; i++){
      _memoItineraries.add(MemoItineraryData(list4[i]['itinerary_id'], list4[i]['memo']));
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
          SpotData(list[i]["spot_id"], list[i]["spot_name"], list[i]["latitude"], list[i]["longitude"], list[i]["image_url"], list[i]["place_id"], 1)
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
    print(response.body);

    setState(() {
      _travelDateTime.add(_endDateTime);
      _tabController = _createNewTabController();
    });

    _tabController.animateTo(_tabController.length-1);


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

      print("temp:" + tempItineraryData.itineraryID.toString() + "," + tempItineraryData.itineraryOrder.toString());
      print("go:" + _itineraries[index].itineraryID.toString() + "," + _itineraries[index].itineraryOrder.toString());

      //移動予定のorder
      int goOrder = _itineraries[index].itineraryOrder;
      if(tempItineraryData.itineraryOrder > goOrder){
        goOrder++;
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
            }
          }else {
            //上から下
            //print("i:" + "id:" +  _itineraries[i].itineraryID.toString() + " order:" + _itineraries[i].itineraryOrder.toString());
            if(_itineraries[i].itineraryOrder <= goOrder && _itineraries[i].itineraryOrder > tempItineraryData.itineraryOrder){
              print("test4");
              _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
            }
          }
        }
      }

      http.Response res = await Network().getData("itinerary/rearrange/" + _dragAndDropData.dataId.toString() + "/" + goOrder.toString() + "/" + _dragAndDropData.dataType.toString());

      print(res.body);
      setState(() {
        //行程リストに追加
        _itineraries[iniIndex].itineraryOrder = goOrder;
       // _spotItineraries.add(SpotItineraryData(len, _spots[_dragAndDropData.dataId].spotId, _spots[_dragAndDropData.dataId].spotName, _spots[_dragAndDropData.dataId].spotImagePath, null, null, 0));
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

    }else{
      print("追加します！");

      //追加
      //index以下のitineraryOrderの値を1ふやす
      for(int i=index+1; i < _itineraries.length; i++){
        if(_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
          ItineraryData tempItineraryData = _itineraries[i];
          _itineraries.removeAt(i);
          _itineraries.insert(i, ItineraryData(tempItineraryData.itineraryID, tempItineraryData.itineraryOrder+1, 1, tempItineraryData.itineraryDateTime, tempItineraryData.accepting));
        }
      }
      int len = _id;
      String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);

      int order = 0;
      setState(() {
        print(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])).toString());
        if(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) == -1){
          if(_itineraries.length == 0){
            _itineraries.insert(0, ItineraryData(len, 1, 1, _travelDateTime[_tabController.index], false));
          }else{
            _itineraries.insert(index + 1, ItineraryData(len, 1, 1, _travelDateTime[_tabController.index], false));
          }
          order = 1;
        }else{
          _itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder + 1, 1, _travelDateTime[_tabController.index], false));
          order = _itineraries[index].itineraryOrder+1;
        }
        //行程リストに追加
        //_itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder + 1, 1, _travelDateTime[_tabController.index], false));
        //行程スポットリストに追加
        _spotItineraries.add(SpotItineraryData(len, _spots[_dragAndDropData.dataId].spotId, _spots[_dragAndDropData.dataId].spotName,_spots[_dragAndDropData.dataId].latitude, _spots[_dragAndDropData.dataId].longitude, _spots[_dragAndDropData.dataId].spotImagePath, null, null, 0));

      });

      print("test : " + day + " , " + order.toString());
      final data = {
        "order" : order,
        "day" : day,
        "plan_id" : widget.planId,
        "spot_id" : _spots[_dragAndDropData.dataId].spotId,
        "type" : 0
      };

      http.Response res = await Network().postData(data, "itinerary/store");
      //print(jsonEncode(data));
      //print("aa" + res.body.toString());

      _id++;

      _dragAndDropData = null;
    }
  }

  //交通パレットからプランに追加したときの処理
  _addTrafficToPlan(int trafficType, int index) async{
    //時間の計算
    int trafficTime = 40;
    int cost = 400;

    int iniIndex = _itineraries.indexWhere((element) => element.itineraryID == _dragAndDropData.dataId);

    if(_dragAndDropData.alreadyFlag){
      int goOrder = _itineraries[index].itineraryOrder;
      print("あああgoOrder:" + goOrder.toString() + " dataId:" + _dragAndDropData.dataId.toString());
      //並び替え時
      setState(() {
        _itineraries[iniIndex].itineraryOrder = goOrder;
        _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
      });

      http.Response res = await Network().getData("itinerary/rearrange/" + _dragAndDropData.dataId.toString() + "/" + goOrder.toString() + "/" + _dragAndDropData.dataType.toString());
    }else{
      //追加時
      int len = _id;
      print('traffic_len:' + len.toString());
      print('trafficID' + len.toString() + ' trafficType' + _dragAndDropData.dataId.toString());

      setState(() {
        //行程リストに追加
        _itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder, 1,  _travelDateTime[_tabController.index], false));
        //行程交通リストに追加
        _trafficItineraries.add(TrafficItineraryData(len, trafficType, trafficTime, cost));
      });
      _id++;

      String day = DateFormat('yyyy-MM-dd').format(_travelDateTime[_tabController.index]);

      print("test : " + day + " , " + _itineraries[index].itineraryOrder.toString());
      final data = {
        "order" : _itineraries[index].itineraryOrder,
        "day" : day,
        "plan_id" : widget.planId,
        "type" : 1,
        "traffic_class" : _dragAndDropData.dataId,
        "travel_time" : trafficTime,
        "traffic_cost" : 0,
      };

      http.Response res = await Network().postData(data, "itinerary/store");
      print(res.body);

      _dragAndDropData = null;
    }
  }

  //削除
  _deletePartPlan(int iniId) async{
    if(_dragAndDropData.alreadyFlag){
      if(_dragAndDropData.dataType == 0){
        //スポットのとき
        int index = _itineraries.indexWhere((element) => element.itineraryID == iniId);
        _itineraries.removeAt(index);
        _spotItineraries.removeAt(_spotItineraries.indexWhere((element) => element.itineraryId == iniId));
        //順番の変更
        for(int i=index; i<_itineraries.length; i++){
          if(_dataTimeFunc(_itineraries[i].itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])){
            _itineraries[i].itineraryOrder = _itineraries[i].itineraryOrder - 1;
          }
        }

      }else if(_dragAndDropData.dataType == 1){
        //交通のとき
        setState(() {
          print("iniID" + iniId.toString());
          _itineraries.removeAt(_itineraries.indexWhere((element) => element.itineraryID == iniId));
          _trafficItineraries.removeAt(_trafficItineraries.indexWhere((element) => element.itineraryId == iniId));
        });
      }else{
        //メモのとき
        setState(() {
          _itineraries.removeAt(_itineraries.indexWhere((element) => element.itineraryID == iniId));
          _memoItineraries.removeAt(_memoItineraries.indexWhere((element) => element.itineraryId == iniId));
        });
      }

      http.Response res = await Network().getData("itinerary/delete/" + iniId.toString() + "/" + _dragAndDropData.dataType.toString());
      print(res.body);

      _dragAndDropData = null;
    }
  }
  
  DateTime _dataTimeFunc(DateTime date){
    return DateTime(date.year, date.month, date.day);
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
                  mapType: MapType.terrain,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(35.6580339,139.7016358),
                    zoom: 17.0,
                  ),
                  scrollGesturesEnabled: true,
                ),
              ),
              //日程一覧タブ表示
              Row(
                children: [
                  Container(
                    height: 50.0,
                    width: MediaQuery.of(context).size.width - MediaQuery.of(context).size.width/6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 4), // changes position of shadow
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
                            number: 1,
                            spotName: _spots[_dragAndDropData.dataId].spotName,
                            spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                            spotStartDateTime: null,
                            spotEndDateTime: null,
                            spotParentFlag: 0,
                            confirmFlag: false,
                            width: MediaQuery.of(context).size.width,
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
                         _itineraries[i].itineraryOrder
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
                                   _itineraries[i].itineraryOrder
                               ),
                             ),
                             //追加時
                             if(_dragAndDropData.alreadyFlag == false)
                               Container(
                                 margin: EdgeInsets.only(left: 15.0, top: 10.0),
                                 child: PlanPart(
                                   number: _itineraries[i].itineraryOrder + 1,
                                   spotName: _spots[_dragAndDropData.dataId].spotName,
                                   spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                                   spotStartDateTime: null,
                                   spotEndDateTime: null,
                                   spotParentFlag: 0,
                                   confirmFlag: false,
                                   width: MediaQuery.of(context).size.width,
                                 ),
                               ),
                             //並び替え時
                             if(_dragAndDropData.alreadyFlag == true)
                               Container(
                                 margin: EdgeInsets.only(left: 15.0, top: 10.0),
                                 child: PlanPart(
                                   number: _itineraries[i].itineraryOrder + 1,
                                   spotName: _spotItineraries[itiId].spotName,
                                   spotPath: _spotItineraries[itiId].spotImagePath,
                                   spotStartDateTime: _spotItineraries[itiId].spotStartDateTime,
                                   spotEndDateTime: _spotItineraries[itiId].spotEndDateTime,
                                   spotParentFlag: 0,
                                   confirmFlag: false,
                                   width: MediaQuery.of(context).size.width,
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
                                   trafficType: _trafficItineraries[itiId].trafficClass,
                                   minutes: 0,
                                   confirmFlag: false,
                                 ):
                                 TrafficPart(
                                   trafficType: _dragAndDropData.dataId,
                                   minutes: 0,
                                   confirmFlag: false,
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
                                   memoString: "　　　　　　　",
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
                            number: _itineraries[testId].itineraryOrder + 1,
                            spotName: _spots[_dragAndDropData.dataId].spotName,
                            spotPath: _spots[_dragAndDropData.dataId].spotImagePath,
                            spotStartDateTime: null,
                            spotEndDateTime: null,
                            spotParentFlag: 0,
                            confirmFlag: false,
                            width: MediaQuery.of(context).size.width,
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
                            trafficType: _dragAndDropData.dataId,
                            minutes: 0,
                            confirmFlag: false,
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
       part = PlanPart(
          number: order,
          spotName: _spotItineraries[index].spotName,
          spotPath: _spotItineraries[index].spotImagePath,
          spotStartDateTime: _spotItineraries[index].spotStartDateTime,
          spotEndDateTime: _spotItineraries[index].spotEndDateTime,
          spotParentFlag: _spotItineraries[index].parentFlag,
          confirmFlag: true,
          width: MediaQuery.of(context).size.width,
        );
       break;
      case 1 :
        part = TrafficPart(
          trafficType: _trafficItineraries[index].trafficClass,
          minutes: _trafficItineraries[index].travelTime,
          confirmFlag: true,
        );
        break;
      case 2 :
        part = MemoPart(
          memoString: _memoItineraries[index].memo,
          confirmFlag: true,
        );
    }

    planPart = LongPressDraggable(
      child: part,
      feedback: part,
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
        Padding(
          padding: EdgeInsets.only(left: 15.0, bottom: 20.0),
          child: GestureDetector(
            child:  SizedBox(
              height: 90.0,
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
              print("a" + result[0].spotName);
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
                    _spots.add(SpotData(result[i].spotId, result[i].spotName, 0, 0, result[i].imageUrl, result[i].placeId, 0));
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