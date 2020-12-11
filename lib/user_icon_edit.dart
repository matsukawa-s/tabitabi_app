import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'network_utils/api.dart';
import 'package:http/http.dart' as http;

class UserIconEditPage extends StatefulWidget {
  @override
  _UserIconEditPageState createState() => _UserIconEditPageState();
}

class _UserIconEditPageState extends State<UserIconEditPage> {
  File _image;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("アイコンを変更する"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                if(_image != null)
                  CircleAvatar(
                    backgroundColor: Colors.black12,
                    radius: 100.0,
                    backgroundImage:FileImage(_image)
                  ),
                FlatButton(
                    onPressed: getImage,
                    child: Text("画像を選択する")
                ),
                RaisedButton(
                    onPressed: (){
                      saveProfile();
                    },
                    child: Text("変更を保存する"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveProfile() {
    var res = Network().postUploadImage({}, _image, 'user/iconSave');
  }
}
