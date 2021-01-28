import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:smart_select/smart_select.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/spot_details_page.dart';

import 'components/spot_item.dart';

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
  Size size;
  final double paddingGridView = 4.0; // GridViewのPadding

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.of(context).size;
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
                modalType: Platform.isAndroid ? S2ModalType.popupDialog : S2ModalType.bottomSheet,
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
                modalType: Platform.isAndroid ? S2ModalType.popupDialog : S2ModalType.bottomSheet,
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
              padding: EdgeInsets.all(paddingGridView),
              itemCount: model.showSpots.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6
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
        Expanded(
          flex: 4,
          child: Container(
            width: (size.width - paddingGridView * 2) / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                GoogleMapApi().fullPhotoPath(spot.imageUrl),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            spot.spotName,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  // お気に入りスポット画面のアイテム（タップ時に詳細ダイアログ開く）
  Widget _buildShowDetailsSpotItem(spot,model){
    return GestureDetector(
      onTap: () async{
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SpotDetailsPage(
                  spotId: spot.spotId,
                  placeId: spot.placeId,
                )
            )
        );
        model.getFavoriteSpots();
      },
      child: SpotItem(spot: spot,),
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