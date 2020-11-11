import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class MapSearchPage extends StatefulWidget {
  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  var _keyWordController = TextEditingController();
  final kGoogleApiKey = "AIzaSyC2VCSOjFsBo9sPArzQde0aN_R5ZU8Rt0w";
  List items = [];
  var focusNode = new FocusNode(); //検索バーのフォーカス制御用

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    FocusScope.of(context).requestFocus(focusNode);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _keyWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 30,left: 8,right: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(90)
              ),
              child: TextField(
                focusNode: focusNode,
                autofocus: true,
                onSubmitted: (String str) => searchPlaces(),
                controller: _keyWordController,
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
                      title: Text(items[index].description.substring(3)),
                      onTap: () => onTapPlace(items[index].placeId),
                    );
                  }
              ),
            )
          ],
        ),
      ),
    );
  }

// Google Places APIを叩いて場所を検索する
  Future<void> searchPlaces() async{
    GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
    List<PlacesSearchResponse> places = [];

    if(_keyWordController.text.isNotEmpty){
      print(_keyWordController.text.toString());
      PlacesAutocompleteResponse res =
        await _places.autocomplete(_keyWordController.text.toString(),language: "ja");

      if(res.status == "OK"){
        setState(() {
          items = res.predictions;
        });
      }
    }
  }

//  地図画面に選択した場所を戻す
  void onTapPlace(placeId){
    Navigator.pop(context,placeId);
  }

}
