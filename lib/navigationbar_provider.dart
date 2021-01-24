import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_plan_page.dart';
import 'package:tabitabi_app/favorite_spot_page.dart';
import 'package:tabitabi_app/map_page_second.dart';
import 'package:tabitabi_app/user_page.dart';

import 'top_page.dart';
import 'plan_search_page.dart';
import 'map_page.dart';
import 'favorite_page.dart';

class NavigationBarProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  int _selectedFIndex = 0;
  int get selectedFIndex => _selectedFIndex;
  static List<Widget> _pageList = [
    TopPage(),
    PlanSearchPage(),
    MapPage(title: 'MAP'),
//    MapPage(),
    FavoritePage(title: 'FAVORITE'),
    UserPage(),
  ];
  final List<TabInfo> _tabs = [
    TabInfo(0,"プラン", FavoritePlanPage()),
    TabInfo(1,"スポット", FavoriteSpotPage()),
  ];
  List<TabInfo> get tabs => _tabs;

  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void onTabTapped(int index) {
    _selectedFIndex = index;
    notifyListeners();
  }

  Widget getPage(){
    return _pageList[_selectedIndex];
  }
}


class TabInfo {
  int index;
  String label;
  Widget widget;
  TabInfo(this.index,this.label, this.widget);
}