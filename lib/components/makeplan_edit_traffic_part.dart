import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';

class TrafficPart extends StatefulWidget {
  final int id;
  final int trafficType;
  //分か秒を入れて計算で〜時間〜分とかするようにしたいね
  final String minutes;
  final bool confirmFlag;
  final bool flg;

  TrafficPart({
    Key key,
    this.id,
    this.trafficType,
    this.minutes,
    this.confirmFlag,
    this.flg,
  }) : super(key: key);

  @override
  _TrafficPartState createState() => _TrafficPartState();
}

class _TrafficPartState extends State<TrafficPart> {

  List<String> _hourList = ["0", "1", "2", "3", "4", "5", "6"];
  List<String> _minutesList = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];


  var _pickerData ='''
[
    {
        "a":0,
        "b":1,
        "c":2,
        "d":3,
        "e":4,
        "f":5,
        "g":6,
    },
    
]''';

  IconData _icon;
  String _travelTime = "";

  double _opacity = 0.5;

  @override
  void initState() {
    super.initState();

    _travelTime = widget.minutes;

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

  Future<void> _updateTime(String time) async{
    final data = {
      "id" : widget.id,
      "travel_time" : time,
    };

    http.Response res = await Network().postData(data, "itinerary/update/traffic/time");
    print(res.body);
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
              if(widget.flg){
                //showPickerDialog(context);
                String time = await _showTrafficTimeDialog();
                print("print:" + time);
                if(time != ""){
                  await _updateTime(time);
                  setState(() {
                    _travelTime = time;
                  });
                }
              }
            },
            behavior: HitTestBehavior.opaque,
          ),
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                _travelTime,
                  style: TextStyle(
                      color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                      fontSize: 14.0,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.normal
                  ),
              ),
            ),
            onTap: () async{
              if(widget.flg){
                //showPickerDialog(context);
                String time = await _showTrafficTimeDialog();
                print("print:" + time);
                if(time != ""){
                  await _updateTime(time);
                  setState(() {
                    _travelTime = time;
                  });
                }
              }
            },
            behavior: HitTestBehavior.opaque,
          )
        ],
      ),
    );
  }

  // showPickerDialog(BuildContext context) {
  //   new Picker(
  //       adapter: PickerDataAdapter<String>(
  //           pickerdata: new JsonDecoder().convert(_pickerData), isArray: true),
  //       hideHeader: true,
  //       title: new Text("交通の時間の変更"),
  //       onConfirm: (Picker picker, List value) {
  //         print(value.toString());
  //         print(picker.getSelectedValues());
  //       }
  //   ).showDialog(context);
  // }

  Future<String> _showTrafficTimeDialog() async{
    String time = "";
    String hour = "0";
    String minutes1 = "0";
    String minutes2 = "0";
    //文字入力
    await showDialog(
        context: context,
        builder:(context){
          return StatefulBuilder(
              builder: (_, setState) {
                return AlertDialog(
                  title: Text("時間の設定", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  content: SingleChildScrollView(
                    child: Container(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 40.0,
                                width: 60.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Center(
                                  child: DropdownButton<String>(
                                    value: hour,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                    onChanged: (String newValue) {
                                      setState(() {
                                        hour = newValue;
                                      });
                                    },
                                    items: _hourList
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                child: Text("時間"),
                              ),
                              Container(
                                  height: 40.0,
                                  width: 120.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      DropdownButton<String>(
                                        value: minutes1,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        onChanged: (String newValue) {
                                          setState(() {
                                            minutes1 = newValue;
                                          });
                                        },
                                        items: _minutesList
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                          );
                                        }).toList(),
                                      ),
                                      DropdownButton<String>(
                                        value: minutes2,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        onChanged: (String newValue) {
                                          setState(() {
                                            minutes2 = newValue;
                                          });
                                        },
                                        items: _minutesList
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value, style: TextStyle(fontWeight: FontWeight.normal),),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  )
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text("分"),
                              )
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top:20.0),
                            height: 40,
                            width: 250,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  child: Container(
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.grey,
                                    ),
                                    child: Center(
                                      child: Text("キャンセル", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                ),
                                GestureDetector(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 10.0),
                                    height: 40.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                      color: Colors.orange,
                                    ),
                                    child: Center(
                                      child: Text("確定", style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                  onTap: (){
                                    Navigator.of(context, rootNavigator: true).pop(context);
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)))
                );
              }
          );
        }
    );
    return time;
  }
}
