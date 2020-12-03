import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/data/tag_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'model/map.dart';
import 'navigationbar_provider.dart';
import 'package:tabitabi_app/plan_search_detail_page.dart';
import 'package:tabitabi_app/top_page.dart';
import 'plan_search_history.dart';
import 'package:http/http.dart';
import 'result_provider.dart';
import 'navigationbar_provider.dart';
import 'plan_search_provider.dart';

import 'makeplan/makeplan_initial_page.dart';

void main() {
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
          create: (_) => TagDataProvider(),
        ),
        ChangeNotifierProvider<MapViewModel>(
          create:(_) => MapViewModel()
        ),
        ChangeNotifierProvider<PlanSearchProvider>(
          create: (context) => PlanSearchProvider(),
        ),
      ],
      child: MaterialApp(
        home: MyApp(),
      ),
    ),);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: CheckAuth(),
    );
  }
}

class CheckAuth extends StatefulWidget {
  @override
  _CheckAuthState createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  bool isAuth = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async{
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    if(token != null){
      setState(() {
        isAuth = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(isAuth){
      return MyHomePage();
    }else{
      return LoginPage();
    }
  }
}


class MyHomePage extends StatelessWidget {
  Color iconColor = Colors.orange[300];

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
        drawer: Container(
          width: 295,
          child: Drawer(
            child: ListView(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text("User Name"),
                  accountEmail: Text("User Email"),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage("https://pbs.twimg.com/profile_images/885510796691689473/rR9aWvBQ_400x400.jpg"),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[300],
                  ),
                ),
                ListTile(
                  title: Text("Item 1"),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: (){

                  },
                ),
                ListTile(
                  title: Text("Item 2"),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: (){

                  },
                ),
              ],
            ),
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
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    label: 'Map',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star_outline),
                    label: 'Favorite',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'User',
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
        onPressed: (){},
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
      return topPageAppBar();
    }else if(pageIndex == 1){           // SearchPageAppBar
      return searchPageAppBar(context);
    }else if(pageIndex == 2){           // MapPageAppBar
      return null;
    }else if(pageIndex == 3){           // FavoritePageAppBar
      return favoritePageAppBar(context);
    }else if(pageIndex == 4){           // UserPageAppBar
      return userPageAppbar();
    }
  }
  // TopPageAppBar
  AppBar topPageAppBar(){
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
  // SearchPageAppBar
  AppBar searchPageAppBar(context){
    var _textEditingController =
    TextEditingController(text: Provider.of<PlanSearchProvider>(context).keyword);
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          color: iconColor,
          icon: new Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
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
          hintText: "Type in your text",
//              fillColor: Colors.grey[100],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined),
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
      leading: Builder(
        builder: (context) => IconButton(
          color: iconColor,
          icon: new Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text("お気に入り"),
//      title: TextField(
//        cursorColor: iconColor,
//        decoration: InputDecoration(
////              border: OutlineInputBorder(
////                borderRadius: BorderRadius.circular(25.0),
////                  borderSide: BorderSide(
////                    color: Colors.white,
////                  ),
////              ),
//          border: InputBorder.none,
//          filled: true,
//          hintStyle: TextStyle(color: Colors.grey[500]),
//          hintText: "Type in your text",
////              fillColor: Colors.grey
//        ),
//      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined),
          color: iconColor,
          onPressed: () {

          },
        ),
      ],
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

  AppBar userPageAppbar(){
    return AppBar(
      title: Text("マイページ"),
    );
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
