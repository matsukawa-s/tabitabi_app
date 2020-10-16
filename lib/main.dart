import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigationbar_provider.dart';

import 'result_provider.dart';
import 'navigationbar_provider.dart';

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
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('title'),
      ),
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
                  icon: Icon(Icons.menu),
                  label: 'TimeLine',
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
    );
  }
}
//class MyHomePage extends StatefulWidget {
////  @override
////  _MyHomePageState createState() => _MyHomePageState();
////}

