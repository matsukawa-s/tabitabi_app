import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/login.dart';
import 'package:tabitabi_app/main.dart';

class InitialLoginCheckPage extends StatelessWidget {
  _checkAuth() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    initDynamicLinks();

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

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
//            Navigator.pushNamed(context, deepLink.path);
          }
        }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
    await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
//      Navigator.pushNamed(context, deepLink.path);
    }
  }

}
