import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tabitabi_app/network_utils/api.dart';
import 'makeplan_edit_page.dart';
import 'package:tabitabi_app/data/itinerary_data.dart';
import 'package:tabitabi_app/data/itinerary_part_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_traffic_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_plan_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_memo_part.dart';

class MakePlanTop extends StatefulWidget {

  final int planId;

  MakePlanTop({
    Key key,
    this.planId,
  }):super(key: key);

  @override
  _MakePlanTopState createState() => _MakePlanTopState();
}

class _MakePlanTopState extends State<MakePlanTop> with TickerProviderStateMixin{

  String _planName = "";
  String _planDetail = "";
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now();
  List<DateTime> _planDates = [DateTime.now()];

  TabController _controller;

  //行程のリスト
  List<ItineraryData> _itineraries = [];
  //行程スポットのリスト
  List<SpotItineraryData> _spotItineraries = [];
  //行程メモのリスト
  List<MemoItineraryData> _memoItineraries = [];
  //行程交通機関のリスト
  List<TrafficItineraryData> _trafficItineraries = [];

  @override
  void initState() {
    super.initState();
    _getPlan();
    _getItiData();

    _controller = TabController(length: 1, vsync: this);
  }

  Future<int> _getPlan() async{
    http.Response response = await Network().getData("plan/get/" + widget.planId.toString());
    List list = json.decode(response.body);
    print(list[0].toString());

    setState(() {
      _planName = list[0]["title"];
      _planDetail = list[0]["description"] == null ? "" : list[0]["description"];
    });
    _startDateTime = DateTime.parse(list[0]["start_day"]);
    _endDateTime = DateTime.parse(list[0]["end_day"]);

    setState(() {
      _planDates = _getDateTimeList(_dateTimeFunc(_startDateTime), _dateTimeFunc(_endDateTime));
    });

    print(_planDates.length);

    setState(() {
      _controller = _createNewTabController();
    });
    return _planDates.length;

  }

  TabController _createNewTabController() => TabController(
    vsync: this,
    length: _planDates.length,
  );

  void _getItiData() async{
    _itineraries.clear();
    _spotItineraries.clear();
    _trafficItineraries.clear();
    _memoItineraries.clear();
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

  DateTime _dateTimeFunc(DateTime date){
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('トップ'),
      // ),
      resizeToAvoidBottomInset : false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("images/paper_00108.jpg"),
              //colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.3), BlendMode.color),
              fit: BoxFit.cover
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200.0,
              actions: [
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white,),
                  onPressed: (){},
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white,),
                  onPressed: (){},
                ),
              ],
              flexibleSpace: Container(
                constraints: BoxConstraints.expand(height: 250.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("images/2304099_m.jpg"),
                    //image: NetworkImage("https://picsum.photos/1500/800"),
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Text(_planName, style: TextStyle(color: Colors.white, fontSize: 32.0)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5.0, bottom: 10.0),
                      child: Text(_planDetail, style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              bottom: PreferredSize(child: Text("", style: TextStyle(color: Colors.white)), preferredSize: Size.fromHeight(53.0),),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //スケジュール
                    Card(
                      margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 500),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 10.0),
                                        height: 400,
                                        width: 500,
                                        child: TabBarView(
                                          controller: _controller,
                                          children: [
                                            for(int i=0; i<_planDates.length; i++)
                                              SingleChildScrollView(
                                                child: _buildSchedule("1", _planDates[i]),
                                              )
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 0.0,
                                          left: 0.0,
                                          right: 0.0,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: TabPageSelector(
                                              controller: _controller,
                                            ),
                                          )
                                      ),
                                      Positioned(
                                        top: 0.0,
                                        bottom: 0.0,
                                        left: -30.0,
                                        child: IconButton(
                                          icon: Icon(Icons.chevron_left),
                                          iconSize: 80.0,
                                          color: Colors.orange,
                                          onPressed: (){
                                            if(!(_controller.index == 0)){
                                              _controller.animateTo(_controller.index - 1);
                                            }
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 0.0,
                                        bottom: 0.0,
                                        right: -30,
                                        child: IconButton(
                                          icon: Icon(Icons.chevron_right),
                                          iconSize: 80.0,
                                          color: Colors.orange,
                                          onPressed: (){
                                            if(!(_controller.index == _planDates.length)){
                                              _controller.animateTo(_controller.index + 1);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                  child: FloatingActionButton(
                                    heroTag: 'planEdit',
                                    backgroundColor: Colors.orange,
                                    child: Icon(Icons.edit, color: Colors.white,),
                                    onPressed: (){
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => MakePlanEdit(planId: widget.planId, startDateTime: _dateTimeFunc(_startDateTime), endDateTime: _dateTimeFunc(_endDateTime),),
                                          )
                                      ).then((value){
                                        setState(() {
                                          _getPlan();
                                          _getItiData();
                                        });
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    //メンバー
                    Card(
                      margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTitle("メンバー"),
                            Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                child: FloatingActionButton(
                                  heroTag: 'memberAdd',
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.add, color: Colors.white,),
                                  onPressed: (){},
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //アルバム
                    Card(
                      margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0, bottom: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 350),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTitle("アルバム"),
                            Expanded(
                              child: Container(),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                child: FloatingActionButton(
                                  heroTag: 'albumAdd',  //これを指定しないと複数FloatingActionButtonが使えない
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.add, color: Colors.white,),
                                  onPressed: (){},
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  //各項目のタイトル
  Widget _buildTitle(String title){
    return Padding(
      padding: EdgeInsets.only(top: 15.0),
      child: Text(title , style: TextStyle(fontSize: 18.0)),
    );
  }

  //各日程のスケジュール
  Widget _buildSchedule(String test, DateTime date){
    return Container(
      margin: EdgeInsets.only(left: 16.0, top: 5.0, right: 16.0),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(date.month.toString() + "/" + date.day.toString(), style: TextStyle(fontSize: 18.0),),
          ),
          for(int i=0; i<_itineraries.length; i++)
            if(_itineraries[i].itineraryDateTime == date)
            Container(
              margin: EdgeInsets.only(top: 14.0, left: 10.0),
              child: _buildPlanPart(_itineraries[i].itineraryID, _itineraries[i].itineraryOrder),
            ),
          if(_itineraries.length == 0 || _itineraries.indexWhere((element) => element.itineraryDateTime == date) == -1)
            Container(
              margin: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 20.0),
              color: Colors.black.withOpacity(0.2),
              width: MediaQuery.of(context).size.width,
              height: 350,
              child: Center(
                child: Text("まだ予定はありません！"),
              ),
            )
        ],
      ),
    );
  }

  //行程のパーツを返すWidget
  Widget _buildPlanPart(int id, int order){
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
          width: MediaQuery.of(context).size.width - 60,
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
    return part;
  }
}

