import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/main.dart';
import 'package:tabitabi_app/makeplan/makeplan_top_page.dart';
import 'package:tabitabi_app/user_profile_edit_page.dart';

import 'model/plan.dart';
import 'network_utils/api.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin{
  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController =  TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final double paddingAroundPage = 8.0; // ページ周りのPaddingサイズ
    final double spaceBetweenWidget = 4.0; // プランの間のスペースサイズ
    final double paddingTabAround = 6.0; // タブビュー内の周りのPaddingサイズ

    final Size size = MediaQuery.of(context).size; //デバイスのサイズ
    final double itemHeight = (size.width - paddingTabAround*2 - spaceBetweenWidget) / 2 * 2/3;
    final double itemWidth = (size.width - paddingTabAround*2 - spaceBetweenWidget) / 2;

    return FutureBuilder(
      future: _getUser(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          final userProfile = snapshot.data["user"];
          final createdPlansTmp = snapshot.data["my_plans"];
          final participatingPlansTmp = snapshot.data["participating_plans"];

          final List<Plan> createdPlans = List.generate(
              createdPlansTmp.length, (index) => Plan.fromJson(createdPlansTmp[index])
          );

          final List<Plan> participatingPlans = List.generate(
              participatingPlansTmp.length, (index) => Plan.fromJson(participatingPlansTmp[index])
          );

          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(paddingAroundPage),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: _buildIconImageInUserTop(userProfile["icon_path"]),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 12.0, left: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: (){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => UserProfileEditPage(userProfile: userProfile),
                                  )
                                );
                              },
                          ),
                        )
                      ],
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 2,
                      margin: EdgeInsets.only(top: 4.0),
//                        color: Colors.red,
                      child: Text(
                          userProfile["name"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18.0,
//                              fontWeight: FontWeight.w600
                          ),
                          overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 4.0),
                child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Text("作成したプラン"),
                      ),
                      Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Text("参加しているプラン"),
                      ),
                    ]
                ),
              ),
              Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Container(
                        padding: EdgeInsets.all(paddingTabAround),
                        child:  createdPlans.isEmpty
                          ? Center(
                              child: Text("作成したプランがありません"),
                            )
                            : Container(
//                              margin: EdgeInsets.only(top:8.0),
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: spaceBetweenWidget,
                                  crossAxisSpacing: spaceBetweenWidget,
                                  childAspectRatio: itemWidth / itemHeight,
                                ),
                                itemCount: createdPlans.length,
                                itemBuilder: (BuildContext context, int index){
                                  return PlanItem(plan: createdPlans[index],width: itemWidth,height: itemHeight,);
//                                  return _buildPlanItem(itemWidth, itemHeight, createdPlans[index],false);
                                }
                              ),
                            )
                      ),
                      Container(
                        padding: EdgeInsets.all(paddingTabAround),
                        child: participatingPlans.isEmpty
                          ? Center(
                              child: Text("参加しているプランがありません"),
                            )
                            : Container(
                                margin: EdgeInsets.only(top:8.0),
                                child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: spaceBetweenWidget,
                                      crossAxisSpacing: spaceBetweenWidget,
                                      childAspectRatio: itemWidth / itemHeight,
                                    ),
                                    itemCount: participatingPlans.length,
                                    itemBuilder: (BuildContext context, int index){
                                      return PlanItem(plan: participatingPlans[index],width: itemWidth,height: itemHeight,);
//                                      return _buildPlanItem(itemWidth, itemHeight, participatingPlans[index],true);
                                    }
                                ),
                              )
                      )
                    ],
                  )
              )
            ],
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }
    );
  }

  Future<dynamic> _getUser() async{
    var res = await Network().getData('user/get_user');
    var body = json.decode(res.body);

    return body;
  }

//  ユーザーのアイコン
  Widget _buildIconImageInUserTop(String iconPath){
    final double iconSize = 40.0;
    if(iconPath == null){
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: LayoutBuilder(builder: (context, constraint) {
            return Icon(
                Icons.person,
                color: Colors.white,
                size: constraint.biggest.height
            );
          }),
        ),
      );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + iconPath),
      );
    }
  }

//  １つのプランアイテム
  Widget _buildPlanItem(double width, double height, Map<String,dynamic> plan, bool readOnly){
    //readOnly: true 参加しているプラン（表示のみ）,false 作成したプラン（編集可能）
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MakePlanTop(planId: plan["id"]);
            },
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 2.0), //(x,y)
                blurRadius: 6.0,
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset(
                "images/osakajo.jpg",
                width: width,
                height: height * 4/5,
                fit: BoxFit.fill,
              ),
// 画像
//              if(plan["image_url"] == null)
//                Image.asset(
//                  "images/osakajo.jpg",
//                  width: width,
//                  height: height * 4/5,
//                  fit: BoxFit.fill,
//                )
//              else
//                Image.network(
//                  plan["image_url"],
//                  width: width,
//                  height: height * 4/5,
//                  fit: BoxFit.fill,
//                ),
              Container(
                height: height * 1/5,
                child: Text(
                  plan["title"],
                  style: TextStyle(fontSize: 20.0),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
