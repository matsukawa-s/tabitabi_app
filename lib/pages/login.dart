import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/main.dart';
import 'package:tabitabi_app/pages/register.dart';

import '../network_utils/api.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String _email;
  String _password;
  String errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      backgroundColor: Colors.orange[200].withOpacity(0.7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Column(
                children: [
//                  Container(
//                      width: double.infinity,
//                      child: Text(
//                        "旅行のプランの作成・共有・検索アプリ",
//                        style: TextStyle(
//                          color: Colors.grey,
//                          fontSize: 16,
//                          fontWeight: FontWeight.bold,
//                        ),
//                        textAlign: TextAlign.center,
//                      )
//                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 3,
                    child: Center(
                        child: Image.asset(
                          'images/logo.png',
                          width: MediaQuery.of(context).size.width,
                        )
                    ),
                  ),
                  Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'メールアドレス',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'exsample@gmail.com',
                              hintStyle: TextStyle(
                                color: Colors.black26,
                                fontSize: 16
                              )
                            ),
                            validator: (inputEmail){
                              if(inputEmail.isEmpty){
                                return 'メールアドレスを入力してください';
                              }
                              _email = inputEmail;
                              return null;
                            },
                          ),
                          Container(
                            margin: EdgeInsets.all(10),
                          ),
                          Text(
                            'パスワード',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          TextFormField(
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '8文字以上で入力してください。',
                              hintStyle: TextStyle(
                                color: Colors.black26,
                                fontSize: 16
                              )
                            ),
                            validator: (inputPassword){
                              if(inputPassword.isEmpty){
                                return 'パスワードを入力してください';
                              }
                              _password = inputPassword;
                              return null;
                            },
                          ),
                          Container(
                            child: Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.all(12.0),
                            child: RaisedButton(
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                    "ログイン",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                    ),
                                ),
                                color: Colors.orange,
                                textColor: Colors.white,
                                shape: const StadiumBorder(),
                                onPressed: (){
                                  if(_formKey.currentState.validate()){
                                    _login();
                                  }
                                }
                            ),
                          ),
                        ],
                      )
                  ),
                  Divider(),
                  FlatButton(
                      onPressed: (){
                        Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.fade,
                              child: RegisterPage(),
                              inheritTheme: true,
                              ctx: context
                          ),
                        );
                      },
                      child: Text(
                          "新規登録はこちら",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                      )
                  )
                ],
              ),
            )
          ),
        ),
      ),
    );
  }

  void _login() async{
    var data = {
      "email" : _email,
      "password" : _password
    };

    var res = await Network().authData(data, 'auth/login');
    var body = json.decode(res.body);

    if(body['success']){
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('token', json.encode(body['token']));
      localStorage.setString('user', json.encode(body['user']));
      print(body['token']);

      Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: MyHomePage(),
            inheritTheme: true,
            ctx: context
        ),
      );

    }else{
      setState(() {
        errorMessage = "メールアドレスまたはパスワードが違います";
      });
    }
  }
}
