import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';

class JoinPlanPage extends StatefulWidget {
  @override
  _JoinPlanPageState createState() => _JoinPlanPageState();
}

class _JoinPlanPageState extends State<JoinPlanPage> {
  var _planCodeController = TextEditingController();
  String planCode;
  String message = "";

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("プランコードを入力して参加する"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.centerRight,
                          children: <Widget>[
                            TextFormField(
                              controller: _planCodeController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
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
                                labelText: 'プランコード',
//                                contentPadding: const EdgeInsets.fromLTRB(6, 6, 48, 6), // 48 -> icon width
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                  Icons.qr_code_scanner,
                                  color: const Color(0xfff96800)
                              ),
                              onPressed: () {
                                FocusScope.of(context).requestFocus(FocusNode());
                                // Your codes...
                              },
                            ),
                          ],
                        ),
                        Divider(),
                        Container(
                          margin: EdgeInsets.only(top: 50.0),
                          child: RaisedButton.icon(
                            onPressed: () => joinPlan(),
                            icon: Icon(Icons.check),
                            label: Text("プランに参加する")),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Text(
                              message,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18
                              ),
                          ),
                        )
                      ],
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
}
