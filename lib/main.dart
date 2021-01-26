import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/data/tag_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/initial_login_check_page.dart';
import 'package:tabitabi_app/providers/plan_provider.dart';
import 'login.dart';
import 'model/map.dart';
import 'model/plan.dart';
import 'model/spot_model.dart';
import 'navigationbar_provider.dart';
import 'package:tabitabi_app/plan_search_detail_page.dart';
import 'package:tabitabi_app/top_page.dart';
import 'network_utils/api.dart';
import 'plan_search_history.dart';
import 'package:http/http.dart';
import 'result_provider.dart';
import 'navigationbar_provider.dart';
import 'plan_search_model.dart';
import 'makeplan/makeplan_initial_page.dart';

//ユーザーページの右上ポップアップメニュー
enum WhyFarther { Logout }

Future main() async{
  await DotEnv().load('.env');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ResultProvider>(
          create: (context) => ResultProvider(),
        ),
        ChangeNotifierProvider<NavigationBarProvider>(
          create: (context) => NavigationBarProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TagDataProvider()
        ),
        ChangeNotifierProvider<MapViewModel>(
          create:(_) => MapViewModel()
        ),
        ChangeNotifierProvider<PlanSearchModel>(
          create: (context) => PlanSearchModel(),
        ),
        ChangeNotifierProvider<FavoriteSpotViewModel>(
            create: (context) => FavoriteSpotViewModel()
        ),
        ChangeNotifierProvider<PlanProvider>(
            create: (context) => PlanProvider()
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.orange,
        ),
        home: InitialLoginCheckPage(),
      ),
    ),);
}

class MyHomePage extends StatelessWidget {
  final Color iconColor = Colors.orange[300];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Provider.of<NavigationBarProvider>(context).tabs.length,
      child: Scaffold(
        appBar: _appBar(context),
        body: SafeArea(
          child: Consumer<NavigationBarProvider>(
              builder: (_, model, __) {
                return model.getPage();
              }
          ),
        ),
        floatingActionButton: floatingActionButton(context),
        bottomNavigationBar: Consumer<NavigationBarProvider>(
            builder: (_, model, __) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'ホーム',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'プラン検索',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    label: '地図',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    label: 'お気に入り',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'マイページ',
                  ),
                ],
                currentIndex: model.selectedIndex,
                onTap: (int index){
                  model.onItemTapped(index);
                },
              );
            }
        ),
      ),
    );
  }



  // pageごとのFAB設定
  Widget floatingActionButton(context){
    // 表示されている pageindex を取得
    int pageIndex = Provider.of<NavigationBarProvider>(context).selectedIndex;
    // return する FAB の変数
    Widget fab;

    //　TopPage(0), UserPage(4) の FAB
    if(pageIndex == 0 || pageIndex == 4){
      fab = FloatingActionButton(
        onPressed: (){
          Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MakePlanInitial(),
              )
          );
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      );
    }else{
      fab = null;
    }
    return fab;
  }

  // pageごとのAppBarを設定
  AppBar _appBar (context){
    // 表示されているpageindexを取得
    int pageIndex = Provider.of<NavigationBarProvider>(context).selectedIndex;

    if(pageIndex == 0){                 // TopPageAppBar
//      return topPageAppBar();
        return null;
    }else if(pageIndex == 1){           // SearchPageAppBar
      return searchPageAppBar(context);
    }else if(pageIndex == 2){           // MapPageAppBar
      return null;
    }else if(pageIndex == 3){           // FavoritePageAppBar
      return favoritePageAppBar(context);
    }else if(pageIndex == 4){           // UserPageAppBar
      return userPageAppbar(context);
    }
  }

  // SearchPageAppBar
  AppBar searchPageAppBar(context){
    var _textEditingController =
    TextEditingController(text: Provider.of<PlanSearchModel>(context).keyword);
    return AppBar(
      backgroundColor: Colors.white,
      title: TextField(
        controller: _textEditingController,
        readOnly: true,
        autofocus: false,
        onTap: () {
          final FocusScopeNode currentScope = FocusScope.of(context);
          if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
            FocusManager.instance.primaryFocus.unfocus();
          }
          Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: PlanSearchHistoryPage(),
                ctx: context,
              ),
          );
        },
        cursorColor: iconColor,
        decoration: InputDecoration(
//              border: OutlineInputBorder(
//                borderRadius: BorderRadius.circular(25.0),
//                  borderSide: BorderSide(
//                    color: Colors.white,
//                  ),
//              ),
          border: InputBorder.none,
          filled: true,
          hintStyle: TextStyle(color: Colors.grey[500]),
          hintText: "検索したい文字やタグを入力",
//              fillColor: Colors.grey[100],
        ),
      ),
      actions: [
        IconButton(
//          icon: Icon(Icons.import_export),
          icon: Icon(Icons.sort),
          color: iconColor,
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: PlanSearchDetailPage(),
                ctx: context,
              ),
            );
          },
        ),
      ],
    );
  }

  AppBar favoritePageAppBar(context) {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text("お気に入り"),
      centerTitle: true,
      bottom: ColoredTabBar(
        color: Colors.white,
        tabBar: TabBar(
          indicatorColor: Colors.orangeAccent,
          tabs: Provider.of<NavigationBarProvider>(context).tabs.map((TabInfo tab) {
            return Tab(text: tab.label);
          }).toList(),
        ),
      ),
    );
  }

  AppBar userPageAppbar(BuildContext context){
    return AppBar(
      backgroundColor: Colors.white,
      title: Text("マイページ"),
      centerTitle: true,
      actions: [
        PopupMenuButton(
            onSelected: (WhyFarther result) {
              switch(result){
                case WhyFarther.Logout:
                  logout(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<WhyFarther>>[
              const PopupMenuItem<WhyFarther>(
                value: WhyFarther.Logout,
                child: Text('ログアウト'),
              ),
            ]
        )
      ],
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
            child: InitialLoginCheckPage(),
            inheritTheme: true,
            ctx: context
        ),
      );
    }
  }

}

class ColoredTabBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget tabBar;
  final Color color;

  ColoredTabBar({@required this.tabBar, @required this.color});

  @override
  Widget build(BuildContext context) {
    return Ink(
      color: color,
      child: tabBar,
    );
  }

  @override
  Size get preferredSize => tabBar.preferredSize;
}

class TextBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration:
        InputDecoration(border: InputBorder.none, hintText: 'Search'),
      ),
    );
  }
}
