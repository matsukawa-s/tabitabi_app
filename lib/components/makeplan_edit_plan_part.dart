import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlanPart extends StatefulWidget {
  final int number;
  final String spotName;
  final String spotPath;
  final DateTime spotStartDateTime;
  final DateTime spotEndDateTime;
  final int spotParentFlag; //子がいるかどうか
  final bool confirmFlag;  //確定しているかどうか
  final double width;

  PlanPart({
    Key key,
    this.number,
    this.spotName,
    this.spotPath,
    this.spotStartDateTime,
    this.spotEndDateTime,
    this.spotParentFlag,
    this.confirmFlag,
    this.width,
  }) : super(key: key);

  @override
  _PlanPartState createState() => _PlanPartState();
}

class _PlanPartState extends State<PlanPart> {
  double _opacity = 0.5;
  final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20.0,
          width: 30.0,
          child: Container(
            margin: EdgeInsets.only(right: 10.0),
            color: widget.confirmFlag == true ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(_opacity) ,
            child: Center(
              child: Text(
                widget.number==null ? "" : widget.number.toString(),
                style: TextStyle(
                  color: widget.confirmFlag == true ? Colors.white : Colors.white.withOpacity(_opacity),
                  fontSize: 14.0,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 60.0,
          width: widget.width - (widget.width / 6),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: widget.confirmFlag ? Theme.of(context).cardColor : Theme.of(context).cardColor.withOpacity(_opacity),
                  boxShadow: [
                    BoxShadow(
                      color: widget.confirmFlag ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.01),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Opacity(
                    opacity: widget.confirmFlag ? 1.0 : _opacity,
                    child: Container(
                      constraints: BoxConstraints.expand(width: widget.width / 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft:  const  Radius.circular(20.0),
                          bottomLeft: const  Radius.circular(20.0),
                        ),
                        child: widget.spotPath == null ? Container() : Image.network(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150'
                              '&photoreference=${widget.spotPath}'
                              '&key=${_kGoogleApiKey}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints.expand(width: widget.width / 6 * 3),
                    padding: EdgeInsets.only(left: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.spotName != null ?
                          widget.spotName:
                          "",
                        style: TextStyle(
                          color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                          fontSize: 14.0,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal
                        ),
                      ),
                    )
                  ),
                  Container(
                    constraints: BoxConstraints.expand(width: widget.width /6),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text(
                            widget.spotStartDateTime!=null ?
                            widget.spotStartDateTime.hour.toString() + ":" + widget.spotStartDateTime.minute.toString() :
                            "",
                            style: TextStyle(
                              color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                              fontSize: 14.0,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.normal
                            ),
                          ),
                        ),
                        Text(widget.spotStartDateTime!=null ?
                          "|" :
                          "",
                          style: TextStyle(
                            color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                            fontSize: 14.0,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 0.0),
                          child: Text(widget.spotEndDateTime!=null ?
                            widget.spotEndDateTime.hour.toString() + ":" + widget.spotEndDateTime.minute.toString() :
                            "",
                            style: TextStyle(
                              color: widget.confirmFlag ? Colors.black : Colors.black.withOpacity(_opacity),
                              fontSize: 14.0,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.normal
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
