import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:tabitabi_app/makeplan/get_map_page.dart';
import 'package:tabitabi_app/network_utils/aws_s3.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tabitabi_app/model/spot_model.dart';

final bucketName = DotEnv().env['BucketName'];

class MakeSpotPage extends StatefulWidget {
  Function callback;

  @override
  _MakeSpotPageState createState() => _MakeSpotPageState();
}

class _MakeSpotPageState extends State<MakeSpotPage> {
  final _formKey = GlobalKey<FormState>();

  String _spotName = "";
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _address;
  File _image;
  final ImagePicker _picker = ImagePicker();

  bool isFileUploading = false;

  Future _getImageFromGallery() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);

    if(pickedFile != null){
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _addSpot() async{
    if(_spotName == "" || _latitude == 0.0 || _longitude == 0.0){
      return null;
    }

    String imageUrl = "https://" + bucketName +  ".s3.amazonaws.com/spot/no_image.png";

    if(_image != null) {
      imageUrl = await AwsS3().uploadImage(_image.path, "spot");
    }

    final data = {
      'place_id' : _spotName,
      'spot_name' : _spotName,
      'latitube' : _latitude,
      'longitube' : _longitude,
      'image_url' : imageUrl,
      'prefecture_id' : 48,
    };

    http.Response res = await Network().postData(data, "spot/store");
    print(res.body);

    List<Spot> returnValue = [];

    returnValue.add(
      Spot(
        spotId: int.parse(res.body),
        placeId: _spotName,
        spotName: _spotName,
        lat: _latitude,
        lng: _longitude,
        imageUrl: imageUrl,
        types:1,
        prefectureId: 1,
        isLike: 0,
      )
    );

    Navigator.of(context).pop(returnValue);

  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //スポット名
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Container(
                      margin: EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                      child:TextFormField(
                        decoration: InputDecoration(
                          labelText: "スポット名",
                          labelStyle: TextStyle(color:Color(0xffACACAC),),
                          focusColor: Theme.of(context).primaryColor,
                          prefixIcon: Icon(Icons.edit),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Color(0xffACACAC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.black),
                        validator: (value){
                          if(value.isEmpty){
                            return "スポット名を入力してください";
                          }
                          return null;
                        },
                        onEditingComplete: (){
                          if (_formKey.currentState.validate()) {

                          }
                        },
                        onChanged: (value){
                          _spotName = value;
                        },
                      ),
                    ),
                  ),
                  //場所
                  _buildFormTitle(Icons.map, "場所"),
                  GestureDetector(
                    onTap: () async{
                      var result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GetMap(),
                          )
                      );
                      print(result);
                      if(result != null){
                        setState(() {
                          _latitude = result[0];
                          _longitude = result[1];
                        });
                      }

                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 10.0),
                      height: 50.0,
                      width: MediaQuery.of(context).size.width - 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Color(0xffACACAC)),
                        color: Colors.grey,
                      ),
                      child: Center(
                        child: Text("地図から探す", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10.0),
                    child: Text("x : " + _latitude.toString() + " y : " + _longitude.toString()),
                  ),
                  //画像
                  _buildFormTitle(Icons.image, "画像"),
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(left: 24.0, top: 10.0, right: 24.0, bottom: 20.0),
                      child: Center(
                        child: Stack(
                          children: [
                            _image == null?
                            Image.asset(
                              "images/no_image.png",
                              height: 150,
                              width: 250,
                              fit: BoxFit.fill,
                            ):
                            Image.file(
                              _image,
                              height: 150,
                              width: 250,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0.1,
                              left: 0.1,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                child: Container(
                                  height: 150,
                                  width: 250,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20.0,
                              left: 30.0,
                              child: Text("画像をアップロードする", style: TextStyle(color: Colors.white, fontSize: 18.0)),
                            ),
                            Positioned(
                              top: 50.0,
                              left: 90.0,
                              child: Icon(Icons.camera_alt, size: 70.0, color: Colors.white,),
                            )
                          ],
                        ),
                      ),
                    ),
                    onTap: (){
                      _getImageFromGallery();
                    },
                    behavior: HitTestBehavior.translucent,
                  ),
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(top: 20.0),
                      height: 40.0,
                      width: MediaQuery.of(context).size.width - 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.orange,
                      ),
                      child: Center(
                        child: Text("登録する", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    ),
                    onTap: (){
                      _addSpot();
                    },
                  )
                ],
              ),
            ),
          ),
          if(isFileUploading)
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  height: 110,
                  width: 122,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text("スポットを追加中", style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),),
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFormTitle(IconData icon, String title){
    return Container(
      margin: EdgeInsets.only(left: 16.0, top: 10.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
              children: [
                WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Icon(icon, color: Colors.grey, size: 24,),
                    )
                ),
                WidgetSpan(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(" " + title, style: TextStyle(color: Colors.black, fontSize: 18.0),),
                    )
                ),
              ]
          ),
        ),
      ),
    );
  }
}
