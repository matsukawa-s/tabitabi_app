import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabitabi_app/main.dart';

import 'network_utils/api.dart';

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
      appBar: AppBar(
        title: Text("ログイン"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Center(
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          labelText: 'メールアドレス',
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
                        margin: EdgeInsets.only(top: 12.0,bottom: 12.0),
                        child: TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            icon: Icon(Icons.vpn_key),
                            border: OutlineInputBorder(),
                            labelText: 'パスワード',
                          ),
                          validator: (inputPassword){
                            if(inputPassword.isEmpty){
                              return 'パスワードを入力してください';
                            }
                            _password = inputPassword;
                            return null;
                          },
                        ),
                      ),
                      RaisedButton(
                        child: Text("ログイン"),
                        color: Colors.grey,
                        textColor: Colors.white,
                        onPressed: (){
                          if(_formKey.currentState.validate()){
                            _login();
                          }
                        }
                      ),
                      Container(
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
              ),
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

      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => MyHomePage()
      ));

    }else{
      setState(() {
        errorMessage = "メールアドレスまたはパスワードが違います";
      });
    }
  }
}
