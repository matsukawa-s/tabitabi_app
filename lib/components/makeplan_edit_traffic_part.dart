import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class TrafficPart extends StatefulWidget {
  final int trafficType;
  //分か秒を入れて計算で〜時間〜分とかするようにしたいね
  final String minutes;
  final bool confirmFlag;

  TrafficPart({
    Key key,
    this.trafficType,
    this.minutes,
    this.confirmFlag,
  }) : super(key: key);

  @override
  _TrafficPartState createState() => _TrafficPartState();
}

class _TrafficPartState extends State<TrafficPart> {
  int _hour = 0;
  int _minutes = 0;

  IconData _icon;

  double _opacity = 0.5;

  @override
  void initState() {
    super.initState();

    //trafficTypeによってアイコン
    if(widget.trafficType != null){
      switch(widget.trafficType){
        case 1:
          _icon = Icons.directions_walk;
          break;
        case 2:
          _icon = Icons.directions_car;
          break;
        case 3:
          _icon = Icons.train;
          break;
        case 4:
          _icon = Icons.airplanemode_active;
          break;
      }
    }

    // //minutesが60分以上のとき
    // if(widget.minutes == null){
    //   _minutes = 0;
    // }else if(widget.minutes >= 60){
    //   _hour = widget.minutes ~/ 60;
    //   _minutes = widget.minutes % 60;
    // }else{
    //   _minutes = widget.minutes;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //constraints: BoxConstraints.expand(height: 50.0),
      height: 50.0,
      margin: EdgeInsets.only(left: MediaQuery.of(context).size.height / 10),
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
                color: widget.confirmFlag ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(_opacity),
                width: 3.0
            )
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Icon(_icon, color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),),
            ),
            onTap: () async{
              //String time = await _showTrafficTimeDialog();

            },
            behavior: HitTestBehavior.opaque,
          ),
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              widget.minutes,
                style: TextStyle(
                    color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                    fontSize: 14.0,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.normal
                ),
            ),
          )
        ],
      ),
    );
  }

  Future<String> _showTrafficTimeDialog() async{
    String time = "";
    String hour;
    String minutes;
    //文字入力
    await showDialog(
        context: context,
        builder: (_){
      return AlertDialog(
        title: Text("時間の設定",style: TextStyle(fontSize: 18.0), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40.0,
                width: 60.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Text("時間"),
              ),
              Container(
                height: 40.0,
                width: 60.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5.0),
                child: Text("分"),
              )
            ],
          ),
        ),
        actions: <Widget>[
          // ボタン領域
          FlatButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
          ),
          FlatButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
          ),
        ],
      );
    }
    );

    return time;
  }
}
