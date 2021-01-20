import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/login.dart';
import 'package:tabitabi_app/main.dart';

import 'makeplan/makeplan_top_page.dart';

class InitialLoginCheckPage extends StatelessWidget {
  _checkAuth(BuildContext context) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    return token == null ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuth(context),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        //処理待ち
        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(
              child: CircularProgressIndicator()
          );
        }

        if(snapshot.data){
          initDynamicLinks(context);
        }

        return snapshot.data ? MyHomePage() : LoginPage();

      }
    );
  }

  void initDynamicLinks(BuildContext context) async {
    //アプリが既に起動しているとき
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
            //プランIDの場合はプランのトップページへ遷移する
            if(deepLink.queryParameters.containsKey('id')){
              final planId = deepLink.queryParameters['id'];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return MakePlanTop(planId: int.parse(planId));
                  },
                ),
              );
            }

            //招待コードの場合はプラン参加ページへ遷移する
            if(deepLink.queryParameters.containsKey('invitation')){
              final planCode = deepLink.queryParameters['invitation'];
            }
          }
        }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
    await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      if(deepLink.queryParameters.containsKey('id')){
        var planId = deepLink.queryParameters['id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MakePlanTop(planId: int.parse(planId));
            },
          ),
        );
      }
    }
  }

  //deepLinkの処理
  void deepLinksProcess(BuildContext context){

  }

}
