import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'widget_to_image_converter.dart';

class ShareProvider {
  Future<void> shareImageAndText(
      String text, GlobalKey globalKey) async {
    final bytes = await WidgetToImageConverter().exportToImage(globalKey);
    await Share.file(
        'shared image', 'share.png', bytes.buffer.asUint8List(), 'image/png',
        text: text);
  }
}