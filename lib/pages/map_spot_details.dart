import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/components/plan_item.dart';
import 'package:tabitabi_app/network_utils/api.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/pages/spot_details_page.dart';
import 'package:tabitabi_app/providers/map_provider.dart';

class MapSpotDerailsPage extends StatefulWidget {
  MapSpotDerailsPage();

  @override
  _MapSpotDerailsPageState createState() => _MapSpotDerailsPageState();
}

class _MapSpotDerailsPageState extends State<MapSpotDerailsPage> {
  MapProvider _mapProvider;
  final borderDesign = BoxDecoration(
      border: Border(
          bottom: BorderSide(color: Colors.black12)
      )
  );

  @override
  Widget build(BuildContext context) {
    _mapProvider = Provider.of<MapProvider>(context);
    final size = MediaQuery.of(context).size;
    final double planContainingSpotsWidth = (size.width) * 2/5 * 4/5;
    final double planContainingSpotsHeight = (size.width) * 2/5;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0,),
                  Container(
                    height: 80,
                    child: _mapProvider.place.photos.length == 0
                        ? Container(
                      constraints: BoxConstraints.expand(),
                      color: Colors.black26,
                      child: Center(child: Text("画像がありません")),
                    )
                        : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mapProvider.place.photos.length,
                        itemBuilder: (BuildContext context, int index){
                          return Container(
                            width: MediaQuery.of(context).size.width / 3,
                            padding: EdgeInsets.all(2.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: GoogleMapApi().fullPhotoPath(_mapProvider.place.photos[index]),
                                progressIndicatorBuilder: (context, url, downloadProgress) =>
                                    Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
                                errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                                fit: BoxFit.fill,
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
//                          height: 40,
                              width: MediaQuery.of(context).size.width - 60,
                              child: Text(
                                _mapProvider.place.name ?? '',
                                style: TextStyle(fontSize: 20,) ,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if(_mapProvider.place.rating != null)
                              Row(
                                children: [
                                  RatingBar.builder(
                                    itemSize: 16,
                                    initialRating: _mapProvider.place.rating,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                                  ),
                                  Text(_mapProvider.place.rating.toString())
                                ],
                              ),
                          ],
                        ),
                      if(!_mapProvider.addFlag)
                        Container(
                            margin: EdgeInsets.only(top: 4.0,right: 4.0),
                            child: LikeButton(
                              size: 36,
                              onTap: _mapProvider.onLikeButtonTapped,
                              isLiked: _mapProvider.place.isFavorite,
                            )
                        ),
                      if(_mapProvider.addFlag)
                        Padding(
                          padding: EdgeInsets.only(top: 4.0,right: 4.0),
                          child: GestureDetector(
                            child: Icon(
                              Icons.add_circle_sharp,
                              size: 45.0 ,
                              color: Theme.of(context).primaryColor,
                            ),
                            onTap: (){
                              _mapProvider.addSpot();
//                              Navigator.of(context).pop(returnValue);
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  if(_mapProvider.place.formattedAddress != null)
                    Container(
                        decoration: borderDesign,
                        child: ListTile(
                          leading: Icon(Icons.add_location),
                          title: Text(_mapProvider.place.formattedAddress ?? ''),
                        )
                    ),
                  if(_mapProvider.place.formattedPhoneNumber != null)
                    Container(
                        decoration: borderDesign,
                        child: ListTile(
                          leading: Icon(Icons.phone),
                          title: Text(_mapProvider.place.formattedPhoneNumber ?? ''),
                        )
                    ),
                  if(_mapProvider.place.weekdayText != null)
                    Theme(
                      data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          accentColor: Colors.black54
                      ),
                      child: Container(
                        decoration: borderDesign,
                        child: ExpansionTile(
                          leading: Icon(Icons.access_time),
                          title: Row(
                            children: [
                              Text("営業時間"),
                              _mapProvider.place.nowOpen != null && _mapProvider.place.nowOpen ? Text("(営業中)") : Text("(営業時間外)")
                              //                              Icon(Icons.keyboard_arrow_down)
                            ],
                          ),
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if(_mapProvider.place.weekdayText != null)
                                  for(int i = 0; i < _mapProvider.place.weekdayText.length; i++)
                                    Container(
                                      padding: EdgeInsets.only(left: 74),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_mapProvider.place.weekdayText[i])
                                        ],
                                      ),
                                    )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  if(_mapProvider.planContainingSpots.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8.0,right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              margin: EdgeInsets.all(4.0),
                              child: Text("このスポットが入っているプラン")
                          ),
                          SizedBox(
                            height: planContainingSpotsHeight,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mapProvider.planContainingSpots.length,
                              itemBuilder: (BuildContext context,int index){
                                return Container(
                                  margin: EdgeInsets.only(right: 4.0),
                                  child: PlanItem(
                                    plan: _mapProvider.planContainingSpots[index],
                                    width: planContainingSpotsWidth,
                                    height: planContainingSpotsHeight,
                                  ),
                                );
//                                  return GestureDetector(
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if(_mapProvider.nearBySpots.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8.0,right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              margin: EdgeInsets.all(4.0),
                              child: Text("周辺のスポット")
                          ),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _mapProvider.nearBySpots.length > 5 ? 5 : _mapProvider.nearBySpots.length,
                                itemBuilder: (BuildContext context,int index){
                                  return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context,rootNavigator: true).push(
                                            MaterialPageRoute(
                                              builder: (context) => SpotDetailsPage(
                                                  placeId: _mapProvider.nearBySpots[index].placeId
                                              ),
                                            )
                                        );
//                                        Navigator.push(
//                                            context,
//                                            MaterialPageRoute(
//                                              builder: (context) => SpotDetailsPage(
//                                                  placeId: _mapProvider.nearBySpots[index].placeId
//                                              ),
//                                            )
//                                        );
                                      },
                                      child: Container(
                                        width: 100,
                                        margin: EdgeInsets.only(right: 4.0),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6.0),
                                                clipBehavior: Clip.antiAlias,
                                                child: Image.network(
                                                  GoogleMapApi().fullPhotoPath(_mapProvider.nearBySpots[index].photos[0].photoReference ?? ''),
                                                  fit: BoxFit.fill,
                                                  width: 100,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                _mapProvider.nearBySpots[index].name,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                  );
                                }
                            ),
                          )
                        ],
                      ),
                    ),
                  if(_mapProvider.place.reviews != null)
                    Padding(
                      padding: EdgeInsets.only(left: 8.0,right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              margin: EdgeInsets.all(4.0),
                              child: Text("レビュー")
                          ),
                          Container(
                            child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                itemCount: _mapProvider.place.reviews.length,
                                itemBuilder: (BuildContext context, int index){
                                  return InkWell(
                                    onTap: (){
                                      showReviewDialog(_mapProvider.place.reviews[index]);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 4.0),
                                      padding: EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _mapProvider.place.reviews[index].authorName,
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              RatingBar.builder(
                                                itemSize: 12,
                                                initialRating: _mapProvider.place.reviews[index].rating.toDouble(),
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemBuilder: (context, _) => Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _mapProvider.place.reviews[index].text ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.white60, // button color
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          splashColor: Colors.black12, // inkwell color
                          child: Icon(Icons.arrow_back),
                          onTap: () { Navigator.pop(context); },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

//      }
  }

  void showReviewDialog(review) {
    var formatter = DateFormat('yyyy/MM/dd(E) HH:mm', "ja_JP");
    var formatted = formatter.format(DateTime.fromMillisecondsSinceEpoch(review.time * 1000)); // DateからString

    showDialog(
        context: context,
        builder: (context){
          return SimpleDialog(
            children: [
              Container(
                padding: EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.authorName,style: TextStyle(fontWeight: FontWeight.w600),),
                    Text(formatted,style: TextStyle(fontSize: 10),),
                    Text(review.text)
                  ],
                ),
              )
            ],
          );
        }
    );
  }


}
