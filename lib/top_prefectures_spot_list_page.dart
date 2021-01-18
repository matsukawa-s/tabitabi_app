import 'package:flutter/material.dart';
import 'package:tabitabi_app/components/spot_item.dart';
import 'package:tabitabi_app/model/spot_model.dart';

class PrefecturesSpotsListPage extends StatelessWidget {
  final Prefecture prefecture;
  final List<Spot> spots;
  final double pagePadding = 6.0;

  PrefecturesSpotsListPage({this.prefecture}) : this.spots = prefecture.spots;

  @override
  Widget build(BuildContext context) {
//    final Size size = MediaQuery.of(context).size;
//    final itemWidth = size.width

    return Scaffold(
      appBar: AppBar(
        title: Text("${prefecture.name}のスポット"),
      ),
      body: Container(
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(pagePadding),
          itemCount: spots.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6
          ),
          itemBuilder: (BuildContext context, int index){
            return SpotItem(spot: spots[index]);
          },
        ),
      ),
    );
  }
}
