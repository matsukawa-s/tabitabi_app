import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'network_utils/api.dart';
import 'package:http/http.dart' as http;

class UserProfileEditPage extends StatefulWidget {
  final userProfile;
  UserProfileEditPage({Key key,@required this.userProfile}) : super(key : key);

  @override
  _UserProfileEditPageState createState() => _UserProfileEditPageState();
}

class _UserProfileEditPageState extends State<UserProfileEditPage> {
  File _image;
  String _name;
  TextEditingController _userNameController;

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        print(pickedFile.path);
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.userProfile["name"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ユーザー情報を変更する"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                children: [
                  _buildIconImage(),
                  FlatButton(
                      onPressed: getImage,
                      child: Text("画像を選択する")
                  ),
                  Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _userNameController,
                        style: TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          labelText: 'ユーザー名',
                        ),
                      ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 16.0),
                    child: RaisedButton(
                        onPressed: (){
                          saveProfile();
                        },
                        child: Text("変更を保存する"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveProfile() {
    final data = {
      "name" : _userNameController.text.toString()
    };

    var res = Network().postUploadImage(data, _image, 'user/profileSave');
  }

  Widget _buildIconImage(){
    final double iconSize = 100.0;
    if(_image != null){
      return CircleAvatar(
          backgroundColor: Colors.black12,
          radius: iconSize,
          backgroundImage:FileImage(_image)
      );
    }else if(widget.userProfile["icon_path"] != null){
          return CircleAvatar(
            backgroundColor: Colors.black12,
            radius: iconSize,
            backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + widget.userProfile["icon_path"]),
          );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
      );
    }
  }
}
