import 'package:flutter/material.dart';
import 'package:tabitabi_app/components/add_tag_part.dart';
import 'add_tag_page.dart';
import 'package:tabitabi_app/data/tag_data.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tabitabi_app/network_utils/aws_s3.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui';

class PlanInfoEditPage extends StatefulWidget {

  final int planId;
  final String planTitle;
  final List<TagData> tags;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String imageUrl;

  PlanInfoEditPage(
      this.planId,
      this.planTitle,
      this.tags,
      this.startDateTime,
      this.endDateTime,
      this.imageUrl,
  );

  @override
  _PlanInfoEditPageState createState() => _PlanInfoEditPageState();
}

class _PlanInfoEditPageState extends State<PlanInfoEditPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _textEditingController;

  //基本情報
  String _planTitle = "";
  List<TagData> _tags = [];
  DateTime _startDateTime;
  DateTime _endDateTime;
  String _imageUrl;
  final ImagePicker _picker = ImagePicker();
  File _image;

  //アップロードフラグ
  bool isFileUploading = false;

  @override
  void initState() {
    _planTitle = widget.planTitle;
    _tags = widget.tags;
    _startDateTime = widget.startDateTime;
    _endDateTime = widget.endDateTime;
    _imageUrl = widget.imageUrl;

    _textEditingController = new TextEditingController(text: _planTitle);
    context.read<TagDataProvider>().clearTagData();
    for(int i=0; i<_tags.length; i++){
      context.read<TagDataProvider>().addTagData(_tags[i]);
      print(_tags[i].tagName);
    }

    super.initState();
  }

  Future _getImageFromGallery() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);

    if(pickedFile != null){
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePlan() async{
    int tagFlg = 1;
    if(_tags == widget.tags){
      tagFlg = 0;
    }
    if(_planTitle == ""){
      return null;
    }
    setState(() {
      isFileUploading = true;
    });
    List<int> tagIds = [];
    for(int i=0; i<_tags.length; i++){
      tagIds.add(_tags[i].tagId);
    }

    if(_image != null) {
      _imageUrl = await AwsS3().uploadImage(_image.path, "plan/thumbnail");
    }

    final data = {
      "id" : widget.planId,
      "plan_title" : _planTitle,
      "image_url" : _imageUrl,
      "tag_flg" : tagFlg,
      "tag_id" : tagIds,
    };

    http.Response res = await Network().postData(data, "plan/info/update");
    print(res.body);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("プラン情報の編集"),
        backgroundColor: Colors.white.withOpacity(0.7),
        actions: [
          Align(
            widthFactor: 1.0,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                child: Text("保存", style: TextStyle(fontSize: 17.0),),
                onTap: () async{
                  await _updatePlan();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(top: 100.0),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //旅行名
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Container(
                        margin: EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                        child:TextFormField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            labelStyle: TextStyle(color:Color(0xffACACAC),),
                            focusColor: Theme.of(context).primaryColor,
                            prefixIcon: Icon(Icons.flight_takeoff),
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
                              return "旅行名を入力してください";
                            }
                            return null;
                          },
                          onEditingComplete: (){
                            if (_formKey.currentState.validate()) {

                            }
                          },
                          onChanged: (value){
                            _planTitle = value;
                          },
                        ),
                      ),
                    ),
                    //タグ
                    _buildFormTitle(Icons.link, "タグ"),
                    _tags.length == 0 ?GestureDetector(
                        onTap: (){
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddTagPage(),
                              )
                          ).then((value){
                            setState(() {
                              _tags = context.read<TagDataProvider>().tagData;
                            });
                          });
                        },
                        child:Container(
                          margin: EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              Container(
                                height: 100,
                                width: 340,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xffACACAC), width: 1),
                                  borderRadius: BorderRadius.circular(10.0)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("目的に合ったタグをつけよう！"),
                                    Container(
                                      margin: EdgeInsets.only(top: 10.0),
                                      height: 30,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.indigo,
                                      ),
                                      child: Center(
                                        child: Text("タグを追加する", style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                    ):
                    GestureDetector(
                      onTap: (){
                        Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddTagPage(),
                            )
                        ).then((value){
                          setState(() {
                            _tags = context.read<TagDataProvider>().tagData;
                          });
                        });
                      },
                      child: Container(
                          margin: EdgeInsets.only(top: 10.0),
                          padding: EdgeInsets.all(20.0),
                          width: 340,
                          decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffACACAC), width: 1),
                              borderRadius: BorderRadius.circular(10.0)
                          ),
                          child: Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: [
                              for(int i=0; i<_tags.length; i++)
                                TagPart(title: _tags[i].tagName,)
                            ],
                          )
                      ),
                    ),
                    _buildFormTitle(Icons.image, "メイン画像の登録"),
                    GestureDetector(
                      child: Container(
                        margin: EdgeInsets.only(left: 24.0, top: 10.0, right: 24.0, bottom: 20.0),
                        child: Center(
                          child: Stack(
                            children: [
                              _image == null?
                              Image.network(
                                _imageUrl,
                                height: 150,
                                width: 250,
                                fit: BoxFit.fill,
                              ):
                              Image.file(
                                _image,
                                height: 150,
                                width: 250,
                                fit: BoxFit.fill,
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
                        print("a");
                        _getImageFromGallery();
                      },
                      behavior: HitTestBehavior.translucent,
                    ),
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
                          child: Text("プランを変更中", style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),),
                        )
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
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
