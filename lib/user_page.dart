import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/main.dart';

import 'network_utils/api.dart';

class UserPage extends StatelessWidget {
  //ユーザー情報をローカルストレージから取得する
  _getUser() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUser(),
      builder: (context, snapshot) {
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
//              backgroundImage: NetworkImage("https://pbs.twimg.com/profile_images/885510796691689473/rR9aWvBQ_400x400.jpg"),
                    ),
                    Text("ユーザ名"),
                  ],
                ),
              ),
              Container(
                  margin: EdgeInsets.all(16.0),
                  child: Text("作成したプラン",textAlign: TextAlign.left,)
              ),
              Container(
                  margin: EdgeInsets.all(16.0),
                  child: Text("参加しているプラン")
              ),
              FlatButton(
                  onPressed: () => logout(context),
                  color: Colors.orange,
                  child: Text("ログアウト")
              )
            ],
          ),
        );
      }
    );
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
