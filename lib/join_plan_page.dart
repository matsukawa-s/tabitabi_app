import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'package:tabitabi_app/components/plan_item.dart';
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
  String searchResultPlanCode;

  @override
  void initState() {
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
                height: MediaQuery.of(context).size.height * 2/5,
                child: Column(
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
                          TextFormField(
                            controller: _planCodeController,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
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
                              ),
                              labelText: 'プランコード',
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    const Radius.circular(10.0),
                                  ),
                                  borderSide: BorderSide(
                                      color: Colors.black26
                                  )
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    const Radius.circular(10.0),
                                  ),
                                  borderSide: BorderSide(
                                      color: Colors.black54
                                  )
                              ),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    const Radius.circular(10.0),
                                  )
                              ),
                              focusedErrorBorder: OutlineInputBorder(
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
                          Container(
//                      margin: EdgeInsets.only(top: 6),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              message,
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14
                              ),
                            ),
                          ),
                          _buildSearchButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if(isSearch) _buildPlanView(plan),
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
        searchResultPlanCode = plan.planCode;
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
      margin: EdgeInsets.only(left: 10.0,top: 20,right: 10.0),
      width: double.infinity,
      child: RaisedButton.icon(
          onPressed: () => {
            if (_formKey.currentState.validate()) {
                  searchPlan()
            }
          },
          padding: EdgeInsets.all(8.0),
          icon: Icon(Icons.search),
          color: Colors.orange,
          textColor: Colors.white,
          shape: const StadiumBorder(),
          label: Text(
            "プランを検索する",
            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),
          )
      ),
    );
  }

  //プランに参加する
  joinPlan() async {
    final data = {
      "plan_code": searchResultPlanCode ?? ''
    };

    var res = await Network().postData(data, "member/store");
    var body = jsonDecode(res.body);

    Fluttertoast.showToast(msg: body["message"] ?? 'エラー');
  }

  Widget _buildPlanView(Plan plan){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Divider(),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildIconImageInUserTop(plan.user['icon_path'],14),
              ),
              Container(
                  width: MediaQuery.of(context).size.width / 4,
                  child: Text(plan.user['name'],style: TextStyle(fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,)
              ),
              Text("さんのプランに参加しますか？",style: TextStyle(fontSize: 12),overflow: TextOverflow.ellipsis,)
            ],
          ),
          PlanItem(
            plan: plan,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 2/5,
          ),
          Container(
            margin: EdgeInsets.only(top: 20.0),
            width: double.infinity,
            child: RaisedButton.icon(
                padding: EdgeInsets.all(8.0),
                onPressed: () => joinPlan(),
                icon: Icon(Icons.check),
                shape: const StadiumBorder(),
                color: Colors.blueAccent,
                textColor: Colors.white,
                label: Text("このプランに参加する",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconImageInUserTop(String iconPath, double size){
    final double iconSize = size;
    if(iconPath == null){
      return CircleAvatar(
        backgroundColor: Colors.grey,
        radius: iconSize,
      );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + iconPath),
      );
    }
  }
}
