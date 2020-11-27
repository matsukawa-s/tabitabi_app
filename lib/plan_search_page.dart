import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/plan_search_provider.dart';

//class SearchPage extends StatefulWidget {
//  @override
//  SearchPageState createState() => new SearchPageState();
//}
//class SearchPageState extends State<SearchPage> {
class PlanSearchPage extends StatelessWidget {
//  final String title;
//  var plansState;
//  List plans;

//  Future<void> _onRefresh() async {
//    setState(() {
//      plans = plansState.fetchPlansList();
//    });
//  }

  @override
  Widget build(BuildContext context) {
//    plansState = Provider.of<SearchProvider>(context);
//    plans = plansState.searchplanlist;
//    var plansState = Provider.of<SearchProvider>(context);
//    List plans = plansState.searchplanlist;

//    print(plans);
//    print(plans[0]['title']);
    return Consumer<PlanSearchProvider>(
      builder: (_, model, __) {
        return RefreshIndicator(
          onRefresh: () => null,
          //      onRefresh: ()=> _onRefresh(),
          //      onRefresh: (){
          //        plansState.fetchPlansList();
          ////        return ;
          //      },
          child: Container(
            color: Colors.grey[200],
            child: model.searchplanlist == null
                ? Container()
                : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                List<double> bottomMargin = []..length = model.searchplanlist.length;
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
                      child: Text(model.searchplanlist[index]['title'],
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
                                  print('おきにいり');
                                  model.favoritePlan(1, model.searchplanlist[index]['id']);
                                }
                            ),
                            Text(model.searchplanlist[index]['favorite_count'].toString()),
                            IconButton(
                                icon: Icon(Icons.visibility),
                                onPressed: (){
                                  print('閲覧数');
                                }),
                            Text(model.searchplanlist[index]['number_of_views'].toString()),
                            IconButton(
                                icon: Icon(Icons.copy_outlined),
                                onPressed: (){

                                  print('参考数');
                                }),
                            Text(model.searchplanlist[index]['referenced_number'].toString()),
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
              itemCount: model.searchplanlist.length,
            ),
          ),
        );
      }
    );
  }
}