//import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'dart:io';
//import 'dart:html';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

import 'package:qr_flutter/qr_flutter.dart';

class InvitePlanPage extends StatelessWidget {
  final plans;

  InvitePlanPage(this.plans);

  @override
  Widget build(BuildContext context) {
    print(plans);
    return Scaffold(
      appBar: AppBar(
        title: Text("プランコード"),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.7),
        actions: [
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                if(Platform.isAndroid){
                  final links = await _createDynamicLink();
                  Share.share(links.toString());
                }
//                if(Platform.isIOS){
//                  final snackBar = SnackBar(
//                    content: Text('お知らせ！'),
//                  );
//                  Scaffold.of(context).showSnackBar(snackBar);
//                }
              }
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImage(
              data: plans["plan_code"],
              version: QrVersions.auto,
              size: 200.0,
              embeddedImage: AssetImage('images/logo_square.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size(25, 25),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plans["plan_code"],
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 24,
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () => clipboardCopy()
                )
              ],
            )

          ],
        ),
      ),
    );
  }

  clipboardCopy() async{
    final data = ClipboardData(text: plans["plan_code"]);
    await Clipboard.setData(data);
    print("コピーしたよ");
  }

  _createDynamicLink() async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://tabitabiapp.page.link',
      link: Uri.parse('https://google.com/?id=${plans['id']}'),
      androidParameters: AndroidParameters(
        packageName: 'com.sk3a.tabitabi_app',
        minimumVersion: 0,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.sk3a.tabitabi_app',
        minimumVersion: '0',
      ),
    );

    final ShortDynamicLink shortLink = await parameters.buildShortLink();
    final Uri dynamicUrl = shortLink.shortUrl;

    return dynamicUrl.toString();

  }
}
