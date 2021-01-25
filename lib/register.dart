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
  final focusName = FocusNode();
  final focusEmail = FocusNode();
  final focusPassword = FocusNode();

  String _name;
  String _email;
  String _password;
  String _validEmailExistsMessage;
  String errorMessages = "";

  @override
  void dispose() {
    super.dispose();
    focusName.dispose();
    focusEmail.dispose();
    focusPassword.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("新規登録"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                              focusNode: focusName,
                              decoration: InputDecoration(
                                icon: Icon(Icons.account_circle),
                                border: OutlineInputBorder(),
                                labelText: 'ユーザーネーム',
                              ),
                              validator: (inputName){
                                if(inputName.isEmpty){
                                  return 'ユーザーネームを入力してください';
                                }
                                _name = inputName;
                                return null;
                              },
                            ),
                          ),
                          TextFormField(
                            focusNode: focusEmail,
                            decoration: InputDecoration(
                              icon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                              labelText: 'メールアドレス',
                            ),
                            validator: (inputEmail){
                              if(inputEmail.isEmpty){
                                return 'メールアドレスを入力してください';
                              }
                              if(validateEmail(inputEmail)){
                                return '有効なメールアドレスではありません';
                              }
                              _email = inputEmail;
                              return null;
                            },
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 12.0,bottom: 12.0),
                            child: TextFormField(
                              focusNode: focusPassword,
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
                                color: Colors.orange,
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
                              errorMessages,
                              style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),
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
      ),
    );
  }

  //メールアドレスの入力チェック
  bool validateEmail(String value) {
    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
    return !emailValid;
  }

  Future<bool> validateEmailExists(String value) async{
    return true;
  }

  void _register() async{
    focusName.unfocus();
    focusEmail.unfocus();
    focusPassword.unfocus();

    final data = {
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

      Navigator.pushAndRemoveUntil(context,MaterialPageRoute(
          builder: (context) => MyHomePage()
      ), (route)=>false);
//      Navigator.pushReplacement(context, MaterialPageRoute(
//          builder: (context) => MyHomePage()
//      ));
    }else{
      //登録失敗（バリデーションエラー）
        Map<String,dynamic> messages = body["message"];
        setState(() {
          errorMessages = '';
        });
        var tmp;
        var message;
        for(String key in messages.keys){
          message = messages[key].toString().substring(1,messages[key].toString().length - 1);
          setState(() {
            errorMessages += (message + '\n');
          });
        }
    }
  }
}
