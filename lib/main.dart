import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigationbar_provider.dart';

import 'result_provider.dart';
import 'navigationbar_provider.dart';

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
                  title: Text("Home"),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  title: Text("Search"),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  title: Text("map"),
                ),

                BottomNavigationBarItem(
                  icon: Icon(Icons.star),
                  title: Text("Favorite"),
                ),
              ],
              currentIndex: model.selectedIndex,
              onTap: (int index){
                model.onItemTapped(index);
              },
            );
          }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MakePlanInitial(),
              )
          );
        },
        label: Text('test'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
//class MyHomePage extends StatefulWidget {
////  @override
////  _MyHomePageState createState() => _MyHomePageState();
////}

