import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qr_flutter/qr_flutter.dart';

class InvitePlanPage extends StatelessWidget {
  final plans;

  InvitePlanPage(this.plans);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("プランコード"),
        backgroundColor: Colors.white.withOpacity(0.7),
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
//              embeddedImage: AssetImage('images/logo_square.jpg'),
//              embeddedImageStyle: QrEmbeddedImageStyle(
//                size: Size(40, 40),
//              ),
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
}
