import 'package:flutter/material.dart';

class PlanPart extends StatefulWidget {
  final int number;
  final String spotName;
  final String spotPath;
  final DateTime spotStartDateTime;
  final DateTime spotEndDateTime;
  final int spotParentFlag; //子がいるかどうか
  final bool confirmFlag;  //確定しているかどうか

  PlanPart({
    Key key,
    this.number,
    this.spotName,
    this.spotPath,
    this.spotStartDateTime,
    this.spotEndDateTime,
    this.spotParentFlag,
    this.confirmFlag,
  }) : super(key: key);

  @override
  _PlanPartState createState() => _PlanPartState();
}

class _PlanPartState extends State<PlanPart> {
  double _opacity = 0.5;
  
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
                widget.number.toString(),
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
          width: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width / 6),
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
                      constraints: BoxConstraints.expand(width: MediaQuery.of(context).size.width / 6),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(widget.spotPath),
                            fit: BoxFit.cover
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft:  const  Radius.circular(20.0),
                          bottomLeft: const  Radius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints.expand(width: MediaQuery.of(context).size.width / 6 * 3),
                    padding: EdgeInsets.only(left: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.spotName,
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
                    constraints: BoxConstraints.expand(width: MediaQuery.of(context).size.width /6),
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
