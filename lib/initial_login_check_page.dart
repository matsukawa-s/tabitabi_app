import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/login.dart';
import 'package:tabitabi_app/main.dart';

class InitialLoginCheckPage extends StatelessWidget {
  _checkAuth() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    return token == null ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuth(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        //処理待ち
        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(
              child: CircularProgressIndicator()
          );
        }

        return snapshot.data ? MyHomePage() : LoginPage();

      }
    );
  }

}
