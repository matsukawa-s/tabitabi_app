import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/makeplan/invite_plan_page.dart';
import 'dart:convert';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:tabitabi_app/model/user.dart';
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
import 'package:tabitabi_app/data/comment_data.dart';
import 'package:bubble/bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'share_provider.dart';
import 'impressions_add_page.dart';
import 'package:tabitabi_app/data/review_data.dart';
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
  final _commentFormKey = GlobalKey<FormState>();
  final _getImageKey = GlobalKey<FormState>();

  List<Widget> _tabs = [
    Text("プラン", style: TextStyle(fontSize: 18.0, color: Colors.white)),
    Text("共有", style: TextStyle(fontSize: 18.0, color: Colors.white)),
    Text("感想", style: TextStyle(fontSize: 18.0, color: Colors.white)),
    Text("コメント", style: TextStyle(fontSize: 15.0, color: Colors.white))
  ];

  List<String> _tabsString = ["プラン", "共有", "公開", "感想"];
  
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
  int _cost = 0;

  int userFlag = 0;
  bool favoriteFlag = false;

  TabController _pageTabController;
  TabController _controller;
  TabController _reviewController;

  //行程のリスト
  List<ItineraryData> _itineraries = [];
  //行程スポットのリスト
  List<SpotItineraryData> _spotItineraries = [];
  //行程メモのリスト
  List<MemoItineraryData> _memoItineraries = [];
  //行程交通機関のリスト
  List<TrafficItineraryData> _trafficItineraries = [];
  //アルバムの画像リスト
  List<Widget> _albumImages = [];
  //メンバーリスト
  List members = [];
  //レビュー
  ReviewData _review;


  //コメントのリスト
  List<CommentData> _commentLists = [];
  //ユーザのデータいれる
  var userData;
  //コメントしてるかどうかのフラグ
  bool commentFlag = false;

  //アップロードフラグ
  bool isFileUploading = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    _getPlan();
    _getItiData();

    _pageTabController = TabController(length: 4, vsync: this);
    _controller = TabController(length: 1, vsync: this);
    _reviewController = TabController(length: 1, vsync: this);
    _getPhoto();
    _getMembers();
    _getReviewData();

  }


  Future<int> _getPlan() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('user') ?? '');
    
    userData = json.decode(prefs.getString('user') ?? '');

    http.Response response = await Network().getData("plan/get/" + widget.planId.toString());
    print(response.body);
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
    _cost = list[0]["cost"];
    for(int i=0; i<list[0]["tags"].length; i++){
      _tags.add(TagData(list[0]["tag_id"][i], list[0]["tags"][i]));
      _tagText += "#" + list[0]["tags"][i] + " ";
    }
    userFlag = list[0]["user_flag"];
    print("userFlg:" + userFlag.toString());

    http.Response response2 = await Network().getData("comment/get/" + widget.planId.toString());
    var list2 = json.decode(response2.body);
    print(response2.body);
    for(int i=0; i<list2.length; i++){
      if(list2[i]["email"] == userData["email"]){
        commentFlag = true;
      }
      _commentLists.add(
        CommentData(list2[i]["user_id"], list2[i]["name"], list2[i]["icon_path"], list2[i]["c_contents"])
      );
    }

    if(userFlag == 0){
      _tabsString.removeAt(1);
      _tabs.removeAt(1);
      _pageTabController = _createNewTabController(_tabsString.length);
    }

    setState(() {
      _planDates = _getDateTimeList(_dateTimeFunc(_startDateTime), _dateTimeFunc(_endDateTime));
    });

    print(_planDates.length);

    _getFavorite();

    setState(() {
      _controller = _createNewTabController(_planDates.length);
    });
    return _planDates.length;
  }

  TabController _createNewTabController(int num) => TabController(
    vsync: this,
    length: num,
  );

  void _getFavorite() async{
    http.Response response = await Network().getData("plan/favorite/get");
    print("testgaviri" + response.body);

    var list = json.decode(response.body);
    for(int i=0; i<list.length; i++){
      if(list[i]["id"] == widget.planId){
        favoriteFlag = true;
      }
    }

  }

  Future<void> _getItiData() async{
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

  Future _getReviewData() async{
    http.Response response = await Network().getData("review/get/" + widget.planId.toString());
    print("test" + response.body);
    var list = json.decode(response.body);
    if(response.body == "[]"){
      return null;
    }
    List<String> url = [];
    for(int i=0; i<list[0]["photo_url"].length; i++){
      url.add(list[0]["photo_url"][i]);
    }

    _review = ReviewData(list[0]["r_contents"].toString(), url);
    print(_review.photoPaths);

    _reviewController = _createNewTabController(_review.photoPaths.length);
    setState(() {

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

  //アルバムを取得
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

  void _getMembers() async{
    members.clear();
    http.Response response = await Network().getData('plan/members/${widget.planId.toString()}');
    print(response.body);
    if(response.statusCode == 200){
      final List tmp = json.decode(response.body);
      members = List.generate(
          tmp.length, (index) => User.fromJson(tmp[index])
      );
    }
    print("members----------");
    print(members);
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
              content: Container(
                height: 150.0,
                width: 250.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text("プランを削除しますか?", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),)
                    ),
                    Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: Text("※削除したプランは元に戻りません！", style: TextStyle(color: Colors.red, fontSize: 13.0,fontWeight: FontWeight.bold),)
                    ),
                    Container(
                      height: 40,
                      width: 250,
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
                                child: Text("いいえ", style: TextStyle(color: Colors.white),),
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
                                child: Text("はい", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            onTap: (){
                              flg = true;
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
          actionBarTitle: "画像を選択",
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
    String open = "非公開に";
    if(_isOpen == 0){
      openId = 1;
      open = "公開";
    }
    await showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
              content: Container(
                height: 150.0,
                width: 250.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text("プランを" + open + "しますか", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),)
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 20.0),
                      height: 20.0,
                      width: 250.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 250,
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
                                child: Text("いいえ", style: TextStyle(color: Colors.white),),
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
                                child: Text("はい", style: TextStyle(color: Colors.white),),
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

  //プランコピー
  Future<void> _planCopy() async{
    bool flg = false;
    await showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
              content: Container(
                height: 150.0,
                width: 250.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 30.0),
                      child: Text("プランをコピーしますか?", style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold),)
                    ),
                    Container(
                      height: 50,
                      width: 250,
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
                                child: Text("いいえ", style: TextStyle(color: Colors.white),),
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
                                child: Text("はい", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            onTap: (){
                              flg = true;
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

    if(!flg){
      return null;
    }

    setState(() {
      isFileUploading = true;
      message = "プランをコピー中";
    });

    http.Response res = await Network().getData("plan/copy/" + widget.planId.toString());
    print(res.body);
    int newPlanId = int.parse(res.body);

    setState(() {
      isFileUploading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return MakePlanTop(planId: newPlanId);
        },
      ),
    );
  }

  //コメント追加
  Future<void> _addComment() async{
    String comment;
    bool flg = false;
    //文字入力
    await showDialog(
        context: context,
        builder: (_){
          return AlertDialog(
              title: Text("コメントをする",style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: 100.0,
                      child: Form(
                        key: _commentFormKey,
                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          decoration: InputDecoration(
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
                            comment = value;
                            return null;
                          },
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top:20.0),
                      height: 40,
                      width: 250,
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
                                child: Text("キャンセル", style: TextStyle(color: Colors.white),),
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
                                child: Text("確定", style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            onTap: (){
                              flg = true;
                              if(_commentFormKey.currentState.validate()){
                                flg = true;
                                Navigator.of(context, rootNavigator: true).pop(context);
                              }

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

    if(!flg){
      return null;
    }

    final data = {
      'plan_id' : widget.planId,
      'c_contents' : comment,
    };

    http.Response res = await Network().postData(data, "comment/store");
    print(res.body);
    commentFlag = true;

    setState(() {
      _commentLists.add(
          CommentData(1, userData["name"], userData["icon_path"], comment)
      );
    });


  }

  //お気に入り
  Future<void> _updateFavorite() async{
    var data = {
      'plan_id' : widget.planId,
    };
    // データベースのお気に入りデータを更新
    await Network().postData(data, 'plan/favorite/store');
    setState(() {
      favoriteFlag = !favoriteFlag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: DefaultTabController(
                length: _pageTabController.length,
                child: NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
                    return [
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                        sliver: SliverAppBar(
                          iconTheme: IconThemeData(
                              color: Colors.white
                          ),
                          pinned: true,
                          expandedHeight: 250.0,
                          actions: [
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.white,),
                              onPressed: () async{
                                _pageTabController.animateTo(0, duration: Duration(milliseconds: 1000));
                                ShareProvider().shareImageAndText('アプリ #たびたび で旅行プランを作りました！', _getImageKey);
                              },
                            ),
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
                            constraints: BoxConstraints.expand(height: 300.0),
                            padding: EdgeInsets.only(bottom: 30.0),
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
                                        _buildIconImageInUserTop(_userIconPath, 16.0),
                                        Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(
                                            _userName,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16.0
                                            ),
                                            overflow: TextOverflow.clip
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
                                  padding: EdgeInsets.only(right: 10.0,left: 5.0),
                                  child: Text(
                                      _planName,
                                      style: TextStyle(color: Colors.white, fontSize: 32.0),
                                      maxLines: 2,
                                      overflow: TextOverflow.fade
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 5.0, bottom: 3.0,left: 5.0),
                                  child: Text(
                                      _tagText,
                                      style: TextStyle(color: Colors.white),
                                      maxLines: 2,
                                  ),
                                )
                              ],
                            ),
                          ),
                          bottom: PreferredSize(
                            child: TabBar(
                              tabs: _tabs,
                            ),
                            preferredSize: Size.fromHeight(110.0),
                          ),
                        ),
                      )
                    ];
                  },
                  body: TabBarView(
                    children: [
                      for(int i=0; i<_pageTabController.length; i++)
                        SafeArea(
                          top: false,
                          bottom: false,
                          child: Builder(
                            builder: (BuildContext context){
                              return CustomScrollView(
                                key: PageStorageKey<String>(_tabsString[i]),
                                slivers: [
                                  SliverOverlapInjector(
                                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.all(8.0),
                                    sliver: SliverFixedExtentList(
                                      itemExtent: 600.0,
                                      delegate: SliverChildBuilderDelegate(
                                            (BuildContext context, int index) {
                                          return _buildPage(i);
                                        },
                                        childCount: 1,
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
                        )
                    ],
                  ),
                ),
              )
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
      floatingActionButton: userFlag == 0 ? FloatingActionButton(
        onPressed: (){

        },
        child: GestureDetector(
            child: Icon(
              Icons.favorite, color: favoriteFlag ? Colors.pinkAccent : Colors.white, size: 36,
            ),
            onTap: (){_updateFavorite();},

        ),
      ) : Container(),
    );
  }

  Widget _buildPage(int index){
    Widget page = Container(
      child: Center(child: Text(index.toString()),),
    );
    if(index == 0){
      page = _buildPlan();
    }
    if(index == 1 && userFlag == 1){
      page = _buildMember();
    }
    if(index == 2 || (index == 1 && userFlag == 0)){
      page = _buildImp();
    }
    if(index == 3 || (index == 2 && userFlag == 0)){
      page = _buildComment();
    }
    return page;
  }

  //行程表示
  Widget _buildPlan(){
    return Card(
      margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        //constraints: BoxConstraints.expand(height: 500),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        key: _getImageKey,
                        child: Container(
                          margin: EdgeInsets.only(top: 10.0),
                          height: 600,
                          //width: 500,
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
                if(userFlag == 0)
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(top: 8.0, bottom: 15.0),
                      width: 300.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Colors.orange
                      ),
                      child: Center(
                        child: Text("このプランをコピーする", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    ),
                    onTap: (){
                      _planCopy();
                    },
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  //共有表示(メンバー&アルバム)
  Widget _buildMember(){
    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                _buildTitle("メンバー"),
                Expanded(
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length,
                      itemBuilder: (BuildContext context, int index){
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                                children: [
                                  if(members[index].iconPath != null)
                                    CircleAvatar(
                                      backgroundColor: Colors.black12,
                                      backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + members[index].iconPath),
                                      radius: 24,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.black12,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: LayoutBuilder(builder: (context, constraint) {
                                          return Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            //                                    size: constraint.biggest.height
                                          );
                                        }),
                                      ),
                                    ),
                                  Text(members[index].name,overflow: TextOverflow.ellipsis,)

                                ]
                            ),
                          );
//                        return Padding(
//                          padding: EdgeInsets.all(10.0),
//                          child: Icon(Icons.account_circle, size: 64.0),
//                        );
                      }
                  ),
                ),
//                Expanded(
//                  child: Container(
//                    alignment: Alignment.bottomRight,
//                    margin: EdgeInsets.only(right: 10.0, bottom: 10.0),
//                    child: FloatingActionButton(
//                      heroTag: 'memberAdd',
//                      backgroundColor: Colors.orange,
//                      child: Icon(Icons.add, color: Colors.white,),
//                      onPressed: (){},
//                    ),
//                  ),
//                ),
              ],
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
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
                  height: 240.0,
                  width: MediaQuery.of(context).size.width - 24.0,
                  child: _albumImages.length == 0 ?
                  Container(
                    margin: EdgeInsets.only(left: 24.0, right: 36.0),
                    //color: Colors.black.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("images/scrapb.png",
                          height: 180,
                          width: 180,
                        ),
                        Text("まだ写真はありません！")
                      ],
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
      ],
    );
  }

  //感想表示
  Widget _buildImp(){
    return Column(
      children: [
        Card(
            margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: EdgeInsets.only(left: 20.0,),
              child: Stack(
                children: [
                  //if(_review != null)
                  Container(
                    margin: EdgeInsets.only(right: 20.0),
                    width: MediaQuery.of(context).size.width - 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _review == null ?
                        Container(
                          margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
                          height: 400,
                          width: MediaQuery.of(context).size.width - 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "images/travel06.png",
                                height: 150,
                                width: 150,
                              ),
                              Text("まだ感想はありません！")
                            ],
                          ),
                        ):
                        Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 20.0),
                              height: 300,
                              //color: Colors.black.withOpacity(0.6),
                              child: TabBarView(
                                controller: _reviewController,
                                children: [
                                  for(int i=0; i<_reviewController.length;i++)
                                    Image.network(
                                      _review.photoPaths[i],
                                      fit: BoxFit.fitWidth,
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 10.0,
                              left: 0.0,
                              height: 50.0,
                              width: MediaQuery.of(context).size.width - 64,
                              child: Center(
                                child: TabPageSelector(
                                  controller: _reviewController,
                                ),
                              ),
                            )
                          ],
                        ),
                        if(_review != null)
                        Container(
                          margin: EdgeInsets.only(top: 10.0),
                          height: 100,
                          child: Text(
                            _review.content,
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if(userFlag == 1 && _review == null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      alignment: Alignment.bottomRight,
                      margin: EdgeInsets.only(bottom: 10.0, right: 10.0),
                      child: FloatingActionButton(
                        heroTag: 'memoryAdd',  //これを指定しないと複数FloatingActionButtonが使えない
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.edit, color: Colors.white,),
                        onPressed: () async{
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ImpressionsAddPage(widget.planId),
                              )
                          ).then((value) => _getReviewData());
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
        ),
      ],
    );
  }

  //コメント表示
  Widget _buildComment(){
    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(left: 12.0, top: 20.0, right: 12.0,),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: BoxConstraints.expand(height: userFlag == 0 ? 450 : 405),
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitle("コメント"),
                Container(
                    height: 320,
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.only(top: 20.0),
                    color: Colors.white,
                    child: _commentLists.length == 0 ?
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "images/bunbougu03.png",
                          height: 150.0,
                          width: 150.0,
                        ),
                        Text("まだコメントはありません"),
                      ],
                    ):
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          for(int i=0; i<_commentLists.length; i++)
                            Padding(
                              padding: EdgeInsets.only(bottom: 20.0),
                              child: _buildCommentPart(_commentLists[i], MediaQuery.of(context).size.width - 90,),
                            )
                        ],
                      ),
                    )
                ),
                if(userFlag == 0)
                  GestureDetector(
                    child: Container(
                      margin: EdgeInsets.only(top: 12.0, bottom: 8.0),
                      width: 300.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: commentFlag ? Colors.grey : Colors.orange
                      ),
                      child: Center(
                        child: Text(commentFlag ? "コメントありがとうございました！" :"コメントをする", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    ),
                    onTap: (){
                      _addComment();
                    },
                  )
              ],
            ),
          ),
        ),
      ],
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
              //color: Colors.black.withOpacity(0.2),
              width: MediaQuery.of(context).size.width,
              height: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/illustrain02-travel04.png",
                    width: 150,
                    height: 150,
                  ),
                  Text("まだ予定はありません！"),
                ],
              ),
            )
        ],
      ),
    );
  }

  //コメントWidget
  Widget _buildCommentPart(CommentData commentData, double width){
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconImageInUserTop(commentData.userPath, width/12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 30.0),
                child: Text(commentData.userName),
              ),
              Container(
                margin: EdgeInsets.only(left: 20.0),
                width: width - width / 6 - 10,
                child: Bubble(
                  margin: BubbleEdges.only(top: 10),
                  nip: BubbleNip.leftTop,
                  child: Text(commentData.contents),
                ),
              )
            ],
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

  Widget _buildIconImageInUserTop(String iconPath, double size){
    final double iconSize = size;
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
