import 'package:flutter_dotenv/flutter_dotenv.dart';

const detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json?';

class GoogleMapApi{
  final _kGoogleApiKey = DotEnv().env['Google_API_KEY'];
  final _placePhotoBaseUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&maxheight=150';

  String fullPhotoPath(String reference){
    return _placePhotoBaseUrl + '&photoreference=${reference}' + '&key=${_kGoogleApiKey}';
  }

  searchDetails(String placeId){
//    place_id=ChIJN1t_tDeuEmsRUsoyG83frY4&fields=name,rating,formatted_phone_number&key=YOUR_API_KEY
  }
}