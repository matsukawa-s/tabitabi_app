import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:smart_select/smart_select.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

class FavoriteSpotPage extends StatefulWidget {
  FavoriteSpotPage({
    Key key,
    this.mode = false,
    this.callback
  }) : super(key: key);

  final bool mode; // true : 選択可能モード
  Function callback; // 親Widgetにスポットを渡す関数

  @override
  _FavoriteSpotPageState createState() => _FavoriteSpotPageState();
}

class _FavoriteSpotPageState extends State<FavoriteSpotPage> {
  List<int> _selectsPrefectures = []; // 都道府県の絞り込み
  List<int> _selectsTypes = []; // 場所タイプの絞り込み
  List<int> _selectedSpotItems = []; // 選択しているスポット(spotId)

  @override
  void initState() {
    super.initState();
    _selectedSpotItems.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteSpotViewModel>(context,listen: false).getFavoriteSpots();
      Provider.of<FavoriteSpotViewModel>(context,listen: false).getSpotTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
   final model = Provider.of<FavoriteSpotViewModel>(context);
        return model.spots == null || model.types == null ? Center(
          child: CircularProgressIndicator()
        )
        : model.spots.isEmpty ? Center(child: Text("お気に入り登録しているスポットがありません"))
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: SmartSelect.multiple(
                  title: '都道府県で絞り込む',
                  value: _selectsPrefectures,
                  onChange: (state) => setState(
                      () => {
                        _selectsPrefectures = state.value,
                        model.narrowDownByPrefectureAndTypes(_selectsPrefectures,_selectsTypes)
                      }
                  ),
                  choiceItems: model.prefectures,
                  choiceType: S2ChoiceType.chips,
                  modalType: S2ModalType.popupDialog,
                  choiceLayout: S2ChoiceLayout.list,
                  tileBuilder: (context,state){
                    return S2Tile.fromState(
                      state,
                      isTwoLine: false, //選択しているアイテムを出す
                    );
                  },
                ),
              ),
              Container(
                child: SmartSelect.multiple(
                  title: 'タイプで絞り込む',
                  value: _selectsPrefectures,
                  onChange: (state) => setState(
                      () => {
                        _selectsTypes = state.value,
                        model.narrowDownByPrefectureAndTypes(_selectsPrefectures,_selectsTypes)
                      }
                  ),
                  choiceItems: model.types,
                  choiceType: S2ChoiceType.checkboxes,
                  modalType: S2ModalType.popupDialog,
                  choiceLayout: S2ChoiceLayout.list,
                  tileBuilder: (context,state){
                    return S2Tile.fromState(
                      state,
                      isTwoLine: false, //選択しているアイテムを出す
                    );
                  },
                ),
              ),
              Divider(),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 5),
                itemCount: model.showSpots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10
                ),
                itemBuilder: (context,index){
                  if(widget.mode){
                    return _buildSelectableItem(model.showSpots[index],model);
                  }else{
                    return _buildShowDetailsSpotItem(model.showSpots[index],model);
                  }
                },
              ),
            ],
          ),
        );
  }

  Widget _buildSpotItem(Spot spot){
    return Column(
      children: [
        Container(
          height: 100,
          width: MediaQuery.of(context).size.width / 3,
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

  // お気に入りスポット画面のアイテム（タップ時に詳細ダイアログ開く）
  Widget _buildShowDetailsSpotItem(spot,model){
    final Size size = MediaQuery.of(context).size;
    final dialogWidth = size.width - 30;
    final dialogHeight = size.height - 30;

    return GestureDetector(
      onTap: (){
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
                contentPadding: EdgeInsets.zero,
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 2, //アスペクト比 3:2
                              child: Image.network(
                                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                                    '&photoreference=${spot.imageUrl}'
                                    '&key=${_kGoogleApiKey}',
                                fit: BoxFit.fill,
                              ),
                            ),
                            IconButton(
                              color: Colors.white,
                                icon: Icon(Icons.cancel),
                                onPressed: (){
                                  Navigator.pop(context);
                                }
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(spot.spotName),
                            ],
                          ),
                        ),
                        RaisedButton(
                            child: Text("このスポットを削除する"),
                            onPressed: (){
                              model.unlikeSpot(spot);
                              Navigator.pop(context);
                            }
                        )
                      ],
                    ),
                  )
                ],
            );
          },
        );
      },
      child: _buildSpotItem(spot),
    );
  }

  //選択可能なスポットアイテム(mode : true)
  Widget _buildSelectableItem(spot,model){
    return GestureDetector(
      onTap: () {
        setState(() {
          if(_selectedSpotItems.contains(spot.spotId)){
            _selectedSpotItems.remove(spot.spotId);
          }else{
            _selectedSpotItems.add(spot.spotId);
          }
        });
        List<Spot> returnValue = model.getSelectedSpots(_selectedSpotItems);
//        print(returnValue);
        widget.callback(returnValue);
      },
      child: !_selectedSpotItems.contains(spot.spotId) ? _buildSpotItem(spot)
          : Stack(
        children: [
          _buildSpotItem(spot),
          Container(
            decoration: BoxDecoration(
                color: Colors.black12.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0)
            ),
          ),
          Positioned(
            right: 0,
            child: Icon(
              Icons.check_circle,
              color: Colors.orangeAccent,
              size: 30.0,
            ),
          )
        ],
      ),
    );
  }
}