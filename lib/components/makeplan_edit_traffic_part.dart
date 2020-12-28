import 'package:flutter/material.dart';

class TrafficPart extends StatefulWidget {
  final int trafficType;
  //分か秒を入れて計算で〜時間〜分とかするようにしたいね
  final int minutes;
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

    //minutesが60分以上のとき
    if(widget.minutes == null){
      _minutes = 0;
    }else if(widget.minutes >= 60){
      _hour = widget.minutes ~/ 60;
      _minutes = widget.minutes % 60;
    }else{
      _minutes = widget.minutes;
    }
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
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Icon(_icon, color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              _hour == 0 ?
                _minutes != 0 ?
                _minutes.toString() + "分" : "" :
                _minutes == 0 ?
                _hour.toString() + "時間" :
                _hour.toString() + "時間" + _minutes.toString() + "分",
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
}
