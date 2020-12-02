import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tabitabi_app/favorite_spot_list_page';

class FavoriteSpotPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.symmetric(vertical: 20,horizontal: 10),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10.0,
      childAspectRatio:0.90,
      crossAxisCount: 2,
      children: List.generate(21, (index) {
        return item(context);
      }),
    );
  }

  Widget item(context){
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FavoriteSpotListPage(),
            )
        );
      },
      child: Column(
        children: [
          Container(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network("https://www.osakacastle.net/wordpress/wp-content/themes/osakacastle-sp/sp_img/contents/top_img.jpg",
                fit: BoxFit.cover,),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 7),
            child: Text("ASD",
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}