import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_spot_page.dart';
import 'package:tabitabi_app/model/spot_model.dart';

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
    return WillPopScope(
      onWillPop: (){
        Navigator.of(context).pop(_selectedSpots);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('スポットの追加'),
        ),
        body: Column(
          children: [
            Container(
              height: 40.0,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Text("お気に入り", style: TextStyle(color: Colors.black),),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Text("地図から", style: TextStyle(color: Colors.black)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
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
                    child: Text("2"),
                  ),
                  Container(
                    child: Text("3"),
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}
