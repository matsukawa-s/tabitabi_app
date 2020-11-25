import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

import 'model/map.dart';

class MapSearchPage extends StatefulWidget {
  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  TextEditingController _searchKeywordController = TextEditingController();
  final kGoogleApiKey = "AIzaSyC2VCSOjFsBo9sPArzQde0aN_R5ZU8Rt0w";
  List items = [];
  var focusNode = new FocusNode(); //検索バーのフォーカス制御用
  MapViewModel mapModel;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    FocusScope.of(context).requestFocus(focusNode);
    //Mapモデル作成し、コントローラーを監視する
    mapModel = Provider.of<MapViewModel>(context,listen: false);
    _searchKeywordController = TextEditingController(text: mapModel.getSearchText());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _searchKeywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                  onSubmitted: (String str) => searchPlaces(),
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
              Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (BuildContext context,int index){
                      return ListTile(
                        title: Text(items[index].name),
                        onTap: () => onTapPlace(items[index].placeId),
                      );
                    }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

// Google Places APIを叩いて場所を検索する
  Future<void> searchPlaces() async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
    List<PlacesSearchResponse> places = [];

    if(_searchKeywordController.text.isNotEmpty){
      print(_searchKeywordController.text.toString());
      PlacesSearchResponse res =
          await _places.searchByText(_searchKeywordController.text.toString(),language: "ja");
//      PlacesAutocompleteResponse res =
//        await _places.autocomplete(_keyWordController.text.toString(),language: "ja");

      if(res.status == "OK"){
        setState(() {
          items = res.results;
        });
        print("items.length : ${items.length.toString()}");
      }

    }
  }

//  地図画面に選択した場所を戻す
  void onTapPlace(placeId){
    Navigator.pop(context,placeId);
  }

}
