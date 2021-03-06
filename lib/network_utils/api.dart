import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network{
//  final _baseUrl = 'http://10.0.2.2:8000/';

  final _baseUrl = 'http://${DotEnv().env['API_ADDRESS']}/';


// アンドロイドエミュレーターの場合10.0.2.2:8000を使用
  //final String _url = 'http://10.0.2.2:8000/api/';
// IOSシミュレータの場合はlocalhostを使用

  final String _url = 'http://${DotEnv().env['API_ADDRESS']}/api/';


  static var token;

  Future<void> _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    token = jsonDecode(localStorage.getString('token'))['token'];
  }

  String getUrl(route){
    return _url + route;
  }

  get baseUrl => _baseUrl;

  get getMultiHeaders => _multiHeaders();

  String imagesDirectory(selectImageDirectory){
    var url = '${_baseUrl}storage/' + selectImageDirectory + '/';
    return url;
  }

  //認証用
  authData(data,apiUrl) async{
    var fullUrl = _url + apiUrl;
    return await http.post(
        fullUrl,
        body: jsonEncode(data),
        headers: _setHeaders()
    );
  }

  //POST（データ保存用）
  postData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    await _getToken();
    return await http.post(
        fullUrl,
        body: jsonEncode(data),
        headers: _setHeaders()
    );
  }

  //GET（データ取得用）
  getData(apiUrl) async {
    var fullUrl = _url + apiUrl;
    await _getToken();
    return await http.get(
        fullUrl,
        headers: _setHeaders()
    );
  }

  //POST（画像とデータ送信）
  postUploadImage(data,File file,apiUrl) async{
    var fullUrl = _url + apiUrl;
    await _getToken();

    var request = http.MultipartRequest('POST', Uri.parse(fullUrl));
    request.fields['data'] = jsonEncode(data);
    if(file != null) {
      var pic = await http.MultipartFile.fromPath("image", file.path);
      request.files.add(pic);
    }
    request.headers.addAll(_setHeaders());

    return await request.send();
  }

  _setHeaders() => {
    'Content-type' : 'application/json',
    'Accept' : 'application/json',
    'Authorization' : 'Bearer $token'
  };

  _multiHeaders() => {
    'Accept' : 'application/json',
    'Authorization' : 'Bearer $token'
  };


}