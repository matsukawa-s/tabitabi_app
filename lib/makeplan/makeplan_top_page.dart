import 'package:flutter/material.dart';
import 'makeplan_edit_page.dart';

class MakePlanTop extends StatefulWidget {
  @override
  _MakePlanTopState createState() => _MakePlanTopState();
}

class _MakePlanTopState extends State<MakePlanTop> {

  String _planName = "旅行名旅行名旅行名旅行名";
  String _planDetail = "旅行の説明です。旅行の説明です。旅行の説明です。旅行の説明です。旅行の説明です。旅行の説明です。";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('トップ'),
      // ),
      resizeToAvoidBottomInset : false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("images/paper_00108.jpg"),
              //colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.3), BlendMode.color),
              fit: BoxFit.cover
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200.0,
              actions: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: (){},
                ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: (){},
                ),
              ],
              flexibleSpace: Container(
                constraints: BoxConstraints.expand(height: 250.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("images/2304099_m.jpg"),
                    //image: NetworkImage("https://picsum.photos/1500/800"),
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10.0),
                      child: Text(_planName, style: TextStyle(color: Colors.white, fontSize: 32.0)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 5.0, bottom: 10.0),
                      child: Text(_planDetail, style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              bottom: PreferredSize(child: Text("", style: TextStyle(color: Colors.white)), preferredSize: Size.fromHeight(53.0),),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //スケジュール
                    Card(
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 400),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildTitle("10/23"),
                                Expanded(
                                  child: DefaultTabController(
                                    length: 3,
                                    child: Builder(
                                      builder: (BuildContext context) => Stack(
                                        children: [
                                          Container(
                                            height: 400,
                                            width: 500,
                                            child: TabBarView(
                                              children: [
                                                _buildSchedule("1"),
                                                _buildSchedule("2"),
                                                _buildSchedule("3"),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0.0,
                                            left: 0.0,
                                            right: 0.0,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: TabPageSelector(),
                                            )
                                          ),
                                          Positioned(
                                            top: 0.0,
                                            bottom: 0.0,
                                            left: -30.0,
                                            child: IconButton(
                                              icon: Icon(Icons.chevron_left),
                                              iconSize: 80.0,
                                              color: Colors.orange,
                                              onPressed: (){
                                                final TabController controller = DefaultTabController.of(context);
                                                if(!(controller.index == 0)){
                                                  controller.animateTo(controller.index - 1);
                                                }
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: 0.0,
                                            bottom: 0.0,
                                            right: -30,
                                            child: IconButton(
                                              icon: Icon(Icons.chevron_right),
                                              iconSize: 80.0,
                                              color: Colors.orange,
                                              onPressed: (){
                                                final TabController controller = DefaultTabController.of(context);
                                                if(!(controller.index == 2)){
                                                  controller.animateTo(controller.index + 1);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                  child: FloatingActionButton(
                                    heroTag: 'planEdit',
                                    backgroundColor: Colors.orange,
                                    child: Icon(Icons.edit),
                                    onPressed: (){
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => MakePlanEdit(),
                                          )
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ),
                    //メンバー
                    Card(
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTitle("メンバー"),
                            Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.account_circle, size: 64.0),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                child: FloatingActionButton(
                                  heroTag: 'memberAdd',
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.add),
                                  onPressed: (){},
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //アルバム
                    Card(
                      margin: EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0, bottom: 30.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        constraints: BoxConstraints.expand(height: 350),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTitle("アルバム"),
                            Expanded(
                              child: Container(),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomRight,
                                margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                child: FloatingActionButton(
                                  heroTag: 'albumAdd',  //これを指定しないと複数FloatingActionButtonが使えない
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.add),
                                  onPressed: (){},
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  //各項目のタイトル
  Widget _buildTitle(String title){
    return Padding(
      padding: EdgeInsets.only(top: 15.0),
      child: Text(title , style: TextStyle(fontSize: 18.0)),
    );
  }

  //各日程のスケジュール
  Widget _buildSchedule(String test){
    return Container(
      margin: EdgeInsets.only(left: 16.0, top: 5.0, right: 16.0),
      color: Colors.greenAccent,
      child: Text(test),
    );
  }
}

