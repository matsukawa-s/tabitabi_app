import 'package:flutter/material.dart';
import 'package:tabitabi_app/makeplan/makeplan_top_page.dart';
import 'package:tabitabi_app/model/plan.dart';

class PlanItem extends StatelessWidget {
  final double width;
  final double height;
  final Plan plan;

  PlanItem({
    this.width = double.infinity,
    this.height,
    this.plan
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MakePlanTop(
                planId: plan.id,
              )
          )
      ),
      child: Container(
        width: width,
        padding: EdgeInsets.all(2.0),
        child: Stack(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: Image.asset("images/osakajo.jpg",height: height,fit: BoxFit.fill,)
            ),
            Positioned(
              bottom: 2.0,
              child: Container(
                width: width,
                height: height * 1/6,
//                margin: EdgeInsets.only(bottom: 4.0),
                padding: EdgeInsets.only(left: 4.0),
                color: Colors.black38,
                child: Text(
                    plan.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ],
        ),
//        child: Column(
//          children: [
//            Expanded(
//              flex: 4,
//              child: ClipRRect(
//                borderRadius: BorderRadius.circular(6.0),
//                child: Container(
//                  width: width,
//                  child: Image.asset("images/osakajo.jpg",fit: BoxFit.fill,),
//                ),
//              ),
//            ),
//            Expanded(
//              flex: 1,
//                child: Text(
//                  plan.title,
//                  overflow: TextOverflow.ellipsis,
//                )
//            ),
//          ],
//        ),
      ),
    );
  }
}
