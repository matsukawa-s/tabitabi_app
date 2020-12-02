import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class TagData{
  int tagId;
  String tagName;

  TagData(this.tagId, this.tagName);
}

class TagDataProvider extends ChangeNotifier{
  List<TagData> _tagData = [];

  List<TagData> get tagData => _tagData;

  TagData getTagData(int index){
    return _tagData[index];
  }

  void addTagData(TagData data){
    _tagData.add(data);
  }

  void removeTagData(int index){
    _tagData.removeAt(index);
  }

  void clearTagData(){
    _tagData.clear();
  }
}