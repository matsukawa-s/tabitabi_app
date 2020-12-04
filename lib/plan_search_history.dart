import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabitabi_app/plan_search_provider.dart';

class PlanSearchHistoryPage extends StatelessWidget {
  // textfield の　コントローラー
  var _searchWord = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var _searchWord =
    TextEditingController(text: Provider.of<PlanSearchProvider>(context).keyword);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          autofocus: true,
          controller: _searchWord,
          onSubmitted: (String value) {
            Provider.of<PlanSearchProvider>(context,listen: false).setKeyword(value);
            Navigator.of(context).pop();
          },
//          cursorColor: iconColor,
          decoration: InputDecoration(
//              border: OutlineInputBorder(
//                borderRadius: BorderRadius.circular(25.0),
//                  borderSide: BorderSide(
//                    color: Colors.white,
//                  ),
//              ),
            border: InputBorder.none,
            filled: true,
            hintStyle: TextStyle(color: Colors.grey[500]),
            hintText: "Type in your text",
            suffixIcon: IconButton(
              onPressed: () => _searchWord.clear(),
              icon: Icon(Icons.clear),
            ),
//              fillColor: Colors.grey[100],
          ),
        ),
      ),
      body: Text("PlanSearchHistory"),
    );
  }
}
