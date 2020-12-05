import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tabitabi_app/favorite_spot_list_page.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:smart_select/smart_select.dart';

final _kGoogleApiKey = "AIzaSyD07VLMTdrGMk3Fcar4CmTF2BMoVeRKw68";

class Prefecture {
  Prefecture(this.code,this.name);
  final code;
  final name;

  Prefecture.fromJson(Map<String,dynamic> json)
      : code = json["code"],
        name = json["name"];
}

class FavoriteSpotPage extends StatefulWidget {
  @override
  _FavoriteSpotPageState createState() => _FavoriteSpotPageState();
}

class _FavoriteSpotPageState extends State<FavoriteSpotPage> {
  List<Spot> spots;
  List<S2Choice<int>> prefectures;
  List<int> _selects = [];

  List<String> _filters = <String>[];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getFavoriteSpots(),
      builder: (context, snapshot) {
        return spots == null ? Container(
          child: Text("お気に入り登録しているスポットがありません"),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: SmartSelect.multiple(
                title: '都道府県から探す',
                value: _selects,
                onChange: (state) => setState(
                    () => {
                      print("good"),
                      _selects = state.value,
                      print(_selects),
                      print(_selects.indexOf(spots[0].prefectureId)),
                      print(_selects.indexOf(spots[1].prefectureId)),
                      print(_selects.indexOf(spots[2].prefectureId)),
                      print(spots[0].prefectureId),
                      print(spots[1].prefectureId),
                      print(spots[2].prefectureId),
                      spots = spots.where((spot) => _selects.indexOf(spot.prefectureId - 1) != -1).toList(),
                      print(spots)
                    }
                ),
                choiceItems: prefectures,
                choiceType: S2ChoiceType.chips,
                modalType: S2ModalType.popupDialog,
                choiceLayout: S2ChoiceLayout.list,
                tileBuilder: (context,state){
                  return S2Tile.fromState(
                    state,
                    isTwoLine: true, //選択しているアイテムを出す
                  );
                },
              ),
            ),
            Divider(),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 5),
              itemCount: spots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10
              ),
              itemBuilder: (context,index){
                return item(spots[index]);
              },
            ),
          ],
        );
      }
    );
  }

  Widget item(spot){
    return Column(
      children: [
        Container(
          height: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                  '&photoreference=${spot.imageUrl}'
                  '&key=${_kGoogleApiKey}',
              fit: BoxFit.fill,
            ),
          ),
        ),
        Text(
          spot.spotName,
          overflow: TextOverflow.ellipsis,
        )
      ],
    );
  }

  getFavoriteSpots() async{
    print("getFavoriteSpots() start");
    String jsonString = await rootBundle.loadString('json/prefectures.json');
    List prefecturesMap = json.decode(jsonString)["prefectures"];

    prefectures = List.generate(
        prefecturesMap.length,
        (index) => S2Choice<int>(
            value: prefecturesMap[index]["code"],
            title: prefecturesMap[index]["name"]
        )
    );

//    prefectures = List.generate(
//        prefecturesMap.length, (index) => Prefecture.fromJson(prefecturesMap[index])
//    );

    http.Response res = await Network().getData('getAllFavorite');
    if(res.statusCode == 200){
      List tmp = jsonDecode(res.body);

      spots = List.generate(
          tmp.length, (index) => Spot.fromJson(tmp[index])
      );

    }else{
      print(res.statusCode);
    }
  }
}