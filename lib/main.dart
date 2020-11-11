import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigationbar_provider.dart';

import 'result_provider.dart';

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
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatelessWidget {
  AppBar _appBar (context){
    int pageIndex = Provider.of<NavigationBarProvider>(context).selectedIndex;
    PreferredSizeWidget _appBarBottom;
    if(pageIndex == 3){
      return AppBar(
        title: const Text('title',
          style: TextStyle(color: Colors.white),),
        bottom: ColoredTabBar(
          color: Colors.white,
          tabBar: TabBar(
            indicatorColor: Colors.orangeAccent,
//          controller: _controller,
            tabs: Provider.of<NavigationBarProvider>(context).tabs.map((TabInfo tab) {
              return Tab(text: tab.label);
            }).toList(),
          ),
        ),
      );
    }else if(pageIndex == 2){
        return null;
    }else{
      return AppBar(
        title: Text('title',
          style: TextStyle(color: Colors.white),),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Provider.of<NavigationBarProvider>(context).tabs.length,
      child: Scaffold(
        appBar: _appBar(context),
        body: Consumer<NavigationBarProvider>(
            builder: (_, model, __) {
              return model.getPage();
            }
        ),
        bottomNavigationBar: Consumer<NavigationBarProvider>(
            builder: (_, model, __) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: 'Favorite',
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