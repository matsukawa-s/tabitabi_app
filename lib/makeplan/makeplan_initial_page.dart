import 'package:flutter/material.dart';

import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'makeplan_top_page.dart';
import 'dart:ui';

class MakePlanInitial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('旅行プランを立てる'),
      ),
      resizeToAvoidBottomInset : false,
      body: MakePlanInitialState(),
    );
  }
}

class MakePlanInitialState extends StatefulWidget {
  @override
  _MakePlanInitialStateState createState() => _MakePlanInitialStateState();
}

class _MakePlanInitialStateState extends State<MakePlanInitialState> {

  //基本情報
  String _planName = "";
  String _planDetail = "";
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _mainImagePath = "images/2304099_m.jpg";

  //DatePickerを表示する
   DateTime _selectDate(BuildContext context, DateTime date, bool flag){
     DateTime selectDate = date;

     DatePicker.showDatePicker(context,
       showTitleActions: true,
       minTime: DateTime.now(),
       maxTime: new DateTime.now().add(new Duration(days: 720)),
       theme: DatePickerTheme(
         headerColor: Colors.white,
         backgroundColor: Colors.white,
         itemStyle: TextStyle(
           color: Colors.black,
           fontWeight: FontWeight.bold,
           fontSize: 18.0,
         ),
         doneStyle: TextStyle(
           color: Colors.black,
           fontSize: 16.0
         ),
       ),
       onConfirm: (date){
         //時間があったらここら辺のコード直す
         if(flag){
           //終了日が開始日より早いとき
           if(_startDate.compareTo(date) > 0){
              showDialog(
                context: context,
                builder: (_){
                  return AlertDialog(
                    content: Text("終了日が開始日より早い日付になっています。"),
                    actions: [
                      FlatButton(
                        child: Text("OK"),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  );
                }
              );
            }else{
              setState(() {
                _endDate = date;
              });
            }
         }else{
            setState(() {
              _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day + -(_startDate.difference(date).inDays));
              _startDate = date;
            });
         }
       },
       currentTime: date,
       locale: LocaleType.jp,
     );
     return selectDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Card(
        margin: EdgeInsets.only(left: 24.0, top: 16.0, right: 24.0, bottom: 16.0),
        child: Container(
          constraints: BoxConstraints.expand(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 5.0),
                child: Image(
                  image: AssetImage("images/illustrain02-travel04.png"),
                  width: 200.0,
                  height: 80.0,
                ),
              ),
              Text("基本情報入力", style: TextStyle(fontSize: 18.0, color: Colors.black54)),
              _buildTextField(Icons.flight_takeoff, "旅行名(*必須)"),
              _buildTextField(Icons.library_books, "旅行の説明"),
              _buildFormTitle(Icons.access_time, "日程"),
              Row(
                children: [
                  Expanded(
                      child: _buildDate(_startDate, false)
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("〜", style: TextStyle(color: Colors.black, fontSize: 18.0),),
                  ),
                  Expanded(
                      child: _buildDate(_endDate, true)
                  ),
                ],
              ),
              _buildFormTitle(Icons.image, "メイン画像の登録"),
              Container(
                margin: EdgeInsets.only(left: 24.0, top: 5.0, right: 24.0),
                child: Center(
                  child: Stack(
                    children: [
                      Image.asset(
                        _mainImagePath,
                        height: 150,
                        width: 250,
                        fit: BoxFit.fill,
                      ),
                      Positioned(
                        top: 0.1,
                        left: 0.1,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            height: 150,
                            width: 250,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20.0,
                        left: 30.0,
                        child: Text("画像をアップロードする", style: TextStyle(color: Colors.white, fontSize: 18.0)),
                      ),
                      Positioned(
                        top: 50.0,
                        left: 90.0,
                        child: Icon(Icons.camera_alt, size: 70.0, color: Colors.white,),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 5.0),
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton(
                    child: Text("登録する", style: TextStyle(color: Colors.white, fontSize: 18.0)),
                    color: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5.0,
                    onPressed: (){
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MakePlanTop(),
                        )
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String title){
     return Container(
       margin: EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
       height: 50.0,
       child:TextField(
         decoration: InputDecoration(
           labelText: title,
           labelStyle: TextStyle(color: Colors.black),
           prefixIcon: Icon(icon),
           enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(20.0),
             borderSide: BorderSide(
               color: Colors.black,
             ),
           ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(20.0),
             borderSide: BorderSide(
               color: Colors.black,
             ),
           ),
         ),
         style: TextStyle(color: Colors.black),
       ),
     );
  }

  Widget _buildDate(DateTime date, bool flg){
     return GestureDetector(
       child: Container(
         width: 300.0,
         margin: EdgeInsets.only(top: 5.0, left: 16.0, right: 16.0),
         padding: EdgeInsets.all(10.0),
         decoration: BoxDecoration(
           border: Border.all(color: Colors.black),
           borderRadius: BorderRadius.circular(15.0),
         ),
         child: Text(
           date.year.toString() + "/" + date.month.toString() + "/" + date.day.toString(),
           style: TextStyle(
             color: Colors.black,
             fontSize: 18.0,
           ),
           textAlign: TextAlign.center,
         ),
       ),
       onTap: (){
         _selectDate(context, date, flg);
       },
     );
  }

  Widget _buildFormTitle(IconData icon, String title){
     return Container(
       margin: EdgeInsets.only(left: 16.0, top: 10.0),
       child: SizedBox(
         width: double.infinity,
         child: RichText(
           textAlign: TextAlign.left,
           text: TextSpan(
             children: [
               WidgetSpan(
                 child: Icon(icon, color: Colors.grey,),
               ),
               TextSpan(
                 text: " " + title,
                 style: TextStyle(color: Colors.black, fontSize: 18.0),
               ),
             ]
           ),
         ),
       ),
     );
  }
}



