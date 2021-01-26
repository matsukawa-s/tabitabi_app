import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:google_maps_webservice/places.dart";
import 'package:http/http.dart' as http;
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'model/plan.dart';
import 'network_utils/google_map.dart';

class SpotDetailsPage extends StatefulWidget {
  SpotDetailsPage({
    Key key,
    this.spotId,
    this.placeId,
  }) : super(key: key);

  final spotId;
  final String placeId;

  @override
  _SpotDetailsPageState createState() => _SpotDetailsPageState();
}

class _SpotDetailsPageState extends State<SpotDetailsPage> {
  final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

  var planContainingSpots = []; //対象スポットが入っているプラン
  bool isFavorite;

  getInitialData() async{
    //google place details api
    final places = GoogleMapsPlaces(apiKey: _kGoogleApiKey);
    PlacesDetailsResponse res = await places.getDetailsByPlaceId(widget.placeId,language: 'ja');

    if(res.status != 'OK') return -1;

    //プランのお気に入り情報を取得する
    http.Response res2 = await Network().getData("getOneFavorite/${widget.placeId}");

    if(res2.statusCode != 200) return -1;

    var details = jsonDecode(res2.body);

    return [
      res.result,
      details
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double planContainingSpotsViewPadding = 8.0;
    final double planContainingSpotsItemHeight = (size.width - planContainingSpotsViewPadding*2 - 6) / 2 * 2/3;
    final double planContainingSpotsItemWidth = (size.width - planContainingSpotsViewPadding*2 - 6) / 2;

    return FutureBuilder(
      future: getInitialData(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          if(snapshot.data == -1){
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text("ERROR"),),
            );
          }

          final data = snapshot.data[0];
          final photoReference = data.photos[0].photoReference;
          final planContainingSpotsTmp = snapshot.data[1]["plan_containing_spots"];
          isFavorite = snapshot.data[1]["isFavorite"];
          final List<Plan> planContainingSpots = List.generate(
              planContainingSpotsTmp.length, (index) => Plan.fromJson(planContainingSpotsTmp[index])
          );

          return Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(size.width * (2/5)),
              child: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.white60, // button color
                      child: InkWell(
                        splashColor: Colors.black12, // inkwell color
                        child: Icon(Icons.arrow_back),
                        onTap: () { Navigator.pop(context); },
                      ),
                    ),
                  ),
                ),
                actions: [
                  MaterialButton(
                    onPressed: onLikeButtonTapped,
                    color: Colors.white,
                    textColor: Colors.pink,
                    child: isFavorite ?
                      Icon(
                        Icons.favorite,
                        size: 36,
                      )
                    : Icon(
                      Icons.favorite_border,
                      size: 36,
                    ),
                    padding: EdgeInsets.all(12),
                    shape: CircleBorder(),
                  ),
                ],
                flexibleSpace: Container(
                  decoration:
                  BoxDecoration(
                    image: DecorationImage(
//                      image: AssetImage('images/osakajo.jpg'),
                      image: NetworkImage(
                          GoogleMapApi().fullPhotoPath(photoReference)
                      ),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(data.name,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 22),),
                    ),
                    if(data.formattedAddress != null)
                      ListTile(
                        leading: Icon(Icons.add_location),
                        title: Text(data.formattedAddress ?? ''),
                      ),
                    if(data.formattedPhoneNumber != null)
                      ListTile(
                        leading: Icon(Icons.phone),
                        title: Text(data.formattedPhoneNumber ?? ''),
                      ),
                    if(data.website != null)
                      ListTile(
                        leading: Icon(Icons.web),
                        title: Text(data.website ?? ''),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0,top: 16.0),
                      child: Text(
                          "このスポットを含むプラン",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                      ),
                    ),
                    if(planContainingSpots.isNotEmpty)
                      SizedBox(
                        height: planContainingSpotsItemHeight,
                        child: Padding(
                          padding: EdgeInsets.all(planContainingSpotsViewPadding),
                          child: ListView.builder(
                              itemCount: planContainingSpots.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (BuildContext context,int index){
                                return PlanItem(plan: planContainingSpots[index]);
                              }
                          ),
                        ),
                      ),
//                    Center(
//                      child: Container(
//                        margin: EdgeInsets.only(top: 20),
//                        width: size.width - planContainingSpotsViewPadding - 30,
//                        child: FlatButton(
//                            onPressed: (){
//
//                            },
//                            shape: const StadiumBorder(
//                              side: BorderSide(color: Colors.orange),
//                            ),
//                            child: const Text("マップで表示する(未実装)")
//                        ),
//                      ),
//                    ),
                  ],
                ),
              ),
            ),
          );
        }else{
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    );
  }

  onLikeButtonTapped() async{
    var data = {
      "spot_id" : widget.spotId
    };

    http.Response res = await Network().postData(data, 'postFavoriteSpot');

    var body = json.decode(res.body);
    print(body);

    if(res.statusCode == 200){
      setState(() {

      });
    }
  }
}
