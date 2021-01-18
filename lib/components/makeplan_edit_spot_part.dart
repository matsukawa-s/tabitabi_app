import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.0,
      width: 100.0,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft:  const  Radius.circular(10.0),
                    topRight: const  Radius.circular(10.0),
                  ),
                  child: widget.spotPath == null ? Container() :
                    widget.spotPath.contains("https://") ?
                        Image.network(
                          widget.spotPath,
                          fit: BoxFit.cover,
                        ):
                        Image.network(
                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                            '&photoreference=${widget.spotPath}'
                            '&key=${_kGoogleApiKey}',
                          fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints.expand(height: 40.0),
                child: Center(
                  child: Text(widget.spotName,
                    style: TextStyle(color: Colors.black,fontSize: 12.0, decoration: TextDecoration.none, fontWeight: FontWeight.normal),),
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

