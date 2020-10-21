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
//  static const MaterialColor customSwatch = const MaterialColor(
//    0xFFA4C639,
//    const <int, Color>{
//      50: const Color(0xFFF4F8E7),
//      100: const Color(0xFFE4EEC4),
//      200: const Color(0xFFD2E39C),
//      300: const Color(0xFFBFD774),
//      400: const Color(0xFFB2CF57),
//      500: const Color(0xFFA4C639),
//      600: const Color(0xFF9CC033),
//      700: const Color(0xFF92B92C),
//      800: const Color(0xFF89B124),
//      900: const Color(0xFF78A417),
//    },
//  );
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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Provider.of<NavigationBarProvider>(context).getTabLength(),
      child: Scaffold(
        appBar: AppBar(
//          backgroundColor: Colors.white,
          title: const Text('title',
            style: TextStyle(color: Colors.white),),
          bottom: Provider.of<NavigationBarProvider>(context).getAppBarBottom(),
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
//class MyHomePage extends StatefulWidget {
////  @override
////  _MyHomePageState createState() => _MyHomePageState();
////}

