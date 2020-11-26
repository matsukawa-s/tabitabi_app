import 'package:flutter/material.dart';

//スポット
class SpotPart extends StatefulWidget {
  final String spotName;
  final String spotPath;

  SpotPart({
    Key key,
    this.spotName,
    this.spotPath,
  }) : super(key: key);

  @override
  _SpotPartState createState() => _SpotPartState();
}

class _SpotPartState extends State<SpotPart> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.0,
      width: 110.0,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                constraints: BoxConstraints.expand(height: 60.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(widget.spotPath),
                      fit: BoxFit.cover
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft:  const  Radius.circular(10.0),
                    topRight: const  Radius.circular(10.0),
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints.expand(height: 30.0),
                child: Center(
                  child: Text(widget.spotName,
                    style: TextStyle(color: Colors.black,fontSize: 14.0, decoration: TextDecoration.none, fontWeight: FontWeight.normal),),
                ),
              )
            ],
          ),
        ],
      )
    );
  }
}

//交通
class TrafficEditPart extends StatefulWidget {
  final IconData icon;
  final String trafficType;

  TrafficEditPart({
    Key key,
    this.icon,
    this.trafficType,
  }) : super(key: key);

  @override
  _TrafficEditPartState createState() => _TrafficEditPartState();
}

class _TrafficEditPartState extends State<TrafficEditPart> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      width: 120.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 7,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Icon(widget.icon, color: Colors.white,),
            ),
            Container(
              width: 80.0,
              child: Center(
                child: Text(widget.trafficType, style: TextStyle(color: Colors.white, fontSize: 14.0, decoration: TextDecoration.none, fontWeight: FontWeight.normal),),
              ),
            )
          ],
        ),
      ),
    );
  }
}

