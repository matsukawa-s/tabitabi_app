import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_spot_list_page.dart';
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/network_utils/api.dart';

final _kGoogleApiKey = "AIzaSyD07VLMTdrGMk3Fcar4CmTF2BMoVeRKw68";

class FavoriteSpotPage extends StatelessWidget {
  List spots;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getFavoriteSpots(),
      builder: (context, snapshot) {
        return spots == null ? Container()
        : GridView.count(
          padding: EdgeInsets.symmetric(vertical: 10,horizontal: 5),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10.0,
//          childAspectRatio:0.90,
          crossAxisCount: 3,
          children: List.generate(spots.length, (index) {
            return item(spots[index]);
          }),
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
                  '&photoreference=${spot["image_url"]}'
                  '&key=${_kGoogleApiKey}',
              fit: BoxFit.fill,
            ),
          ),
        ),
        Text(
          spot["spot_name"],
          overflow: TextOverflow.ellipsis,
        )
      ],
    );
  }

//  Widget item(context){
//    return GestureDetector(
//      onTap: () {
//        Navigator.push(
//            context,
//            MaterialPageRoute(builder: (context) => FavoriteSpotListPage(),
//            )
//        );
//      },
//      child: Column(
//        children: [
//          Container(
//            height: 180,
//            child: ClipRRect(
//              borderRadius: BorderRadius.circular(8.0),
//              child: Image.network("https://www.osakacastle.net/wordpress/wp-content/themes/osakacastle-sp/sp_img/contents/top_img.jpg",
//                fit: BoxFit.cover,),
//            ),
//          ),
//          Container(
//            margin: EdgeInsets.symmetric(vertical: 7),
//            child: Text("ASD",
//              overflow: TextOverflow.ellipsis,
//            ),
//          ),
//        ],
//      ),
//    );
//  }

  getFavoriteSpots() async{
    http.Response res = await Network().getData('getAllFavorite');
    if(res.statusCode == 200){
      spots = jsonDecode(res.body);
    }
  }
}