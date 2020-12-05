import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:smart_select/smart_select.dart';

final _kGoogleApiKey = "AIzaSyD07VLMTdrGMk3Fcar4CmTF2BMoVeRKw68";

class FavoriteSpotPage extends StatefulWidget {
  @override
  _FavoriteSpotPageState createState() => _FavoriteSpotPageState();
}

class _FavoriteSpotPageState extends State<FavoriteSpotPage> {
  List<int> _selects = [];
  var model;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    model = Provider.of<FavoriteSpotViewModel>(context);
  }

  @override
  Widget build(BuildContext context) {


        return model.spots == null ? Container(
          child: Text("お気に入り登録しているスポットがありません"),
        ) :
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: SmartSelect.multiple(
                title: '都道府県から探す',
                value: _selects,
                onChange: (state) => setState(
                    () => {
                      _selects = state.value,
                      model.refine(_selects)
                    }
                ),
                choiceItems: model.prefectures,
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
              itemCount: model.showSpots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10
              ),
              itemBuilder: (context,index){
                return item(model.showSpots[index]);
              },
            ),
          ],
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
}