import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            return Center(
              child: Text("error"),
            );
          }

          return Consumer<PlanProvider>(
            builder: (context, plans, child) => Container(
              padding: EdgeInsets.all(contentsPadding),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: itemWidth / itemHeight
                  ),
                  itemCount: plans.plans.length,
                  itemBuilder: (BuildContext context,int index){
                    return _buildPlanItem(plans.plans[index]);
                  }
              ),
            ),
          );
        }
    );
  }

  Widget _buildPlanItem(Plan plan){
    return GestureDetector(
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    "images/osakajo.jpg",
                    width: double.infinity,
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.favorite,color: Colors.pink,)
                )
              ],
            )
          ),
          Expanded(
            flex: 1,
            child: Container(
              child: Text(plan.title,overflow: TextOverflow.ellipsis,),
            ),
          ),
        ],
      ),
    );
  }
}