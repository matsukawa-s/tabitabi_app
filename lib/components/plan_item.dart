import 'package:flutter/material.dart';
import 'package:tabitabi_app/makeplan/makeplan_top_page.dart';
import 'package:tabitabi_app/model/plan.dart';

class PlanItem extends StatelessWidget {
  final double width;
  final double height;
  final Plan plan;

  PlanItem({
    this.width,
    this.height,
    this.plan
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double defaultHeight = (size.width) * 2/5 * 4/5;
    final double defaultWidth = (size.width) * 2/5;

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
        width: width ?? defaultWidth,
//        padding: EdgeInsets.all(2.0),
        child: Stack(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset("images/osakajo.jpg",height: height ?? defaultHeight,fit: BoxFit.fill,)
            ),
            Positioned(
              bottom: 0,
              width: width,
              child: Container(
//                width: width - 2.0 ?? defaultWidth - 2.0,
                width: double.infinity,
                padding: EdgeInsets.only(left: 2.0, bottom: 2.0),
                height: (height ?? defaultHeight) * 1/5,
                decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0)
                    )
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                    plan.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
