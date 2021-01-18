import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/makeplan/invite_plan_page.dart';
import 'dart:convert';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'makeplan_edit_page.dart';
import 'package:tabitabi_app/data/itinerary_data.dart';
import 'package:tabitabi_app/data/itinerary_part_data.dart';
import 'package:tabitabi_app/components/makeplan_edit_traffic_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_plan_part.dart';
import 'package:tabitabi_app/components/makeplan_edit_memo_part.dart';
import 'package:tabitabi_app/network_utils/aws_s3.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'package:tabitabi_app/makeplan/plan_info_edit_page.dart';
import 'package:tabitabi_app/data/tag_data.dart';
import 'dart:io';

enum WhyFarther { EditPlan, OpenPlan, JoinPlan, DeletePlan }

class MakePlanTop extends StatefulWidget {

  final int planId;

  MakePlanTop({
    Key key,
    this.planId,
  }):super(key: key);

  @override
  _MakePlanTopState createState() => _MakePlanTopState();
}

class _MakePlanTopState extends State<MakePlanTop> with TickerProviderStateMixin{
  var plans;

  String _planName = "";
  String _imageUrl = "";
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now();
  List<DateTime> _planDates = [DateTime.now()];
  String _userName = "";
  String _userIconPath;
  List<TagData> _tags = [];
  String _tagText = "";
  int _isOpen = 0;

  int userFlag = 0;

  TabController _controller;

  //行程のリスト
  List<ItineraryData> _itineraries = [];
  //行程スポットのリスト
  List<SpotItineraryData> _spotItineraries = [];
  //行程メモのリスト
  List<MemoItineraryData> _memoItineraries = [];
  //行程交通機関のリスト
  List<TrafficItineraryData> _trafficItineraries = [];

  List<Asset> _images = [];

  //アルバムの画像リスト
  List<Widget> _albumImages = [];

  //アップロードフラグ
  bool isFileUploading = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    _getPlan();
    _getItiData();

    _controller = TabController(length: 1, vsync: this);
    _getPhoto();
  }

  Future<int> _getPlan() async{
    http.Response response = await Network().getData("plan/get/" + widget.planId.toString());
    //print(response.body);
    var list = json.decode(response.body);
    print(list);
    plans = list[0];
    _tagText = "";
    _tags.clear();

    setState(() {
      _planName = list[0]["title"];
      //_planDetail = list[0]["description"] == null ? "" : list[0]["description"];
    });
    _startDateTime = DateTime.parse(list[0]["start_day"]);
    _endDateTime = DateTime.parse(list[0]["end_day"]);
    _imageUrl = list[0]["image_url"];
    _userName = list[0]["user_name"];
    _userIconPath = list[0]["user_icon_path"];
    _isOpen = list[0]["is_open"];
    for(int i=0; i<list[0]["tags"].length; i++){
      _tags.add(TagData(list[0]["tag_id"][i], list[0]["tags"][i]));
      _tagText += "#" + list[0]["tags"][i] + " ";
    }
    userFlag = list[0]["user_flag"];
    print("userFlg:" + userFlag.toString());

    setState(() {
      _planDates = _getDateTimeList(_dateTimeFunc(_startDateTime), _dateTimeFunc(_endDateTime));
    });

    print(_planDates.length);

    setState(() {
      _controller = _createNewTabController();
    });
    return _planDates.length;

  }

  TabController _createNewTabController() => TabController(
    vsync: this,
    length: _planDates.length,
  );

  void _getItiData() async{
    _itineraries.clear();
    _spotItineraries.clear();
    _trafficItineraries.clear();
    _memoItineraries.clear();
    //行程データ取得
    http.Response response = await Network().getData("itinerary/get/" + widget.planId.toString());
    List<dynamic> list = json.decode(response.body);
    List<int> ids = [];
    for(int i=0; i<list.length; i++){

      DateTime date = DateTime.parse(list[i]["day"]);
      _itineraries.add(ItineraryData(list[i]["id"], list[i]["itinerary_order"], list[i]["spot_order"], list[i]["plan_id"], date, false));
      ids.add(list[i]["id"]);

      print(list[i]["id"].toString());
    }

    final data = {
      "ids" : ids,
    };

    //List<String> id = [];
    http.Response responseSpot = await Network().postData(data, "itinerary/get/spot");
    print(responseSpot.body);
    List list2 = json.decode(responseSpot.body);
    for(int i=0; i<list2.length; i++){
      DateTime startDate = list2[i]["start_date"] == null ? null :DateTime.parse(list2[i]["start_date"]);
      DateTime endDate = list2[i]["end_date"] == null ? null :DateTime.parse(list2[i]["end_date"]);
      _spotItineraries.add(SpotItineraryData(list2[i]["id"], list2[i]["itinerary_id"], list2[i]["spot_id"], list2[i]["spot_name"], list2[i]["latitube"], list2[i]["longitube"], list2[i]["image_url"], startDate , endDate, 0));
      // print(_spotItineraries[i].spotName);
    }

    http.Response responseTraffic = await Network().postData(data, "itinerary/get/traffic");
    List list3 = json.decode(responseTraffic.body);
    for(int i=0; i<list3.length; i++){
      _trafficItineraries.add(TrafficItineraryData(list3[i]["id"], list3[i]["itinerary_id"], list3[i]["traffic_class"], list3[i]["travel_time"], list3[i]["traffic_cost"]));
    }

    http.Response responseMemo = await Network().postData(data, "itinerary/get/note");
    List list4 = json.decode(responseMemo.body);
    for(int i=0; i<list4.length; i++){
      _memoItineraries.add(MemoItineraryData(list4[i]["id"], list4[i]['itinerary_id'], list4[i]['memo']));
    }

    setState(() {
      _itineraries.sort((a,b) => a.itineraryOrder.compareTo(b.itineraryOrder));
    });
  }

  //日付のリストを作る
  List<DateTime> _getDateTimeList(DateTime startDate, DateTime endDate){
    List<DateTime> dateList = [];
    print("aa");

    //1日だけのとき
    if(startDate == endDate){
      dateList.add(startDate);
      return dateList;
    }

    //2日以上あるとき
    DateTime date = startDate;
    DateTime lastDate = DateTime(endDate.year, endDate.month, endDate.day+1);
    while(date != lastDate){
      dateList.add(date);
      date = DateTime(date.year, date.month, date.day+1);
    }

    return dateList;
  }

  //画像を取得
  void _getPhoto() async{
    _albumImages.clear();

    http.Response response = await Network().getData("photo/get/" + widget.planId.toString());
    List list = json.decode(response.body);
    for(int i=0; i<list.length; i++){
      _albumImages.add(_photoItem(list[i]["id"], list[i]["photo_url"], i));
    }

    setState(() {

    });

  }

  DateTime _dateTimeFunc(DateTime date){
    return DateTime(date.year, date.month, date.day);
  }

  //プラン削除処理
  Future<void> _deletePlan() async{
    bool flg = false;
    //確認ダイアログ表示
    await showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("確認"),
            content: Text("プランを削除してよろしいですか？"),
            actions: [
              FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
              ),
              FlatButton(
                  child: Text("OK"),
                  onPressed: (){
                    flg = true;
                    Navigator.of(context, rootNavigator: true).pop(context);
                  }
              ),
            ],
          );
        }
    );

    //いいえのとき
    if(!flg){
      return null;
    }

    //プランを削除
    setState(() {
      message = "プランを削除しています";
      isFileUploading = true;
    });

    http.Response response = await Network().getData("plan/delete/" + widget.planId.toString());

    print(response.body);

    Navigator.of(context).pop();
  }

  //アルバム画像追加処理
  Future<void> _addAlbum() async{
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    //image選択
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        //selectedAssets: _images,
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
      error = e.toString();
    }

    if (!mounted) return;

    if(resultList.isEmpty){
      print("ee");
      return null;
    }

    //選択した画像をアップロード
    setState(() {
      message = "画像をアップロードしています";
      isFileUploading = true;
    });

    //保存先のパス
    List<String> uploadPaths = [];

    for(int i=0; i<resultList.length; i++){
      var path = await FlutterAbsolutePath.getAbsolutePath(resultList[i].identifier);

      var uploadPath = await AwsS3().uploadImage(path, "album/"+ widget.planId.toString());
      uploadPaths.add(uploadPath);
    }

    final data = {
      "urls" : uploadPaths,
      "plan_id" : widget.planId,
    };

    http.Response res = await Network().postData(data, "photo/store");
    print(res.body);

    _getPhoto();

    setState(() {
      isFileUploading = false;
    });
  }

  //アルバム画像保存処理
  Future<void> _saveAlbum(int id, String imagePath) async{
    //選択した画像をアップロード
    setState(() {
      message = "画像を保存しています";
      isFileUploading = true;
    });
    Uint8List buffer = (await NetworkAssetBundle(Uri.parse(imagePath)).load(imagePath)).buffer.asUint8List();
    final result = await ImageGallerySaver.saveImage(buffer);
    print(result);
    setState(() {
      isFileUploading = false;
    });
  }

  //アルバム削除処理
  Future<void> _deleteAlbum(int id, String imageUrl, int index) async{
    bool flg = false;
    //確認ダイアログ表示
    await showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          title: Text("確認"),
          content: Text("選択した画像を削除していいですか？"),
          actions: [
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
            ),
            FlatButton(
              child: Text("OK"),
              onPressed: (){
                flg = true;
                Navigator.of(context, rootNavigator: true).pop(context);
              }
            ),
          ],
        );
      }
    );

    //いいえのとき
    if(!flg){
      return null;
    }

    //選択した画像を削除
    setState(() {
      message = "画像を削除しています";
      isFileUploading = true;
    });

    String result = await AwsS3().deleteImage(imageUrl);
    print(result);

    http.Response response = await Network().getData("photo/delete/" + id.toString());
    print(response.body);

    //リストから削除
    _albumImages.removeAt(index);
    setState(() {
      isFileUploading = false;
    });
  }

  //公開設定確認ダイアログ
  Future<void> _showOpenDialog() async{
    int openId = 0;
    if(_isOpen == 0){
      openId = 1;
    }
    await showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("確認"),
            content: Container(
              height: 100.0,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text("公開設定を変更しますか？"),
                  ),
                  Row(
                    children: [
                      Text("現在の公開設定："),
                      Container(
                          height: 10.0,
                          width: 10.0,
                          decoration: BoxDecoration(
                              color: _isOpen == 0 ? Colors.grey : Colors.greenAccent,
                              shape: BoxShape.circle
                          )
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0),
                        child: Text(
                          _isOpen == 0 ? "非公開" : "公開中",
                          style: TextStyle(
                              fontSize: 14.0
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(context),
              ),
              FlatButton(
                  child: Text("OK"),
                  onPressed: (){
                    _updateIsOpenPlan(openId);
                    Navigator.of(context, rootNavigator: true).pop(context);
                  }
              ),
            ],
          );
        }
    );
  }

  //帰ってきたときに表示するダイアログ
  Future<void> _showDialog() async{
    int openId = 0;
    if(_isOpen == 0){
      openId = 1;
    }
    await showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            content: Container(
              height: 200.0,
              width: 250.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("プランを公開しよう！", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),),
                  Image.asset(
                    "images/travel05.png",
                    height: 100,
                    width: 100,
                    fit: BoxFit.fitHeight,
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                            height: 40.0,
                            width: 100.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              color: Colors.grey,
                            ),
                            child: Center(
                              child: Text("公開しない", style: TextStyle(color: Colors.white),),
                            ),
                          ),
                          onTap: (){
                            Navigator.of(context, rootNavigator: true).pop(context);
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.only(left: 10.0),
                            height: 40.0,
                            width: 100.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              color: Colors.orange,
                            ),
                            child: Center(
                              child: Text("公開する", style: TextStyle(color: Colors.white),),
                            ),
                          ),
                          onTap: (){
                            _updateIsOpenPlan(openId);
                            Navigator.of(context, rootNavigator: true).pop(context);
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0)))
          );
        }
    );
  }
  //公開設定変更
  Future<void> _updateIsOpenPlan(int open) async{
    final data = {
      "id" : widget.planId,
      "is_open" : open,
    };

    http.Response res = await Network().postData(data, "plan/update/open");
    print(res.body);

    setState(() {
      _isOpen = open;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('トップ'),
      // ),
      resizeToAvoidBottomInset : false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/paper_00108.jpg"),
                  //colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.3), BlendMode.color),
                  fit: BoxFit.cover
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200.0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white,),
                      onPressed: (){},
                    ),
//                IconButton(
//                  icon: Icon(Icons.more_vert, color: Colors.white,),
//                  onPressed: (){},
//                ),
                    if(userFlag == 1)
                    PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.white,),
                        onSelected: (WhyFarther result) {
                          switch(result){
                            case WhyFarther.EditPlan:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return PlanInfoEditPage(widget.planId, _planName, _tags, _startDateTime, _endDateTime, _imageUrl);
                                  },
                                ),
                              ).then((value){
                                _getPlan();
                              });
                              break;
                            case WhyFarther.OpenPlan:
                              _showOpenDialog();
                              break;
                            case WhyFarther.JoinPlan:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return InvitePlanPage(plans);
                                  },
                                ),
                              );
                              break;
                            case WhyFarther.DeletePlan:
                              _deletePlan();
                              break;

                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<WhyFarther>>[
                          const PopupMenuItem<WhyFarther>(
                            value: WhyFarther.EditPlan,
                            child: Text('プラン情報の編集'),
                          ),
                          const PopupMenuItem<WhyFarther>(
                            value: WhyFarther.OpenPlan,
                            child: Text('プランの公開設定'),
                          ),
                          const PopupMenuItem<WhyFarther>(
                            value: WhyFarther.JoinPlan,
                            child: Text('プラン招待コード'),
                          ),
                          const PopupMenuItem<WhyFarther>(
                            value: WhyFarther.DeletePlan,
                            child: Text('プランを削除する'),
                          ),
                        ]
                    ),
                  ],
                  flexibleSpace: Container(
                    constraints: BoxConstraints.expand(height: 250.0),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _imageUrl == null ? AssetImage("images/2304099_m.jpg") : NetworkImage(_imageUrl),
                        //image: NetworkImage("https://picsum.photos/1500/800"),
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if(userFlag == 0)
                        Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildIconImageInUserTop(_userIconPath),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text(
                                  _userName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        if(userFlag == 1)
                          Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 10.0,
                                  width: 10.0,
                                  decoration: BoxDecoration(
                                    color: _isOpen == 0 ? Colors.grey : Colors.greenAccent,
                                    shape: BoxShape.circle
                                  )
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 5.0),
                                  child: Text(
                                    _isOpen == 0 ? "非公開" : "公開中",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.0
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: Text(_planName, style: TextStyle(color: Colors.white, fontSize: 32.0)),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 5.0, bottom: 3.0),
                          child: Text(_tagText, style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                  bottom: PreferredSize(child: Text("", style: TextStyle(color: Colors.white)), preferredSize: Size.fromHeight(75.0),),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //スケジュール
                        Card(
                          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            constraints: BoxConstraints.expand(height: 500),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 10.0),
                                            height: 400,
                                            width: 500,
                                            child: TabBarView(
                                              controller: _controller,
                                              children: [
                                                for(int i=0; i<_planDates.length; i++)
                                                  SingleChildScrollView(
                                                    child: _buildSchedule("1", _planDates[i]),
                                                  )
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                              bottom: 0.0,
                                              left: 0.0,
                                              right: 0.0,
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: TabPageSelector(
                                                  controller: _controller,
                                                ),
                                              )
                                          ),
                                          Positioned(
                                            top: 0.0,
                                            bottom: 0.0,
                                            left: -30.0,
                                            child: IconButton(
                                              icon: Icon(Icons.chevron_left),
                                              iconSize: 80.0,
                                              color: Colors.orange,
                                              onPressed: (){
                                                if(!(_controller.index == 0)){
                                                  _controller.animateTo(_controller.index - 1);
                                                }
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: 0.0,
                                            bottom: 0.0,
                                            right: -30,
                                            child: IconButton(
                                              icon: Icon(Icons.chevron_right),
                                              iconSize: 80.0,
                                              color: Colors.orange,
                                              onPressed: (){
                                                if(!(_controller.index == _planDates.length)){
                                                  _controller.animateTo(_controller.index + 1);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if(userFlag == 1)
                                    Container(
                                      alignment: Alignment.bottomRight,
                                      margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                      child: FloatingActionButton(
                                        heroTag: 'planEdit',
                                        backgroundColor: Colors.orange,
                                        child: Icon(Icons.edit, color: Colors.white,),
                                        onPressed: (){
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => MakePlanEdit(planId: widget.planId, startDateTime: _dateTimeFunc(_startDateTime), endDateTime: _dateTimeFunc(_endDateTime),),
                                              )
                                          ).then((value){
                                            setState(() {
                                              _getPlan();
                                              _getItiData();
                                            });
                                            if(_isOpen==0){
                                              _showDialog();
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        //メンバー
                        if(userFlag == 1)
                        Card(
                          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            constraints: BoxConstraints.expand(height: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildTitle("メンバー"),
                                Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Icon(Icons.account_circle, size: 64.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Icon(Icons.account_circle, size: 64.0),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Icon(Icons.account_circle, size: 64.0),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.bottomRight,
                                    margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                    child: FloatingActionButton(
                                      heroTag: 'memberAdd',
                                      backgroundColor: Colors.orange,
                                      child: Icon(Icons.add, color: Colors.white,),
                                      onPressed: (){},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //アルバム
                        if(userFlag == 1)
                        Card(
                          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0, bottom: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            constraints: BoxConstraints.expand(height: 350),
                            child: Stack(
                              children: [
                                Container(
                                  height: 50.0,
                                  width: MediaQuery.of(context).size.width,
                                  child: Center(
                                    child: _buildTitle("アルバム"),
                                  ),
                                ),
                                Positioned(
                                  top: 50.0,
                                  left: 0,
                                  height: 280.0,
                                  width: MediaQuery.of(context).size.width - 24.0,
                                  child: _albumImages.length == 0 ?
                                      Container(
                                        margin: EdgeInsets.only(left: 24.0, right: 24.0),
                                        color: Colors.black.withOpacity(0.2),
                                        child: Center(
                                          child: Text("まだ写真はありません！"),
                                        ),
                                      )
                                      : Container(
                                        child: GridView.builder(
                                          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                          ),
                                          itemCount: _albumImages.length,
                                          itemBuilder: (context, index){
                                            return _albumImages[index];
                                          }
                                        )
                                      ),
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
                                  child: FloatingActionButton(
                                    heroTag: 'albumAdd',  //これを指定しないと複数FloatingActionButtonが使えない
                                    backgroundColor: Colors.orange,
                                    child: Icon(Icons.add, color: Colors.white,),
                                    onPressed: () async{
                                      _addAlbum();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if(userFlag == 0)
                          //コメント
                          Card(
                            margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Container(
                              constraints: BoxConstraints.expand(height: 200),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildTitle("コメント"),

                                ],
                              ),
                            ),
                          ),
                        Container(
                          height: 100,
                        )
                      ],
                    ),
                  ]),
                ),
              ],
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
                        child: Text(message, style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),),
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

  //各項目のタイトル
  Widget _buildTitle(String title){
    return Padding(
      padding: EdgeInsets.only(top: 15.0),
      child: Text(title , style: TextStyle(fontSize: 18.0)),
    );
  }

  //各日程のスケジュール
  Widget _buildSchedule(String test, DateTime date){
    return Container(
      margin: EdgeInsets.only(left: 16.0, top: 5.0, right: 16.0),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(date.month.toString() + "/" + date.day.toString(), style: TextStyle(fontSize: 18.0),),
          ),
          for(int i=0; i<_itineraries.length; i++)
            if(_itineraries[i].itineraryDateTime == date)
            Container(
              margin: EdgeInsets.only(top: 14.0, left: 10.0),
              child: _buildPlanPart(_itineraries[i].itineraryID, _itineraries[i].spotOrder),
            ),
          if(_itineraries.length == 0 || _itineraries.indexWhere((element) => element.itineraryDateTime == date) == -1)
            Container(
              margin: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0, bottom: 20.0),
              color: Colors.black.withOpacity(0.2),
              width: MediaQuery.of(context).size.width,
              height: 350,
              child: Center(
                child: Text("まだ予定はありません！"),
              ),
            )
        ],
      ),
    );
  }

  //行程のパーツを返すWidget
  Widget _buildPlanPart(int id, int order){
    Widget part = Container();

    int itinerariesType = -1;  //0:スポット　1:メモ　2:交通
    int index = -1;

    //スポット・メモ・交通から、行程IDと一致するものを探す
    for(int i=0; i<_spotItineraries.length; i++){
      if(_spotItineraries[i].itineraryId == id){
        itinerariesType = 0;
        index = i;
        break;
      }
    }
    if(itinerariesType == -1){
      for(int i=0; i<_trafficItineraries.length; i++){
        if(_trafficItineraries[i].itineraryId == id){
          itinerariesType = 1;
          index = i;
          break;
        }
      }
    }
    if(itinerariesType == -1){
      for(int i=0; i<_memoItineraries.length; i++){
        if(_memoItineraries[i].itineraryId == id){
          itinerariesType = 2;
          index = i;
          break;
        }
      }
    }

    switch (itinerariesType){
      case 0 :
        part = PlanPart(
          number: order,
          id: _spotItineraries[index].id,
          spotName: _spotItineraries[index].spotName,
          spotPath: _spotItineraries[index].spotImagePath,
          spotStartDateTime: _spotItineraries[index].spotStartDateTime,
          spotEndDateTime: _spotItineraries[index].spotEndDateTime,
          spotParentFlag: _spotItineraries[index].parentFlag,
          confirmFlag: true,
          width: MediaQuery.of(context).size.width - 60,
          flg: false,
          day: DateTime.now(),
        );
        break;
      case 1 :
        part = TrafficPart(
          trafficType: _trafficItineraries[index].trafficClass,
          minutes: _trafficItineraries[index].travelTime,
          confirmFlag: true,
          flg: false,
        );
        break;
      case 2 :
        part = MemoPart(
          memoString: _memoItineraries[index].memo,
          confirmFlag: true,
        );
    }
    return part;
  }

  Widget _buildIconImageInUserTop(String iconPath){
    final double iconSize = 15.0;
    if(iconPath == null){
      return CircleAvatar(
        backgroundColor: Colors.grey,
        radius: iconSize,
      );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + iconPath),
      );
    }
  }

  Widget _photoItem(int id, String imagePath, int index) {
    //var assetsImage = "assets/img/" + image + ".png";
    return GestureDetector(
      child: Container(
        child: Image.network(imagePath, fit: BoxFit.cover,),
      ),
      onTap: () async{
        await _showPictureDialog(id, imagePath, index);
      },
    );
  }

  _showPictureDialog (int id, String imagePath, int index) async{
    await showDialog(
      context: context,
      builder: (context){
        return StatefulBuilder(
          builder: (_, setState){
            return SimpleDialog(
              backgroundColor: Colors.black,
              children: [
                Stack(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height / 2,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        image: DecorationImage(
                          image: NetworkImage(imagePath),
                          fit: BoxFit.fitWidth
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 10.0,
                      height: 30.0,
                      width: 30.0,
                      child: GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          child: Center(
                            child: Icon(Icons.clear),
                          ),
                        ),
                        onTap: (){
                          Navigator.of(context, rootNavigator: true).pop(context);
                        },
                      ),
                    ),
                    //ボタン
                    Positioned(
                      bottom: 0,
                      left: 0,
                      width: MediaQuery.of(context).size.width - MediaQuery.of(context).size.width/4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            child: Container(
                                height: 35.0,
                                width: 80.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.white),
                                  color: Colors.black.withOpacity(0.5)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white, size: 20.0,),
                                    Text("削除", style: TextStyle(color: Colors.white),)
                                  ],
                                )
                            ),
                            onTap: () async{
                              Navigator.of(context, rootNavigator: true).pop(context);
                              await _deleteAlbum(id, imagePath, index);
                            },
                          ),
                          GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(left: 10.0),
                              height: 35.0,
                              width: 80.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Colors.white),
                                color: Colors.black.withOpacity(0.5)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_rounded, color: Colors.white, size: 20.0,),
                                  Text("保存", style: TextStyle(color: Colors.white),)
                                ],
                              )
                            ),
                            onTap: (){
                              Navigator.of(context, rootNavigator: true).pop(context);
                              _saveAlbum(id, imagePath);
                            },
                          )
                        ],
                      )
                    )
                  ],
                ),
              ],
            );
          }
        );
      }
    );
  }
}

