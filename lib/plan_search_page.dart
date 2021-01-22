import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/plan_search_model.dart';
import 'package:tabitabi_app/makeplan/makeplan_top_page.dart';

import 'network_utils/api.dart';

//class SearchPage extends StatefulWidget {
//  @override
//  SearchPageState createState() => new SearchPageState();
//}
//class SearchPageState extends State<SearchPage> {
class PlanSearchPage extends StatelessWidget {
  bool isLiked;
  Color iconColor = Colors.grey[800];
  bool debugPaintSizeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final double _width = MediaQuery.of(context).size.width;
    final double _height = MediaQuery.of(context).size.height;
    return FutureBuilder(
      future: Provider.of<PlanSearchModel>(context,listen: false).fetchPostPlans(),
      builder: (ctx,dataSnapshot){
        return Consumer<PlanSearchModel>(
            builder: (_, model, __) {
              return RefreshIndicator(
                onRefresh: () => model.fetchPostPlans(),
                child: model.plans == null
                    // 検索結果がnullの間、ぐるぐる表示
                    ? Center(
                        child: CircularProgressIndicator() ,
                      )
                    : (model.plans.length == 0)
                        // 検索結果が０件のとき
                        ? Center(child: Text(model.keyword + ' に一致するプランは見つかりませんでした。'),)
                        // 検索結果が見つかったとき
                        : (_width > 600)
                          ? _bigDisplay(model)
                          : _smallDisplay(model),
              );
            }
        );
      },
    );
  }

  Widget _bigDisplay(model){
    return GridView.builder(
        itemCount: model.plans.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 30,
          crossAxisSpacing: 10,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (BuildContext context, int index) {
          return contents(model,index,context);
        }
    );
  }

  Widget _smallDisplay(model){
    return GridView.builder(
        itemCount: model.plans.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//          mainAxisSpacing: 10,
          crossAxisCount: 1,
          childAspectRatio: 1.7,
        ),
        itemBuilder: (BuildContext context, int index) {
          return contents(model,index,context);
        }
    );
  }

  Widget contents(model,index,context){
    return GestureDetector(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // プランの画像表示
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        "https://www.osakacastle.net/wordpress/wp-content/themes/osakacastle-sp/sp_img/contents/top_img.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        // プランのサブアイテム表示
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                child: Row(
//                  mainAxisSize: MainAxisSize.min,
                  children: [
                  IconButton(
                    icon: (model.plans[index].isFavorite)? Icon(Icons.favorite,color: Colors.pink): Icon(Icons.favorite_outline,color: iconColor,),
                    onPressed: (){
                      // ローカルのお気に入りデータ更新
                      model.setFavoriteChange(index);
                      onPlanLikeButtonTapped(1, model.plans[index].id);
                      print(model.plans[index].favoriteCount);
                    },
                  ),
                  Text(
                      NumberFormat.compact().format(model.plans[index].favoriteCount),
                    style: TextStyle(
                      color: iconColor,
            // プランのタイトル表示
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      model.plans[index].title,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // プランのサブアイテム表示
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child:
                    Container(
                      child: Row(children: [
                        IconButton(
                          icon: (model.plans[index].isFavorite)? Icon(Icons.favorite,color: Colors.pink): Icon(Icons.favorite_outline,color: iconColor,),
                          onPressed: (){
                            // ローカルのお気に入りデータ更新
                            model.setFavoriteChange(index);
                            onPlanLikeButtonTapped(1, model.plans[index].id);
                            print(model.plans[index].favoriteCount);
                          },
                        ),
                        Text(
                            NumberFormat.compact().format(model.plans[index].favoriteCount),
                          style: TextStyle(
                            color: iconColor,
                          ),
                        ),
                        IconButton(
                            icon: Icon(Icons.visibility_outlined,color: iconColor,),
                            onPressed: (){
//                      model.plans[index].numberOfViews += 1;
                              print('閲覧数');
                              print(iconColor.toString());
                            }),
                        Text(
                          NumberFormat.compact().format(model.plans[index].numberOfViews),
                          style: TextStyle(
                            color: iconColor,
                          ),
                        ),
                        IconButton(
                            icon: Icon(Icons.copy_outlined,color: iconColor,),
                            onPressed: (){

                              print('参考数');
                            }),
                        Text(
                          NumberFormat.compact().format(model.plans[index].referencedNumber),
                          style: TextStyle(
                            color: iconColor,
                          ),
                        ),
                      ],),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.upload_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: (){
        Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MakePlanTop(planId: model.plans[index].id,),
            )
        );
      },
    );
  }
  // お気に入りカウントアップ
  Future<bool> onPlanLikeButtonTapped(userId,favoritePlanId) async {
    // お気に入り状態を更新するためのリクエストデータ
    Map data = {
      'user_id' : userId,
      'favorite_plan_id' : favoritePlanId,
    };
    // データベースのお気に入りデータを更新
    await Network().postData(data, 'favoritePlan');
  }
}