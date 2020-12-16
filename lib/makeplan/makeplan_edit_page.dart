import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bubble/bubble.dart';

import 'package:tabitabi_app/data/itinerary_part_data.dart';

import 'package:tabitabi_app/components/makeplan_edit_spot_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_plan_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_memo_part.dart';
import 'package:tabitabi_app/data/spot_data.dart';
import 'package:tabitabi_app/data/itinerary_data.dart';
import 'package:tabitabi_app/data/itinerary_part_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_traffic_part.dart';
import 'package:tabitabi_app/makeplan/makeplan_add_spot_page.dart';

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
  @override
  _MakePlanEditState createState() => _MakePlanEditState();
}

class _MakePlanEditState extends State<MakePlanEdit> with TickerProviderStateMixin  {

  GoogleMapController mapController;
  TabController _tabController;
  TabController _menuTabController;

  //ItineraryDataのIDあとでDBからとってくるようにする。
  int _id = 1;

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
  DragAndDropData _dragAndDropData = null;

  //Dragしてるかどうかのフラグ
  bool _dragFlag = false;
  //下の部分のフラグ
  bool _underFlag = false;

  //旅行の日程　とりあえず仮
  List<DateTime> _travelDateTime = [];

  DateTime lastDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 6);

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

    _spots.add(SpotData(1, "ペンギン城", "images/osakajo.jpg", 1, 1));
    _spots.add(SpotData(2, "カバン", "images/illustrain02-travel04.png", 2, 1));
    _spots.add(SpotData(3, "世界", "images/osakajo.jpg", 3, 1));

    _itineraries.add(ItineraryData(1, 1, 1, DateTime.now(), false));
    _itineraries.add(ItineraryData(2, 1, 1, DateTime.now(), false));
    _itineraries.add(ItineraryData(3, 2, 1, DateTime.now(), false));
    _itineraries.add(ItineraryData(4, 2, 1, DateTime.now(), false));
    _itineraries.add(ItineraryData(5, 3, 1, DateTime.now(), false));

    _id = 6;

    _spotItineraries.add(SpotItineraryData(1, 1, "ペンギン城", "images/osakajo.jpg", null, null, 0));
    _spotItineraries.add(SpotItineraryData(3, 2, "カバン", "images/illustrain02-travel04.png", DateTime.now(), DateTime.now(), 0));
    _spotItineraries.add(SpotItineraryData(5, 3, "世界", "images/osakajo.jpg", DateTime.now(), DateTime.now(), 0));

    _memoItineraries.add(MemoItineraryData(2, "メモですメモです"));

    _trafficItineraries.add(TrafficItineraryData(4, 1, 60, 400));

    _travelDateTime.add(DateTime.now());
    _travelDateTime.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1));
    _travelDateTime.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2));
    _travelDateTime.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 3));
    _travelDateTime.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 4));
    _travelDateTime.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 5));


    _tabController = TabController(length: _travelDateTime.length, vsync: this);
    _menuTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _menuTabController.dispose();
    super.dispose();
  }

  //日付追加の処理
  _addDateTime(){
    setState(() {
      _travelDateTime.add(DateTime(lastDateTime.year, lastDateTime.month, lastDateTime.day));
      _tabController = _createNewTabController();
    });

    lastDateTime = DateTime(lastDateTime.year, lastDateTime.month, lastDateTime.day + 1);
    _tabController.animateTo(_tabController.length-1);

  }

  TabController _createNewTabController() => TabController(
    vsync: this,
    length: _travelDateTime.length,
  );

  //スポットパレットからプランに追加したときの処理
  _addSpotToPlan(int index){
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

      setState(() {
        print(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])).toString());
        if(_itineraries.indexWhere((element) => _dataTimeFunc(element.itineraryDateTime) == _dataTimeFunc(_travelDateTime[_tabController.index])) == -1){
          _itineraries.insert(index + 1, ItineraryData(len, 1, 1, _travelDateTime[_tabController.index], false));
        }else{
          _itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder + 1, 1, _travelDateTime[_tabController.index], false));
        }
        //行程リストに追加
        //_itineraries.insert(index + 1, ItineraryData(len, _itineraries[index].itineraryOrder + 1, 1, _travelDateTime[_tabController.index], false));
        //行程スポットリストに追加
        _spotItineraries.add(SpotItineraryData(len, _spots[_dragAndDropData.dataId].spotId, _spots[_dragAndDropData.dataId].spotName, _spots[_dragAndDropData.dataId].spotImagePath, null, null, 0));
      });

      _id++;
    }
  }

  //交通パレットからプランに追加したときの処理
  _addTrafficToPlan(int trafficType, int index){
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
    }
  }

  //削除
  _deletePartPlan(int iniId){
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
                  _dragAndDropData = null;
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
                   _dragAndDropData = null;
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
                _dragAndDropData = null;
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
    Widget planPart;
    Widget part;

    int itinerariesType = -1;  //0:スポット　1:メモ　2:交通
    int index = -1;

    int spotId = 0;

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
        DragAndDropData(itinerariesType, id, 0, _memoItineraries[index].memo, true):
          itinerariesType == 1 ?
          DragAndDropData(itinerariesType, id, _trafficItineraries[index].itineraryId, null, true):
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
              print(result);
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
          padding: EdgeInsets.only(top: 30.0),
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