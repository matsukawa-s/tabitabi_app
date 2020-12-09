import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/plan_search_model.dart';

import 'network_utils/api.dart';

//class SearchPage extends StatefulWidget {
//  @override
//  SearchPageState createState() => new SearchPageState();
//}
//class SearchPageState extends State<SearchPage> {
class PlanSearchPage extends StatelessWidget {
  bool isLiked;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<PlanSearchModel>(context,listen: false).fetchPostPlansList(),
      builder: (ctx,dataSnapshot){
        return Consumer<PlanSearchModel>(
            builder: (_, model, __) {
              return RefreshIndicator(
                onRefresh: () => model.fetchPostPlansList(),
                child: Container(
                  color: Colors.grey[200],
                  child: model.plans == null
                      ? Container()
                      : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      List<double> bottomMargin = []..length = model.plans.length;
                      if (index != 9) {
                        bottomMargin[index] = 5;
                      } else {
                        bottomMargin[index] = 0;
                      }
                      return Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        "https://www.osakacastle.net/wordpress/wp-content/themes/osakacastle-sp/sp_img/contents/top_img.jpg"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                height: 170.0,
                                width: 500,
                              ),
                              Container(
                                padding: EdgeInsets.all(5),
                                child: CircleAvatar(
                                  radius: 24.0,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                      "https://pbs.twimg.com/profile_images/885510796691689473/rR9aWvBQ_400x400.jpg"),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            height: 28.0,
                            width: 500,
                            color: Colors.white,
                            child: Text(model.plans[index].title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: bottomMargin[index]),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  IconButton(
                                      icon: Icon(Icons.stars),
                                      onPressed: (){
                                        onPlanLikeButtonTapped(model.plans[index].isFavorite,1,model.plans[index].id,context);
                                      },
                                  ),
                                  Text(NumberFormat.compact().format(model.plans[index].favoriteCount)),
                                  IconButton(
                                      icon: Icon(Icons.visibility),
                                      onPressed: (){
                                        print('閲覧数');
                                      }),
                                  Text(NumberFormat.compact().format(model.plans[index].numberOfViews)),
                                  IconButton(
                                      icon: Icon(Icons.copy_outlined),
                                      onPressed: (){

                                        print('参考数');
                                      }),
                                  Text(NumberFormat.compact().format(model.plans[index].referencedNumber)),
                                ],),
                                IconButton(
                                  icon: Icon(Icons.upload_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    itemCount: model.plans.length,
                  ),
                ),
              );
            }
        );
      },
    );
  }
  // お気に入りカウントアップ
  Future<bool> onPlanLikeButtonTapped(bool isLiked,userId,favoritePlanId,context) async {
    // ローカルのお気に入りデータ更新
//    Provider.of<PlanSearchModel>(context,listen: false).plans[favoritePlanId].setFavoriteChange;

    // お気に入り状態を更新するためのリクエストデータ
    Map data = {
      'user_id' : userId,
      'favorite_plan_id' : favoritePlanId,
    };
    // データベースのお気に入りデータを更新
    await Network().postData(data, 'favoritePlan');
  }
}