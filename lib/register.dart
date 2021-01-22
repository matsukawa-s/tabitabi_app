import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'network_utils/api.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String _name;
  String _email;
  String _password;
  String errorMessage = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("新規登録"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 12.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              icon: Icon(Icons.account_circle),
                              border: OutlineInputBorder(),
                              labelText: 'ユーザー名',
                            ),
                            validator: (inputName){
                              if(inputName.isEmpty){
                                return 'ユーザー名を入力してください';
                              }
                              _name = inputName;
                              return null;
                            },
                          ),
                        ),
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
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.all(12.0),
                          child: RaisedButton(
                              padding: EdgeInsets.all(10.0),
                              child: Text(
                                  "登録する",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold
                                  ),
                              ),
                              color: Colors.black12,
                              textColor: Colors.white,
                              shape: const StadiumBorder(),
                              onPressed: (){
                                if(_formKey.currentState.validate()){
                                  _register();
                                }
                              }
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _register() async{
    var data = {
      "name" : _name,
      "email" : _email,
      "password" : _password
    };

    var res = await Network().authData(data, 'auth/register');
    var body = json.decode(res.body);

    if(body['success']){
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      localStorage.setString('token', json.encode(body['token']));
      localStorage.setString('user', json.encode(body['user']));

      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => MyHomePage()
      ));
    }
  }
}
