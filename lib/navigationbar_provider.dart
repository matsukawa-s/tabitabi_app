import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_plan_page.dart';
import 'package:tabitabi_app/favorite_spot_page.dart';

import 'top_page.dart';
import 'search_page.dart';
import 'map_page.dart';
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
  final List<TabInfo> _tabs = [
    TabInfo("Plan", FavoritePlanPage()),
    TabInfo("Spot", FavoriteSpotPage()),
  ];
  List<TabInfo> get tabs => _tabs;

  void onItemTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Widget getPage(){
    return _pageList[_selectedIndex];
  }
}


class TabInfo {
  String label;
  Widget widget;
  TabInfo(this.label, this.widget);
}