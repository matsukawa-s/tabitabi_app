import 'package:amazon_s3_cognito/amazon_s3_cognito.dart';
import 'package:amazon_s3_cognito/aws_region.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final poolId = DotEnv().env['PoolID'];
final awsFolderPath = DotEnv().env['AwsFolderPath'];
final bucketName = DotEnv().env['BucketName'];

class AwsS3{
  Future<String> uploadImage(String path, String folderName) async{
    //画像そのまま保存すると重いのでサイズを落とす
    List<int> result = await FlutterImageCompress.compressWithFile(   // ②
      path,
      minWidth: 1236,
      minHeight: 1236,
      quality: 60,
    );

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/compress';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.png';
    File file = File(filePath);
    await file.writeAsBytes(result);

    //保存先のパス
    String fileName = "$folderName/${DateTime.now().millisecondsSinceEpoch}.png";
    String uploadedImageUrl = await AmazonS3Cognito.upload(
        file.path,
        bucketName,
        poolId,
        fileName,
        AwsRegion.US_EAST_1,
        AwsRegion.US_EAST_1
    );
    print("upload:" + uploadedImageUrl);
    //なんか実際アクセスするときのURLは違うらしい？
    uploadedImageUrl = "https://"+ bucketName + ".s3.amazonaws.com/" + fileName;
    print("upload2:" + uploadedImageUrl);

    return uploadedImageUrl;
  }

  Future<String> deleteImage(String imageUrl) async{
    String url = imageUrl.replaceFirst("https://" + bucketName +".s3.amazonaws.com/", "");
    print(url);
    String result = await AmazonS3Cognito.delete(
        bucketName,
        poolId,
        url,
        AwsRegion.US_EAST_1,
        AwsRegion.US_EAST_1);

    return result;
  }

}