import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/model/plan.dart';
import 'package:tabitabi_app/providers/plan_provider.dart';

class FavoritePlanPage extends StatelessWidget {
  final double contentsPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double itemWidth = (size.width - contentsPadding * 2) / 2;
    final double itemHeight = itemWidth * 2/3;

    return FutureBuilder(
        future: Provider.of<PlanProvider>(context,listen: false).getFavoritePlans(),
        builder: (BuildContext context,AsyncSnapshot snapshot){
          print(snapshot.error);
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if(snapshot.hasError){
            print(snapshot.error);
            return Center(
              child: Text("error"),
            );
          }

          return Consumer<PlanProvider>(
            builder: (context, plan, child) => Container(
              padding: EdgeInsets.all(contentsPadding),
              child: plan.plans.isEmpty
                  ? Center(
                      child: Text("お気に入りにしているプランはありません"),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: itemWidth / itemHeight
                      ),
                      itemCount: plan.plans.length,
                      itemBuilder: (BuildContext context,int index){
                        return Stack(
                          children: [
                            PlanItem(
                              plan: plan.plans[index],
                              width: itemWidth,
                              height: itemHeight,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                iconSize: 28,
                                icon: Icon(Icons.favorite,color: Colors.pink[400],),
                                onPressed: () => plan.deleteFavoritePlan(plan.plans[index])
                              )
                            )
                          ],
                        );
//                        return _buildPlanItem(plan.plans[index]);
                      }
                  ),
            ),
          );
        }
    );
  }
}