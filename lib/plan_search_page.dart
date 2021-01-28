import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            model.plans[index].imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(top: 30.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: FractionalOffset.bottomCenter,
                          end: FractionalOffset.topCenter,
                          colors: [
                            const Color(0xff000000).withOpacity(0.5),
                            const Color(0xff000000).withOpacity(0.0),
                          ],
                          stops: const [
                            0.0,
                            2.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildIconImageInUserTop(model.plans[index].user["icon_path"], 16.0),
                          Padding(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(
                              model.plans[index].user["name"],
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                //fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 10.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          child: Text(
                            _getDateTime(DateTime.parse(model.plans[index].startDay), DateTime.parse(model.plans[index].endDay)).toString() + "日程",
                            style: TextStyle(
                              color: Colors.white,
                              //fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right
                          ),
                        ),
                        Container(
                          child: Text(
                            model.plans[index].title,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white,
                              //fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if(model.plans[index].tags.toString() != "[]")
                          Row(
                            children: [
                              for(int i=0; i<model.plans[index].tags.length; i++)
                              Container(
                                child: Text(
                                    "#" + model.plans[index].tags[i]["tag_name"].toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      //fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.right
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
            // プランのタイトル表示
            // Expanded(
            //   child: Container(
            //     padding: EdgeInsets.symmetric(horizontal: 20),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Text(
            //           model.plans[index].title,
            //           textAlign: TextAlign.left,
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 20,
            //           ),
            //           overflow: TextOverflow.ellipsis,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // プランのサブアイテム表示
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child:
                    Container(
                      padding: EdgeInsets.only(),
                      child: Row(children: [
                        IconButton(
                          icon: (model.plans[index].isFavorite)? Icon(Icons.favorite,color: Colors.pink): Icon(Icons.favorite_outline,color: iconColor,),
                          onPressed: (){
                            // ローカルのお気に入りデータ更新
                            model.setFavoriteChange(index);
                            onPlanLikeButtonTapped(1, model.plans[index].id);
                            print(model.plans[index].favoriteCount);
                          },
                          padding: EdgeInsets.only(bottom: 3.0),
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
                            },
                            padding: EdgeInsets.only(bottom: 3.0),
                        ),
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
                            },
                          padding: EdgeInsets.only(bottom: 3.0),
                        ),
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
                    padding: EdgeInsets.only(bottom: 3.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () async{
        await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MakePlanTop(planId: model.plans[index].id,),
            )
        );
        model.fetchPostPlans();
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

  //日程を返す
  int _getDateTime(DateTime startDate, DateTime endDate){
    List<DateTime> dateList = [];
    print("aa");

    //1日だけのとき
    if(startDate == endDate){
      dateList.add(startDate);
      return dateList.length;
    }

    //2日以上あるとき
    DateTime date = startDate;
    DateTime lastDate = DateTime(endDate.year, endDate.month, endDate.day+1);
    while(date != lastDate){
      dateList.add(date);
      date = DateTime(date.year, date.month, date.day+1);
    }

    return dateList.length;
  }

  Widget _buildIconImageInUserTop(String iconPath, double size){
    final double iconSize = size;
    if(iconPath == null){
      return CircleAvatar(
        backgroundColor: Colors.grey,
        radius: iconSize,
      );
    }else{
      return CircleAvatar(
        backgroundColor: Colors.black12,
        radius: iconSize,
        backgroundImage: NetworkImage(Network().imagesDirectory("user_icons") + iconPath),
      );
    }
  }
}
