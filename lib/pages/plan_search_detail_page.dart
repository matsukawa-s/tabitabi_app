import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/model/plan_search_model.dart';

class PlanSearchDetailPage extends StatelessWidget {
  final double space = 15;
  Color backColor = Colors.grey[200];
  Color iconColor = Colors.orange[300];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          color: iconColor,
          icon: new Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('検索フィルタ'),
      ),
      body: Container(
        color: backColor,
        padding: EdgeInsets.all(space),
//        height: ,
        child: Container(
//          height: 100,
          child: Consumer<PlanSearchModel>(
            builder: (_,model, __){
              return Container(
                child: ListView(
                  children: [
                    _listTitle('並び替え'),
                    _listItem('アップロード', model,context,0),
                    _listItem('お気に入り数', model,context,1),
                    _listItem('閲覧数', model,context,2),
                    _listItem('参考数', model,context,3),
                  ],
                ),
              );
            }
          ),
        ),
//        child: ListView.separated(
//            itemBuilder: (BuildContext context, int index) {
//              return _listItem(context,index);
//            },
//            separatorBuilder: (BuildContext context, int index) {
//              return _separatorItem();
//            },
//            itemCount: 1
//        ),
      ),
    );
  }

  Widget _listTitle(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
//        border: Border(
//          bottom: BorderSide(
//            color: Colors.black54,
//            width: 1,
//          ),
//        ),
      ),
      child: ListTile(
        title: Row(
          children: [
            Icon(Icons.import_export,color: iconColor,),
            SizedBox(
              width: 12,
            ),
            Text(
              title,
              style: TextStyle(
                  color:Colors.black,
                  fontSize: 18.0
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listItem(String name, model,context,index) {
    var check;
    if(model.sortIndex == index){
      check = Icon(Icons.check, color: iconColor);
    }

    return Container(
      color: Colors.white,
      child: ListTile(
        title: Text(
          name,
          style: TextStyle(
              color:Colors.black,
              fontSize: 18.0
          ),
        ),
        trailing: check,
        onTap: () {
          // 選択されたインデックスでプランリスト更新
          model.setSort(index);

          // プラン検索ページに戻る
          Navigator.pop(context);
          print(model.sortIndex);
        }, // タップ
      ),
    );
  }

  Widget _separatorItem() {
    return Container(
      height: space,
//      color: Colors.orange,
    );
  }
}
