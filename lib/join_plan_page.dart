import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:tabitabi_app/makeplan/qr_scan_page.dart';
import 'package:tabitabi_app/network_utils/api.dart';

import 'model/plan.dart';

class JoinPlanPage extends StatefulWidget {
  @override
  _JoinPlanPageState createState() => _JoinPlanPageState();
}

class _JoinPlanPageState extends State<JoinPlanPage> {
  final _formKey = GlobalKey<FormState>();
  var _planCodeController = TextEditingController();
  Size size;
  Plan plan;
  String planCode;
  String message = "";
  bool isSearch; // true: 検索,false: 結果表示

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isSearch = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("プランを探す"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 8.0),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                      "プランコードを入力またはQRコードを読み込んでください",
                      overflow: TextOverflow.visible,
                  ),
                )
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextFormField(
                          controller: _planCodeController,
//                          maxLength: 16,
                          decoration: InputDecoration(
                            labelText: 'プランコード',
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  const Radius.circular(10.0),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.black38
                                )
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  const Radius.circular(10.0),
                                )
                            ),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'プランコードを入力してください。';
                            }
                            return null;
                          },
                        ),
                        IconButton(
                          icon: Icon(
                              Icons.qr_code_scanner,
                              color: const Color(0xfff96800)
                          ),
                          onPressed: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            //QRコードで読み取る
                            final result = await Navigator.push(
                              context,
                              PageTransition(
                                  type: PageTransitionType.fade,
                                  child: QRViewExample(),
                                  inheritTheme: true,
                                  ctx: context
                              ),
                            );
                            print(result);
                            _planCodeController.text = result;
                          },
                        )
                      ],
                    ),
                    if(isSearch) _buildPlanView(plan) else _buildSearchButton(),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 18
                          ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //プランコードからプランを検索する
  void searchPlan() async{
    var res = await Network().getData("member/search/${_planCodeController.text.toString()}");
    var body = jsonDecode(res.body);

    if(body["is_exist"]){
      setState(() {
        message = '';
        plan = Plan.fromJson(body["plan"]);
        isSearch = true;
      });
    }else{
      setState(() {
        message = body["message"];
        isSearch = false;
      });
    }

  }

  Widget _buildSearchButton(){
    return Container(
      margin: EdgeInsets.only(top: 50.0),
      child: RaisedButton.icon(
          onPressed: () => {
            if (_formKey.currentState.validate()) {
                  searchPlan()
            }
          },
          icon: Icon(Icons.search),
          label: Text("プランを検索する")),
    );
  }

  //プランに参加する
  joinPlan() async{
    final data = {
      "plan_code" : _planCodeController.text.toString()
    };

    var res = await Network().postData(data, "member/store");
    var body = jsonDecode(res.body);

    setState(() {
      message = body["message"];
    });
  }

  Widget _buildPlanView(Plan plan){
    return Column(
      children: [
        Container(
//          margin: EdgeInsets.only(top: 50.0),
          padding: EdgeInsets.all(10.0),
//          color: Colors.black12,
//          decoration: BoxDecoration(
//            border: Border.all(color: Colors.black12),
//            borderRadius: BorderRadius.circular(10),
//          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("作成者：${plan.user["name"]}"),
                  Container(
                      width: 1000,
                      child: Image.asset("images/osakajo.jpg",fit: BoxFit.fill,)
                  ),
                  Text(
                      "${plan.title}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                  ),
//                  Text(plan.description),
                ],
              ),
            ],
          ),
        ),
        RaisedButton.icon(
            onPressed: () => joinPlan(),
            icon: Icon(Icons.check),
            label: Text("このプランに参加する")
        ),
      ],
    );
  }
}
