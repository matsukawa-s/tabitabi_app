import 'package:flutter/material.dart';
import 'package:tabitabi_app/model/spot_model.dart';
import 'package:tabitabi_app/network_utils/google_map.dart';
import 'package:tabitabi_app/spot_details_page.dart';

class SpotItem extends StatelessWidget {
  final double width;
  final double height;
  final Spot spot;

  SpotItem({
    this.width = double.infinity,
    this.height,
    this.spot
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final defaultWidth = size.width / 3;
    final defaultHeight = size.width / 3;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SpotDetailsPage(
                spotId: spot.spotId,
                placeId: spot.placeId,
              )
          )
      ),
      child: Container(
        width: width ?? defaultWidth,
        height: height ?? defaultHeight,
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    GoogleMapApi().fullPhotoPath(spot.imageUrl),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                spot.spotName,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}
