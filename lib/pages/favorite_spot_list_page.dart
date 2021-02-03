import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FavoriteSpotListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("フォルダ名"),
      ),
      body: GridView.count(
        childAspectRatio:0.95,
        crossAxisCount: 3,
        crossAxisSpacing: 3.0,
        children: List.generate(31, (index) {
          return Stack(
            children:[
              Container(
                height: 139,
                child: Image.network("https://www.osakacastle.net/wordpress/wp-content/themes/osakacastle-sp/sp_img/contents/top_img.jpg",
                  fit: BoxFit.cover,),
              ),
              Positioned(
                left: 5.0,
//                top: 100.0,
//                right: 100.0,
                bottom: 5.0,
                child: Text("ASDF",
                  style: TextStyle(
                    color: Colors.white,
//                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          );
        }),
      ),
    );
  }
}