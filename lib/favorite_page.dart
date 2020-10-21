import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigationbar_provider.dart';

class FavoritePage extends StatelessWidget {
  final String title;

  FavoritePage({@required this.title});

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.title;
    return TabBarView(
        children: Provider.of<NavigationBarProvider>(context).tabs.map((tab) => tab.widget).toList()
    );
  }
}