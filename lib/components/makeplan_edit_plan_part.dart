import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class PlanPart extends StatefulWidget {
  final int number;
  final int id;
  final String spotName;
  final String spotPath;
  final DateTime spotStartDateTime;
  final DateTime spotEndDateTime;
  final int spotParentFlag; //子がいるかどうか
  final bool confirmFlag;  //確定しているかどうか
  final double width;
  final bool flg;
  final DateTime day;

  PlanPart({
    Key key,
    this.number,
    this.id,
    this.spotName,
    this.spotPath,
    this.spotStartDateTime,
    this.spotEndDateTime,
    this.spotParentFlag,
    this.confirmFlag,
    this.width,
    this.flg,
    this.day
  }) : super(key: key);

  @override
  _PlanPartState createState() => _PlanPartState();
}

class _PlanPartState extends State<PlanPart> {
  double _opacity = 0.5;
  final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

  List<String> _popUpMenuItem = ["開始時間の設定", "終了時間の設定", "スポットの詳細"];

  DateTime startDateTime;
  DateTime endDateTime;

  @override
  void initState() {
    super.initState();

    if(widget.spotStartDateTime != null){
      startDateTime = widget.spotStartDateTime;
      endDateTime = widget.spotEndDateTime;
    }
  }

  //日付の更新
  Future<void> _updateDate() async{
    String start = startDateTime==null ? "" : DateFormat('yy-MM-dd HH:mm').format(startDateTime);
    String end = endDateTime==null ? "" : DateFormat('yy-MM-dd HH:mm').format(endDateTime);

    print(start);
    print(end);
    final data = {
      "id" : widget.id,
      "start_date" : start,
      "end_date" : end,
    };

    http.Response res = await Network().postData(data, "itinerary/update/spot/date");
    print(res.body);
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20.0,
          width: 30.0,
          child: Container(
            margin: EdgeInsets.only(right: 10.0),
            color: widget.confirmFlag == true ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(_opacity) ,
            child: Center(
              child: Text(
                widget.number==null ? "" : widget.number.toString(),
                style: TextStyle(
                  color: widget.confirmFlag == true ? Colors.white : Colors.white.withOpacity(_opacity),
                  fontSize: 14.0,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 60.0,
          width: widget.width - (widget.width / 6),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: widget.confirmFlag ? Theme.of(context).cardColor : Theme.of(context).cardColor.withOpacity(_opacity),
                  boxShadow: [
                    BoxShadow(
                      color: widget.confirmFlag ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.01),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Opacity(
                    opacity: widget.confirmFlag ? 1.0 : _opacity,
                    child: Container(
                      constraints: BoxConstraints.expand(width: widget.width / 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft:  const  Radius.circular(20.0),
                          bottomLeft: const  Radius.circular(20.0),
                        ),
                        child: widget.spotPath == null ? Container() : Image.network(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                              '&photoreference=${widget.spotPath}'
                              '&key=${_kGoogleApiKey}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints.expand(width: widget.width / 6 * 2 + 30),
                    padding: EdgeInsets.only(left: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.spotName != null ?
                          widget.spotName:
                          "",
                        style: TextStyle(
                          color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                          fontSize: 14.0,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal
                        ),
                      ),
                    )
                  ),
                  Container(
                    constraints: BoxConstraints.expand(width: widget.width /6),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text(
                            startDateTime!=null ?
                            startDateTime.hour.toString().padLeft(2,"0") + ":" + startDateTime.minute.toString().padLeft(2,"0") :
                            "",
                            style: TextStyle(
                              color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                              fontSize: 14.0,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.normal
                            ),
                          ),
                        ),
                        Text(endDateTime !=null && startDateTime!=null ?
                          "|" :
                          "",
                          style: TextStyle(
                            color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                            fontSize: 14.0,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 0.0),
                          child: Text(endDateTime!=null ?
                            endDateTime.hour.toString().padLeft(2,"0") + ":" + endDateTime.minute.toString().padLeft(2,"0") :
                            "",
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
                  ),
                  if(widget.flg)
                  Container(
                    constraints: BoxConstraints.expand(width: widget.width /6 -30),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      initialValue: "value",
                      onSelected: (String s) {
                        if(s == _popUpMenuItem[0]){
                          _startSetDateTime();
                        }else if(s==_popUpMenuItem[1]){
                          _endSetDateTime();
                        }
                        setState(() {

                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _popUpMenuItem.map((String s) {
                          return PopupMenuItem(
                            child: Text(s, style: TextStyle(fontSize: 14.0),),
                            value: s,
                          );
                        }).toList();
                      },
                    )
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  _startSetDateTime(){
    DatePicker.showTimePicker(
        context,
        showTitleActions: true,
        onConfirm: (date) {
          print('confirm $date');
            setState(() {
            startDateTime = date;
            });
            _updateDate();
        },
        currentTime: startDateTime==null ? DateTime.now(): startDateTime,
      onCancel: (){
         setState(() {
           startDateTime = null;
         });
         _updateDate();
      }
    );
  }

  _endSetDateTime(){
    DatePicker.showTimePicker(context,
        showTitleActions: true,
        onConfirm: (date) {
      print('confirm $date');
      setState(() {
        if(startDateTime == null){
          endDateTime = date;
          _updateDate();
        }else if(date.isAfter(startDateTime)){
          endDateTime = date;
          _updateDate();
        }
      });
    }, currentTime: endDateTime==null ? DateTime.now(): endDateTime,
        onCancel: (){
          setState(() {
            endDateTime = null;
          });
          _updateDate();
        }
    );
    // DatePicker.showPicker(context, showTitleActions: true, onChanged: (date) {
    //   print('change $date in time zone ' + date.timeZoneOffset.inHours.toString());
    // }, onConfirm: (date) {
    //   print('confirm $date');
    // }, pickerModel: CustomPicker(currentTime: DateTime.now()), locale: LocaleType.en);
  }

  // _buildDialog(BuildContext context){
  //
  //   DateTime tempStartDate = startDateTime==null ? DateTime(widget.day.year,widget.day.month,widget.day.day,DateTime.now().hour,DateTime.now().minute):startDateTime;
  //   DateTime tempEndDate = endDateTime==null ? DateTime(widget.day.year,widget.day.month,widget.day.day,DateTime.now().hour+1,DateTime.now().minute):endDateTime;
  //
  //   return showDialog(
  //     context: context,
  //     builder: (_){
  //       return AlertDialog(
  //         title: Text("時間の設定", textAlign: TextAlign.center,),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             children: [
  //               Text("開始時間", style: TextStyle(fontSize: 14.0),textAlign: TextAlign.left,),
  //               GestureDetector(
  //                 child: Container(
  //                   height: 40.0,
  //                   width: 150.0,
  //                   margin: EdgeInsets.only(top: 5.0),
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10.0),
  //                     border: Border.all(color: Colors.grey),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       tempStartDate.hour.toString().padLeft(2,"0") + ":" + tempStartDate.minute.toString().padLeft(2,"0")
  //                     ),
  //                   ),
  //                 ),
  //                 onTap: (){
  //                   DatePicker.showTimePicker(context, showTitleActions: true, onChanged: (date) {
  //                     print('change $date in time zone ' + date.timeZoneOffset.inHours.toString());
  //                   }, onConfirm: (date) {
  //                     print('confirm $date');
  //                   }, currentTime: DateTime.now());
  //                 },
  //               ),
  //               Padding(
  //                 padding: EdgeInsets.only(top: 5.0),
  //                 child: Text("終了時間", style: TextStyle(fontSize: 14.0),textAlign: TextAlign.left,),
  //               ),
  //               Container(
  //                 height: 40.0,
  //                 width: 150.0,
  //                 margin: EdgeInsets.only(top: 5.0),
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(10.0),
  //                   border: Border.all(color: Colors.grey),
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                    tempEndDate.hour.toString().padLeft(2,"0") + ":" + tempEndDate.minute.toString().padLeft(2,"0")
  //                   ),
  //                 ),
  //               )
  //             ],
  //           )
  //         ),
  //         actions: <Widget>[
  //           // ボタン領域
  //           FlatButton(
  //             child: Text("Cancel"),
  //             onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
  //           ),
  //           FlatButton(
  //             child: Text("OK"),
  //             onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
  //           ),
  //         ],
  //       );
  //     }
  //   );
  // }
}
