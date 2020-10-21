import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_plan_page.dart';
import 'package:tabitabi_app/favorite_spot_page.dart';

import 'top_page.dart';
import 'search_page.dart';
import 'map_page.dart';
import 'timeline_page.dart';
import 'favorite_page.dart';

class NavigationBarProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  static List<Widget> _pageList = [
    TopPage(title: 'TOP'),
    SearchPage(title: 'SEARCH'),
    MapPage(title: 'MAP'),
    FavoritePage(title: 'FAVORITE'),
  ];
  List<int> _tabLength =[0,0,0,2];
  int get tabLength => _tabLength[_selectedIndex];
  final List<TabInfo> _tabs = [
    TabInfo("Plan", FavoritePlanPage()),
    TabInfo("Spot", FavoriteSpotPage()),
  ];
  List<TabInfo> get tabs => _tabs;


//  static List<IconData> _pageIcon = [
//    Icons.home,
//    Icons.search,
//    Icons.map,
//    Icons.menu,
//    Icons.star,
//  ];

//  static List<String> _pageTitle = [
//  ];

  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Widget getPage(){
    return _pageList[_selectedIndex];
  }

  int getTabLength(){
    return tabLength;
  }

  Widget getAppBarBottom(){
    if(selectedIndex == 3) {
      return ColoredTabBar(
        color: Colors.white,
        tabBar: TabBar(
          indicatorColor: Colors.orangeAccent,
//          controller: _controller,
          tabs: _tabs.map((TabInfo tab) {
              return Tab(text: tab.label);
            }).toList(),
        ),
      );
    }else{
      return null;
    }
  }
//  IconData getIcon(){
//    return _pageIcon[_selectedIndex];
//  }
}

class TabInfo {
  String label;
  Widget widget;
  TabInfo(this.label, this.widget);
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