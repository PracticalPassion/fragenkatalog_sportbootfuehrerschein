import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'Catalogs.dart';
import 'Questions.dart';
import 'hiveDb.dart' as db;
import 'Settings.dart';

class Front extends StatefulWidget {
  const Front({Key? key}) : super(key: key);

  @override
  State<Front> createState() => _FrontState();
}

class _FrontState extends State<Front> {
  List<Catalog> catalogs = [];
  int pageIndex = 0;
  init() async {
    var check = await db.getData("initialized");

    if (check == "" || check != "true") {
      const keyFontziseNormalFont = "keyFontziseNormalFont";
      const keyQuestion = "KeyQuestionFontSize";
      await db.setData(keyFontziseNormalFont, "14");
      await db.setData(keyQuestion, "16");
      await db.setData("initialized", "true");
    }
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  List<Widget> pagelist() {
    return const [ListOfCatalogs(), Einstellungen()];
  }

  List<BottomNavigationBarItem> navBarItems() {
    return [
      const BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Kataloge'),
      const BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Einstellungen'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: pagelist()[pageIndex],
        bottomNavigationBar: BottomNavigationBar(
          //selectedItem,
          currentIndex: pageIndex,
          onTap: (value) {
            setState(() {
              pageIndex = value;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: navBarItems(),
        ));
  }
}
