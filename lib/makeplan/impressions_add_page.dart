import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:tabitabi_app/network_utils/aws_s3.dart';

class ImpressionsAddPage extends StatefulWidget {
  final int planId;

  ImpressionsAddPage(
      this.planId
  );
  @override
  _ImpressionsAddPageState createState() => _ImpressionsAddPageState();
}

class _ImpressionsAddPageState extends State<ImpressionsAddPage> with TickerProviderStateMixin{
  final _formKey = GlobalKey<FormState>();

  TabController _tabController;

  String _content;
  int _cost;
  List<String> _images = [];
  List<Asset> _imagesAsset = [];

  bool _imageErrorFlag = false;
  bool isFileUploading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);

  }

  TabController _createNewTabController() => TabController(
    vsync: this,
    length: _images.length,
  );

  //保存処理
  Future<void> _saveImp() async{
    if(!_formKey.currentState.validate()){
      return null;
    }
    if(_images.length == 0){
      _imageErrorFlag = true;
      setState(() {

      });
      return null;
    }else{
      _imageErrorFlag = false;
    }

    setState(() {
      isFileUploading = true;
    });

    //画像をアップロード
    List<String> uploadPaths = [];
    for(int i=0; i<_images.length; i++){
      var uploadPath = await AwsS3().uploadImage(_images[i], "review/"+ widget.planId.toString());
      uploadPaths.add(uploadPath);
    }

    final data = {
      'plan_id' : widget.planId,
      'r_contents' : _content,
      'image_urls' : uploadPaths,
      'cost' : _cost
    };

    http.Response res = await Network().postData(data, "review/store");
    print(res.body);

    Navigator.of(context).pop();
  }

  //画像追加処理
  Future<void> _addImage() async{
    List<Asset> resultList = List<Asset>();

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
        selectedAssets: _imagesAsset,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      print(e.toString());
    }

    if (!mounted) return;

    if(resultList.isEmpty){
      return null;
    }

    _images.clear();

    _imagesAsset = resultList;
    resultList.forEach((element) async{
      var path = await FlutterAbsolutePath.getAbsolutePath(element.identifier);
      _images.add(path);

      _tabController = _createNewTabController();
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("感想"),
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
                  await _saveImp();
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
              padding: EdgeInsets.only(left: 16.0, right: 16.0),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      //写真
                      _buildFormTitle(Icons.image_outlined, "写真"),
                      Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        height: 250,
                        width: MediaQuery.of(context).size.width - 50,
                        color: Colors.black.withOpacity(0.2),
                        child: _images.length == 0 ?
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              child: Center(
                                child: Text("思い出の写真を選ぼう！"),
                              ),
                            ),
                            onTap: (){
                              _addImage();
                            },
                          ):
                          TabBarView(
                          controller: _tabController,
                          children: [
                            for(int i=0; i<_images.length; i++)
                              Image.asset(
                                _images[i],
                                fit: BoxFit.fitHeight,
                              )
                          ],
                        ),
                      ),
                      if(_images.length != 0)
                      Container(
                        child: TabPageSelector(
                          controller: _tabController,
                        ),
                      ),
                      if(_images.length != 0)
                      GestureDetector(
                        child: Container(
                          height: 50.0,
                          width: MediaQuery.of(context).size.width - 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Theme.of(context).primaryColor
                          ),
                          child: Center(
                            child: Text("写真を変更する", style: TextStyle(color: Colors.white),),
                          ),
                        ),
                        onTap: (){
                          _addImage();
                        },
                      ),
                      if(_imageErrorFlag)
                        Text("画像を選択してください", style: TextStyle(color: Colors.red),),
                      //内容
                      _buildFormTitle(Icons.edit, "内容"),
                      Container(
                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "旅行の思い出を書こう！",
                            labelStyle: TextStyle(color:Color(0xffACACAC),),
                            focusColor: Theme.of(context).primaryColor,
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
                              return 'コメントを入力してください';
                            }
                            _content = value;
                            return null;
                          },
                        ),
                      ),
                      //コスト　
                      _buildFormTitle(Icons.monetization_on_outlined, "費用"),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "おおよその金額",
                                labelStyle: TextStyle(color:Color(0xffACACAC),),
                                focusColor: Theme.of(context).primaryColor,
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
                                  return '金額を入力してください';
                                }
                                if(value == 0.toString()){
                                  return '0より大きい値を入力してください';
                                }
                                _cost= int.parse(value);
                                return null;
                              },
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 10.0),
                            child: Text("円", style: TextStyle(fontSize: 22.0),),
                          )
                        ],
                      ),
                      Container(height: 100,)
                    ],
                  ),
                ),
              ),
            ),
            if(isFileUploading == true)
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
                          child: Text("画像アップロード中", style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),),
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
      margin: EdgeInsets.only(top: 10.0,bottom: 5.0),
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
