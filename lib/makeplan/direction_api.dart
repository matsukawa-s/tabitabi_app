import 'package:google_directions_api/google_directions_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];

final _type = [TravelMode.walking, TravelMode.driving, TravelMode.transit];

class DirectionApi{

  Future<String> getDirection(String origin, String destination, int type) async{
    DirectionsService.init(_kGoogleApiKey);

    final directionsService = DirectionsService();

    final request = DirectionsRequest(
      origin: origin,
      destination: destination,
      travelMode: _type[type],
    );

    String trafficTime = "0分";

    await directionsService.route(request, (DirectionsResult response, DirectionsStatus status) {
      if(status == DirectionsStatus.ok){
        print(status.toString());
        print(response.routes[0].legs[0].distance.text);
        print(response.routes[0].legs[0].duration.text);
        trafficTime = response.routes[0].legs[0].duration.text;
      }else{
        print(status.toString());
      }
    });
    return trafficTime;
  }
}