import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:tabitabi_app/join_plan_page.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tabitabi_app/spot_details_page.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class TopPage extends StatelessWidget {
  final String title;
  final pagePadding = 6.0;

  TopPage({@required this.title});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double popularPlanItemHeight = (size.width - pagePadding*2) / 2 * 2/3;
    final double popularPlanItemWidth = (size.width - pagePadding*2) / 2;
    final double popularSpotItemSize = (size.width - pagePadding*2) / 3;

    return FutureBuilder(
      future: getInitialTopData(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          final List<dynamic> todayPlans = snapshot.data["today_plans"]; //今日のプラン
          final List<dynamic> popularPlans = snapshot.data["popular_plans"]; //人気のプラン
          final List<dynamic> popularSpots = snapshot.data["popular_spots"]; //人気のスポット
          final List<dynamic> planHistory = snapshot.data["plan_history"]; //最近見たプラン

          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: RaisedButton(
                          child: Text("プランに参加する"),
                          color: Colors.orangeAccent,
                          shape: const StadiumBorder(),
                          onPressed: (){
                            Navigator.push(
                              context,
                              PageTransition(
                                  type: PageTransitionType.fade,
                                  child: JoinPlanPage(),
                                  inheritTheme: true,
                                  ctx: context
                              ),
                            );
                          }
                      ),
                    ),
                  ),
                  //今日のプランを表示する
                  todayPlans.isEmpty ? Container() :
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.all(4.0),
                        child: Text(
                          "今日のプラン",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: todayPlans.length,
                            itemBuilder: (BuildContext context, int index){
                              return Container(
//                                margin: EdgeInsets.all(4.0),
                                padding: EdgeInsets.all(2.0),
                                width: size.width - pagePadding*2,
                                child: Column(
                                  children: [
                                    Expanded(
                                        child: Container(
                                          child: Image.asset("images/osakajo.jpg",fit: BoxFit.fill,),
                                          width: size.width - pagePadding*2,
                                        )
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          todayPlans[index]["title"],
//                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(todayPlans[index]["start_day"] + ' ~ ' + todayPlans[index]["end_day"])
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }
                        ),
                      ),

                    ],
                  ),
                  //人気のプランを表示する
                  popularPlans.isEmpty ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.all(4.0),
                          child: Text(
                            "人気のプラン",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54
                            ),
                          ),
                        ),
//                        Divider(),
                        SizedBox(
                          height: popularPlanItemHeight,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: popularPlans.length,
                              itemBuilder: (BuildContext context, int index){
                                return Container(
//                                  color: Colors.black12,
                                  width: popularPlanItemWidth,
                                  margin: EdgeInsets.only(right: 6.0),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Container(
                                          width: popularPlanItemWidth,
                                          child: Image.asset("images/osakajo.jpg",fit: BoxFit.fill,),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                          child: Text(popularPlans[index]["title"])
                                      ),
                                    ],
                                  ),
                                );
                              }
                          ),
                        ),
                      ],
                    ),
                  popularSpots.isEmpty ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.all(4.0),
                          child: Text(
                            "人気のスポット",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54
                            ),
                          ),
                        ),
                        SizedBox(
                          height: popularSpotItemSize,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popularSpots.length,
                            itemBuilder: (BuildContext context,int index){
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SpotDetailsPage(
                                          spotId: popularSpots[index]["id"],
                                          placeId: popularSpots[index]["place_id"],
                                        ),
                                      )
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(2.0),
                                  height: popularSpotItemSize,
                                  width: popularSpotItemSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6.0),
                                          clipBehavior: Clip.hardEdge,
                                          child: Image.network(
                                            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                                                '&photoreference=${popularSpots[index]["image_url"]}'
                                                '&key=${_kGoogleApiKey}',
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          popularSpots[index]["spot_name"],
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    ],
                                  )
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
//                  Column(
//                    crossAxisAlignment: CrossAxisAlignment.start,
//                    children: [
//                      Text("最近見たプラン"),
//                      Divider(),
//                      SizedBox(
//                        height: 110,
//                        child: ListView(
//                          scrollDirection: Axis.horizontal,
//                          children: [
//                            //仮
//                            for(int i = 0;i < 5;i++)
//                              Padding(
//                                padding: const EdgeInsets.all(4.0),
//                                child: Container(
//                                  color: Colors.black12,
//                                  width: 150,
//                                  child: Text(i.toString()),
//                                ),
//                              )
//                          ],
//                        ),
//                      ),
//                    ],
//                  )
                ],
              ),
            ),
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }
    );
  }

  Future<dynamic> getInitialTopData() async{
    http.Response res  = await Network().getData("top");

    return json.decode(res.body);

  }

  Widget _buildFavoriteSpotItem(){
    return GestureDetector(

    );
  }

//  Widget appBar(){
//    Color iconColor = Colors.orange[300];
//    return AppBar(
//      backgroundColor: Colors.white,
//      leading: Builder(
//        builder: (context) => IconButton(
//          color: iconColor,
//          icon: new Icon(Icons.menu),
//          onPressed: () => Scaffold.of(context).openDrawer(),
//        ),
//      ),
//      actions: [
//        IconButton(
//          icon: Icon(Icons.settings_outlined),
//          color: iconColor,
//          onPressed: () {
//
//          },
//        ),
//      ],
//    );
//  }

//  Widget floatingActionButton(){
//    return FloatingActionButton(
//      onPressed: (){},
//      tooltip: 'Increment',
//      child: Icon(Icons.add),
//    );
//  }

}