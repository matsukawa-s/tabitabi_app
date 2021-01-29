import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  TextEditingController _userNameController;
  bool isSubmit = false;

  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        print(pickedFile.path);
        _image = File(pickedFile.path);
        setState(() {
          isSubmit = true;
        });
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
        title: Text("プロフィールを編集"),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          FlatButton(
              onPressed: isSubmit ? saveProfile : null,
              child: Text(
                "保存",
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,),
              )
          )
//          IconButton(icon: Icon(Icons.check), onPressed: (){})
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  _buildIconImage(),
                  FlatButton(
                      onPressed: getImage,
                      child: Text("写真を変更する",style: TextStyle(fontSize: 14,color: Colors.black87),)
                  ),
                  Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _userNameController,
                        style: TextStyle(fontSize: 26),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                          labelText: 'ユーザーネーム',
                          labelStyle: TextStyle(fontSize: 20)
                        ),
                        onChanged: (input){
                          setState(() {
                            isSubmit = input == widget.userProfile["name"] ? false : true;
                          });
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveProfile() async{
    final data = {
      "name" : _userNameController.text.toString()
    };

    http.StreamedResponse res = await Network().postUploadImage(data, _image, 'user/profileSave');

    if(res.statusCode == 200){
      Fluttertoast.showToast(msg: "プロフィールを変更しました");
      setState(() {
        isSubmit = false;
      });
    }
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
        backgroundColor: Colors.black26,
        radius: iconSize,
//        child: Icon(Icons.person_sharp,size: constraint.biggest.height,color: Colors.white,),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(builder: (context, constraint) {
            return Icon(
                Icons.person,
                color: Colors.white,
                size: constraint.biggest.height
            );
          }),
        ),
      );
    }
  }
}
