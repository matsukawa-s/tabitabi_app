
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tabitabi_app/network_utils/api.dart';
import 'makeplan_edit_page.dart';

class MakePlanTop extends StatefulWidget {

  final int planId;

  MakePlanTop({
    Key key,
    this.planId,
  }):super(key: key);

  @override
  _MakePlanTopState createState() => _MakePlanTopState();
}

class _MakePlanTopState extends State<MakePlanTop> {

  String _planName = "";
  String _planDetail = "";
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now();
  List<DateTime> _planDates = [];

  @override
  void initState() {
    super.initState();
    _getPlan();
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
    return _planDates.length;

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
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 400),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: DefaultTabController(
                                    length: _planDates.length,
                                    child: Builder(
                                      builder: (BuildContext context){
                                        final TabController controller = DefaultTabController.of(context);
                                        return  Stack(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(top: 10.0),
                                              height: 400,
                                              width: 500,
                                              child: TabBarView(
                                                children: [
                                                  for(int i=0; i<_planDates.length; i++)
                                                    _buildSchedule("1", _planDates[i]),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                                bottom: 0.0,
                                                left: 0.0,
                                                right: 0.0,
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: TabPageSelector(),
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
                                                  if(!(controller.index == 0)){
                                                    controller.animateTo(controller.index - 1);
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
                                                  if(!(controller.index == _planDates.length)){
                                                    controller.animateTo(controller.index + 1);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ),
                                  // child: FutureBuilder(
                                  //   future: _getPlan(),
                                  //   builder: (BuildContext context, AsyncSnapshot<int> snapshot){
                                  //     print(snapshot.hasError);
                                  //     print(snapshot.error.toString());
                                  //
                                  //     if (snapshot.connectionState != ConnectionState.done) {
                                  //       return Center(
                                  //         child: CircularProgressIndicator(),
                                  //       );
                                  //     }
                                  //
                                  //     if (snapshot.hasError) {
                                  //       return Text(snapshot.error.toString());
                                  //     }
                                  //
                                  //     if(snapshot.hasData){
                                  //       int length = snapshot.data;
                                  //       if(_planDates.length == 0){
                                  //         return Container();
                                  //       }
                                  //
                                  //       return DefaultTabController(
                                  //         length: _planDates.length,
                                  //         child: Builder(
                                  //           builder: (BuildContext context) => Stack(
                                  //             children: [
                                  //               Positioned(
                                  //                 top: 0.0,
                                  //                 left: 0.0,
                                  //                 height: 50.0,
                                  //                 width: 320,
                                  //                 child: Center(
                                  //                   child: _buildTitle("10/23"),
                                  //                 ),
                                  //               ),
                                  //               Container(
                                  //                 margin: EdgeInsets.only(top: 50.0),
                                  //                 height: 400,
                                  //                 width: 500,
                                  //                 child: TabBarView(
                                  //                   children: [
                                  //                     for(int i=0; i<_planDates.length; i++)
                                  //                       _buildSchedule("1"),
                                  //                   ],
                                  //                 ),
                                  //               ),
                                  //               Positioned(
                                  //                   bottom: 0.0,
                                  //                   left: 0.0,
                                  //                   right: 0.0,
                                  //                   child: Align(
                                  //                     alignment: Alignment.center,
                                  //                     child: TabPageSelector(),
                                  //                   )
                                  //               ),
                                  //               Positioned(
                                  //                 top: 0.0,
                                  //                 bottom: 0.0,
                                  //                 left: -30.0,
                                  //                 child: IconButton(
                                  //                   icon: Icon(Icons.chevron_left),
                                  //                   iconSize: 80.0,
                                  //                   color: Colors.orange,
                                  //                   onPressed: (){
                                  //                     final TabController controller = DefaultTabController.of(context);
                                  //                     if(!(controller.index == 0)){
                                  //                       controller.animateTo(controller.index - 1);
                                  //                     }
                                  //                   },
                                  //                 ),
                                  //               ),
                                  //               Positioned(
                                  //                 top: 0.0,
                                  //                 bottom: 0.0,
                                  //                 right: -30,
                                  //                 child: IconButton(
                                  //                   icon: Icon(Icons.chevron_right),
                                  //                   iconSize: 80.0,
                                  //                   color: Colors.orange,
                                  //                   onPressed: (){
                                  //                     final TabController controller = DefaultTabController.of(context);
                                  //                     if(!(controller.index == _planDates.length)){
                                  //                       controller.animateTo(controller.index + 1);
                                  //                     }
                                  //                   },
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       );
                                  //     }else{
                                  //       return Center(
                                  //         child: Container(child: Text("sa"),),
                                  //       );
                                  //     }
                                  //   },
                                  // ),
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
                                        });
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ),
                    //メンバー
                    Card(
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0),
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
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0, bottom: 30.0),
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
      color: Colors.greenAccent,
      child: Column(
        children: [
          Container(
            child: Text(date.month.toString() + "/" + date.day.toString(), style: TextStyle(fontSize: 18.0),),
          )
        ],
      ),
    );
  }
}

