import 'package:flutter/material.dart';
import 'package:tabitabi_app/pages/favorite_spot_page.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/makeplan/make_spot_page.dart';
import 'package:tabitabi_app/pages/map_page.dart';
import 'package:tabitabi_app/pages/map_page_fix.dart';
class AddSpotPage extends StatefulWidget {
  @override
  _AddSpotPageState createState() => _AddSpotPageState();
}

class _AddSpotPageState extends State<AddSpotPage> with SingleTickerProviderStateMixin{
  TabController _tabController;
  List<Spot> _selectedSpots; // お気に入りスポット一覧から選択しているスポット

  @override
  void initState() {
    super.initState();
    _tabController =  TabController(length: 3, vsync: this);
  }

  //選択したスポットをセットする
  callback(List<Spot> returnValue){
    setState(() {
      _selectedSpots = returnValue;
    });
    print(_selectedSpots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スポットの追加'),
        backgroundColor: Colors.white.withOpacity(0.7),
        actions: [
          FlatButton(
              onPressed: () => Navigator.of(context).pop(_selectedSpots),
              child: Text("決定",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),)
          )
        ],
      ),
      body: Column(
        children: [
          Container(
//            height: 40.0,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Text("お気に入り", style: TextStyle(color: Colors.black),),
                ),
                Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Text("地図から", style: TextStyle(color: Colors.black)),
                ),
                Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Text("自分で作る", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Container(
                  child: FavoriteSpotPage(mode: true,callback: callback),
                ),
                Container(
                  child: MapFixPage(addFlag: true,),
                ),
                Container(
                  child: MakeSpotPage(),
                ),
              ],
            ),
          )
        ],
      )
    );
  }
}
