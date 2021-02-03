import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/map.dart';

class MapSearchPage extends StatefulWidget {
  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  TextEditingController _searchKeywordController = TextEditingController();
  final kGoogleApiKey = DotEnv().env['Google_API_KEY'];
  List<PlacesSearchResult> items = [];
  var focusNode = new FocusNode(); //検索バーのフォーカス制御用
  MapViewModel mapModel;
  var history = {};
  bool isHistoryOrSearch; // true:検索履歴表示,false:検索結果表示


  @override
  void initState() {
    super.initState();
//    FocusScope.of(context).requestFocus(focusNode);
    isHistoryOrSearch = false;
    //Mapモデル作成し、コントローラーを監視する
    mapModel = Provider.of<MapViewModel>(context,listen: false);
    _searchKeywordController = TextEditingController(text: mapModel.getSearchText());
  }

  Future<bool> getHistory() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('history')) {
      history = jsonDecode(prefs.getString('history'));
      history = LinkedHashMap.fromEntries(history.entries.toList().reversed);
    }
    return true;
  }

  @override
  void dispose() {
    _searchKeywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        body: FutureBuilder(
          future: getHistory(),
          builder: (context, snapshot) {
            if(snapshot.hasData){
              return SafeArea(
                child: Container(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 16,left: 8,right: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(90)
                        ),
                        child: TextField(
                          focusNode: focusNode,
                          autofocus: true,
                          onSubmitted: (String str) => searchPlaces(''),
                          controller: _searchKeywordController,
                          style: TextStyle(
                              fontSize: 18
                          ),
                          decoration: InputDecoration(
                            prefixIcon: IconButton(
                              icon: Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                Navigator.pop(context);
                                FocusScope.of(context).unfocus(); //キーボード閉じる
                              },
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: (){
                                _searchKeywordController.clear();
                                mapModel.searchPlacesTextUpdate('');
                              },
                            ),
                            hintText: '検索',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      _buildHistorySearchResultArea(),
                    ],
                  ),
                ),
              );
            }else{
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
        ),
      ),
    );
  }

  Widget _buildHistorySearchResultArea(){
    if(isHistoryOrSearch){
      //検索結果を表示する
      return Expanded(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (BuildContext context,int index){
              return ListTile(
                title: Text(items[index].name),
                subtitle: Text(items[index].formattedAddress),
                onTap: () => onTapPlace(items[index].placeId),
              );
            }
        ),
      );
    }else if(!isHistoryOrSearch && history.isNotEmpty){
      //検索履歴を表示する
      return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  margin: EdgeInsets.only(left: 16.0,top: 4.0),
                  child: Text(
                    "過去に見たスポット",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
              ),
              Flexible(
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (BuildContext context,int index){
                      String key = history.keys.elementAt(index);
                      return ListTile(
                        title: Text(history[key]),
                        leading: Icon(Icons.history),
                        onTap: (){
                            Navigator.pop(context,key);
//                          searchPlaces(key);
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => deleteHistoryItem(key)
                        ),
                      );
                    }
                ),
              ),
            ],
          )
      );
    }else{
      //検索履歴がないとき
      return Container();
    }
  }

// Google Places APIを叩いて場所を検索する
  Future<void> searchPlaces(String historyKeyword) async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
    List<PlacesSearchResponse> places = [];

    //検索履歴をタップして検索したとき
    if(historyKeyword != ''){
      _searchKeywordController.text = historyKeyword;
    }

    if(_searchKeywordController.text.isNotEmpty){
      print(_searchKeywordController.text.toString());
      PlacesSearchResponse res =
          await _places.searchByText(_searchKeywordController.text.toString(),language: "ja");

      if(res.status == "OK"){
        setState(() {
          items = res.results;
          //表示を切り替えて検索結果を表示する
          isHistoryOrSearch = true;
        });
      }else{
        print("error");
      }
    }
  }

//  地図画面に選択した場所を戻す
  void onTapPlace(placeId){
    Navigator.pop(context,placeId);
  }

//  過去に見たスポットのアイテムひとつを削除する
  deleteHistoryItem(key) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    history = jsonDecode(prefs.getString('history'));
    history.remove(key);
    prefs.setString('history', jsonEncode(history));
    setState(() { });
  }

}
