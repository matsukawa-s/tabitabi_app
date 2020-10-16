import 'package:flutter/cupertino.dart';

class ResultProvider extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}