import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/main.dart';
import 'package:tabitabi_app/user_icon_edit.dart';

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
          print(Network().imagesDirectory(userProfile["icon_path"]));
          return Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black12,
                        radius: 50.0,
                        backgroundImage: NetworkImage(Network().imagesDirectory(userProfile["icon_path"])),
                      ),
                      Text(userProfile["name"]),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text("ユーザー情報を変更する"),
                  onTap: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserIconEditPage(),
                        )
                    );
                  },
                ),
                FlatButton(
                    onPressed: () => logout(context),
                    color: Colors.orange,
                    child: Text("ログアウト")
                ),
                TabBar(
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

  void logout(BuildContext context) async {
    var res = await Network().getData('auth/logout');
    var body = json.decode(res.body);
    if (body['success']) {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.remove('user');
      localStorage.remove('token');
      Navigator.pushReplacement(
          context,
          PageTransition(
              type: PageTransitionType.fade,
              child: CheckAuth(),
              inheritTheme: true,
              ctx: context
          ),
      );
    }
  }
}
