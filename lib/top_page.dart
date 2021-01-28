import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/components/spot_item.dart';
import 'package:tabitabi_app/join_plan_page.dart';
import 'package:tabitabi_app/makeplan/makeplan_initial_page.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/spot_details_page.dart';
import 'package:tabitabi_app/top_prefectures_spot_list_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'model/plan.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class TopPage extends StatelessWidget {
  final pagePadding = 6.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double popularPlanItemHeight = (size.width - pagePadding*2) * 2/5 * 4/5;
    final double popularPlanItemWidth = (size.width - pagePadding*2) * 2/5;
    final double popularSpotItemSize = (size.width - pagePadding*2) * 2/7;

    return FutureBuilder(
      future: getInitialTopData(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          final List<dynamic> todayPlansTmp = snapshot.data["today_plans"] ?? []; //今日のプラン
          final List<dynamic> popularPlansTmp = snapshot.data["popular_plans"] ?? []; //人気のプラン
          final List<dynamic> popularSpotsTmp = snapshot.data["popular_spots"] ?? []; //人気のスポット
          final List<dynamic> prefecturesSpotsTmp = snapshot.data["prefectures_spots"] ?? [];
          
          final List<Plan> todayPlans = List.generate(
              todayPlansTmp.length, (index) => Plan.fromJson(todayPlansTmp[index])
          );

          final List<Plan> popularPlans = List.generate(
              popularPlansTmp.length, (index) => Plan.fromJson(popularPlansTmp[index])
          );

          final List<Spot> popularSpots = List.generate(
              popularSpotsTmp.length, (index) => Spot.fromJson(popularSpotsTmp[index])
          );
          
          final List<Prefecture> prefecturesSpots = List.generate(
              prefecturesSpotsTmp.length, (index) => Prefecture.fromJson(prefecturesSpotsTmp[index])
          );

          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                children: [
                  if(todayPlans.isNotEmpty)
                    _buildJoinPlan(context),
                  //今日のプランを表示する
                  todayPlans.isEmpty ?
                  Container(
                    margin: EdgeInsets.only(left: 4.0, right: 4.0, bottom: 4.0),
                    height: 230,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Color(0xffFCF0C6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          child: Image.asset(
                            "images/illustrain02-travel04.png",
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(),
                          child: Text("さあ プランを作りましょう！", style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 5.0, left: 30.0, right: 30.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: RaisedButton(
                                child: Text(
                                  "プランを作成する",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                color: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onPressed: (){
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MakePlanInitial(),
                                      )
                                  );
                                }
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                          child: _buildJoinPlan(context),
                        ),
                      ],
                    ),
                  ) :
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 2.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black54,
                                width: 1
                              )
                            )
                          ),
                          child: Row(
                            children: [
                              Container(
                                  margin: EdgeInsets.only(right: 2.0),
                                  child: Icon(Icons.calendar_today,color: Colors.black54,size: 20,)
                              ),
                              Text(
                                "今日のプラン",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: (size.width - pagePadding*2) * 2/5,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: todayPlans.length,
                            itemBuilder: (BuildContext context, int index){
                              return Stack(
                                children: [
                                  PlanItem(
                                    plan: todayPlans[index],
                                    width: size.width - pagePadding*2,
                                    height: (size.width - pagePadding*2) * 2/5,
                                  ),
                                  Positioned(
                                    top: 5.0,
                                    right: 5.0,
                                    child: Text("${todayPlans[index].startDay} ~ ${todayPlans[index].endDay}"),
                                  )
                                ],
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
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            padding: EdgeInsets.only(bottom: 2.0),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.black54,
                                        width: 1
                                    )
                                )
                            ),
                            child: Row(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(right: 2.0),
                                    child: Icon(Icons.airplanemode_active,color: Colors.black54,size: 20,)
                                ),
                                Text(
                                  "人気のプラン",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: popularPlanItemHeight,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: popularPlans.length,
                              itemBuilder: (BuildContext context, int index){
                                return Container(
                                  margin: EdgeInsets.only(right: 4.0),
                                  child: PlanItem(
                                    plan: popularPlans[index],
                                    width: popularPlanItemWidth,
                                    height: popularPlanItemHeight,
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
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            padding: EdgeInsets.only(bottom: 2.0),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.black54,
                                        width: 1
                                    )
                                )
                            ),
                            child: Row(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(right: 2.0),
                                    child: Icon(Icons.add_location,color: Colors.black54,size: 20,)
                                ),
                                Text(
                                  "人気のスポット",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: popularSpotItemSize,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popularSpots.length,
                            itemBuilder: (BuildContext context,int index){
                              return Container(
                                margin: EdgeInsets.only(right: 4.0),
                                child: SpotItem(
                                  spot: popularSpots[index],
                                  width: popularSpotItemSize,
                                  height: popularSpotItemSize,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  prefecturesSpots.isEmpty ? Container()
                    : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          padding: EdgeInsets.only(bottom: 2.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black54,
                                      width: 1
                                  )
                              )
                          ),
                          child: Row(
                            children: [
                              Container(
                                  margin: EdgeInsets.only(right: 2.0),
                                  child: Icon(Icons.map,color: Colors.black54,size: 20,)
                              ),
                              Text(
                                "都道府県のスポット",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: popularSpotItemSize,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: prefecturesSpots.length,
                            itemBuilder: (BuildContext context,int index){
                              return Container(
                                padding: EdgeInsets.all(6.0),
                                width: popularSpotItemSize,
                                height: popularSpotItemSize,
                                child: GestureDetector(
                                  onTap: (){
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => PrefecturesSpotsListPage(
                                              prefecture: prefecturesSpots[index],
                                            )
                                        )
                                    );
                                  },
                                  child: Container(
                                      padding: EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        border: Border.all(color: Colors.white24),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
//                                              image: AssetImage("images/map-osaka.png")
                                            image: NetworkImage("${Network().baseUrl}prefectures_images/${prefecturesSpots[index].image}")
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: double.infinity,
//                                        padding: EdgeInsets.all(2.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white70,
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              prefecturesSpots[index].name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      )
                                  ),
                                ),
                              );
                            }
                        ),
                      )
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

  Widget _buildJoinPlan(context){
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: RaisedButton(
            child: Text(
              "プランに参加する",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
              ),
            ),
            color: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JoinPlanPage())
//                PageTransition(
//                    type: PageTransitionType.fade,
//                    child: JoinPlanPage(),
//                    inheritTheme: true,
//                    ctx: context
//                ),
              );
            }
        ),
      ),
    );
  }

  Future<dynamic> getInitialTopData() async{
    http.Response res  = await Network().getData("top");
    print(res.body);

    return json.decode(res.body);

  }
}