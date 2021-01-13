import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:tabitabi_app/join_plan_page.dart';
import 'package:tabitabi_app/network_utils/api.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class TopPage extends StatelessWidget {
  final String title;

  TopPage({@required this.title});

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.all(8.0),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("今日のプラン"),
                      Divider(),
                      Container(
                        margin: EdgeInsets.only(bottom: 8.0),
                        height: 150,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  //人気のプランを表示する
                  popularPlans.isEmpty ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("人気のプラン"),
                        Divider(),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: popularPlans.length,
                              itemBuilder: (BuildContext context, int index){
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    color: Colors.black12,
                                    width: 150,
                                    child: Text(popularPlans[index]["title"]),
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
                        Text("人気のスポット"),
                        Divider(),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popularSpots.length,
                            itemBuilder: (BuildContext context,int index){
                              return Container(
                                padding: EdgeInsets.all(4.0),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 110,
                                      width: 110,
//                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                                            '&photoreference=${popularSpots[index]["image_url"]}'
                                            '&key=${_kGoogleApiKey}',
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    Container(
                                      width: 110,
                                      child: Text(
                                        popularSpots[index]["spot_name"],
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  ],
                                )
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("最近見たプラン"),
                      Divider(),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            //仮
                            for(int i = 0;i < 5;i++)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  color: Colors.black12,
                                  width: 150,
                                  child: Text(i.toString()),
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  )
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

  Widget appBar(){
    Color iconColor = Colors.orange[300];
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          color: iconColor,
          icon: new Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined),
          color: iconColor,
          onPressed: () {

          },
        ),
      ],
    );
  }

  Widget floatingActionButton(){
    return FloatingActionButton(
      onPressed: (){},
      tooltip: 'Increment',
      child: Icon(Icons.add),
    );
  }

  Future<dynamic> getInitialTopData() async{
    http.Response res  = await Network().getData("top");

    return json.decode(res.body);

  }
}