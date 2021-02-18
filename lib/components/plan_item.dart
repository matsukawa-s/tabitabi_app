import 'package:cached_network_image/cached_network_image.dart';
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
      onTap: () async{
        var result = await Navigator.of(context,rootNavigator: true).push(
            MaterialPageRoute(
                builder: (context) => MakePlanTop(
                  planId: plan.id,
                )
            )
        );
      },
      child: Container(
        width: width ?? defaultWidth,
        height: height ?? defaultHeight,
//        padding: EdgeInsets.all(2.0),
        child: Stack(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: plan.imageUrl == null
                    ? Image.asset(
                        "images/osakajo.jpg",
                        width: width ?? defaultWidth,
                        height: height ?? defaultHeight,
                        fit: BoxFit.fill,
                      )
                    : CachedNetworkImage(
                        imageUrl: plan.imageUrl,
                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                            Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                        errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
            ),
            Positioned(
              bottom: 0,
              width: width ?? defaultWidth,
              child: Container(
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

class PlanItemNotTap extends StatelessWidget {
  final double width;
  final double height;
  final Plan plan;

  PlanItemNotTap({
    this.width,
    this.height,
    this.plan
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double defaultHeight = (size.width) * 2/5 * 4/5;
    final double defaultWidth = (size.width) * 2/5;

    return Container(
      width: width ?? defaultWidth,
      height: height ?? defaultHeight,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: plan.imageUrl == null
                ? Image.asset(
              "images/osakajo.jpg",
              width: width ?? defaultWidth,
              height: height ?? defaultHeight,
              fit: BoxFit.fill,
            )
                : CachedNetworkImage(
              imageUrl: plan.imageUrl,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
              errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            bottom: 0,
            width: width ?? defaultWidth,
            child: Container(
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
    );
  }
}