import 'package:flutter/material.dart';
import 'hiveDb.dart' as db;
import 'package:flutter/cupertino.dart';
import 'Questions.dart';

class Einstellungen extends StatefulWidget {
  const Einstellungen({Key? key}) : super(key: key);

  @override
  State<Einstellungen> createState() => _EinstellungenState();
}

class _EinstellungenState extends State<Einstellungen> {
  static const keyFontziseNormalFont = "keyFontziseNormalFont";
  static const keyQuestion = "KeyQuestionFontSize";
  double fontSizeAnswer = 15;
  double fontSizeQuestion = 17;

  getfontSize() async {
    try {
      fontSizeQuestion = double.parse(await db.getData(keyQuestion));
      fontSizeAnswer = double.parse(await db.getData(keyFontziseNormalFont));
      setState(() {});
    } catch (e) {
      throw UnimplementedError(e.toString());
    }
  }

  resetDB() {
    showDialog<String>(context: context, builder: (BuildContext context) => const ErrorHandler());
  }

  @override
  void initState() {
    getfontSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("Schriftgröße Auswählen:"),
        Slider(
          value: fontSizeAnswer,
          min: 10,
          max: 20,
          divisions: 10,
          label: '${fontSizeAnswer.round()}',
          onChanged: (value) async {
            setState(() {
              fontSizeAnswer = value;
            });
            await db.setData(keyFontziseNormalFont, value.toString());
            await db.setData("chnageFontsize", "true");
          },
        ),
        const Text("Schriftgröße der Fragen:"),
        Slider(
          value: fontSizeQuestion,
          min: 13,
          max: 25,
          divisions: 12,
          label: '${fontSizeQuestion.round()}',
          onChanged: (value) async {
            setState(() {
              fontSizeQuestion = value;
            });
            await db.setData(keyQuestion, value.toString());
            await db.setData("chnageFontsize", "true");
          },
        ),
        const SizedBox(
          height: 30,
        ),
        CupertinoButton(
          onPressed: () async {
            await resetDB();
          },
          child: const Text("Datenbank zurücksetzen"),
        )
      ],
    )));
  }
}

class ErrorHandler extends StatefulWidget {
  const ErrorHandler({Key? key}) : super(key: key);

  @override
  _ErrorHandler createState() => _ErrorHandler();
}

class _ErrorHandler extends State<ErrorHandler> {
  Future resetDB() async {
    await CatalogDatabase.instance.deleteAll();
    await db.setData("DataExists", "false");

    Navigator.pop(context);
  }

  @override
  void initState() {
    //checkConnection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Benachrichtigung'),
      content: const Text("datenbank wirklich löschen? Alle lernschritte gehen verloren"),
      actions: <Widget>[
        CupertinoDialogAction(
            child: const Text("Abbrechen"),
            onPressed: () {
              Navigator.pop(context);
            }),
        CupertinoDialogAction(
            child: const Text(
              "Löschen",
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
            onPressed: () {
              resetDB();
            }),
      ],
    );
  }
}
