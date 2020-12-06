import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:tabitabi_app/data/tag_data.dart';
import 'makeplan_top_page.dart';
import 'dart:ui';
import 'package:tabitabi_app/components/add_tag_part.dart';
import 'add_tag_page.dart';

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
  List<TagData> _tag = [];
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Padding(
          //   padding: EdgeInsets.only(top: 5.0),
          //   child: Image(
          //     image: AssetImage("images/illustrain02-travel04.png"),
          //     width: 200.0,
          //     height: 80.0,
          //   ),
          // ),
          // Text("基本情報入力", style: TextStyle(fontSize: 18.0, color: Colors.black54)),
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
          _buildFormTitle(Icons.link, "タグ"),
          _tag.length == 0 ?GestureDetector(
              onTap: (){
                Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddTagPage(),
                    )
                ).then((value){
                  setState(() {
                    _tag = context.read<TagDataProvider>().tagData;
                  });
                });
              },
              child:Container(
                margin: EdgeInsets.only(top: 10.0),
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      width: 300,
                      decoration: BoxDecoration(
                          border: Border.all(color: Color(0xffACACAC), width: 1),
                          borderRadius: BorderRadius.circular(10.0)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("目的に合ったタグをつけよう！"),
                          Container(
                            margin: EdgeInsets.only(top: 10.0),
                            height: 30,
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.indigo,
                            ),
                            child: Center(
                              child: Text("タグを追加する", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
          ):
          GestureDetector(
            onTap: (){
              Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddTagPage(),
                  )
              ).then((value){
                setState(() {
                  _tag = context.read<TagDataProvider>().tagData;
                });
              });
            },
            child: Container(
                margin: EdgeInsets.only(top: 10.0),
                padding: EdgeInsets.all(20.0),
                width: 300,
                decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffACACAC), width: 1),
                    borderRadius: BorderRadius.circular(10.0)
                ),
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    for(int i=0; i<_tag.length; i++)
                      TagPart(title: _tag[i].tagName,)
                  ],
                )
            ),
          ),
          _buildFormTitle(Icons.image, "メイン画像の登録"),
          Container(
            margin: EdgeInsets.only(left: 24.0, top: 10.0, right: 24.0),
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
          Container(
            margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: RaisedButton(
                child: Text("登録する", style: TextStyle(color: Colors.white, fontSize: 18.0)),
                color: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 3.0,
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
             borderRadius: BorderRadius.circular(10.0),
             borderSide: BorderSide(
               color: Color(0xffACACAC),
             ),
           ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10.0),
             borderSide: BorderSide(
               color: Color(0xffACACAC),
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
           border: Border.all(color: Color(0xffACACAC)),
           borderRadius: BorderRadius.circular(10.0),
         ),
         child: Text(
           date.year.toString() + "/" + date.month.toString().padLeft(2, '0') + "/" + date.day.toString().padLeft(2, '0'),
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
         width: MediaQuery.of(context).size.width,
         child: RichText(
           textAlign: TextAlign.left,
           text: TextSpan(
             children: [
               WidgetSpan(
                 child: Padding(
                   padding: EdgeInsets.only(top: 5.0),
                   child: Icon(icon, color: Colors.grey, size: 24,),
                 )
               ),
               WidgetSpan(
                 child: Padding(
                   padding: EdgeInsets.only(top: 8.0),
                   child: Text(" " + title, style: TextStyle(color: Colors.black, fontSize: 18.0),),
                 )
               ),
             ]
           ),
         ),
       ),
     );
  }
}



