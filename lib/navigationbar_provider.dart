import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    TimeLinePage(title: 'TIMELINE'),
    FavoritePage(title: 'FAVORITE'),
  ];
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

//  IconData getIcon(){
//    return _pageIcon[_selectedIndex];
//  }
}