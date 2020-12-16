import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/main.dart';
import 'package:tabitabi_app/user_profile_edit_page.dart';

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
    return FutureBuilder(
      future: _getUser(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          final userProfile = snapshot.data;
          return Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          children: <Widget>[
                            _buildIconImageInUserTop(userProfile["icon_path"]),
                            Text(
                              userProfile["name"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.black12,
//                        border: Border.all(color: Colors.grey),
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
                ),
                Divider(),
                Container(
                  margin: EdgeInsets.only(top: 4.0),
                  child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Text("作成したプラン"),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
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
                          child: Text("作成したプラン"),
                        ),
                        Container(
                          child: Text("参加しているプラン"),
                        )
                      ],
                    )
                )
              ],
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

  Future<dynamic> _getUser() async{
    var res = await Network().getData('get_user');
    var body = json.decode(res.body);

    return body;
  }

  Widget _buildIconImageInUserTop(String iconPath){
    final double iconSize = 40.0;
    if(iconPath == null){
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
      );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + iconPath),
      );
    }
  }

}
