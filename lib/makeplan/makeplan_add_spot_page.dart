import 'package:flutter/material.dart';

class AddSpotPage extends StatefulWidget {
  @override
  _AddSpotPageState createState() => _AddSpotPageState();
}

class _AddSpotPageState extends State<AddSpotPage> with SingleTickerProviderStateMixin{

  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController =  TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: Text("1"),
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
    );
  }
}
