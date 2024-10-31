import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'Question.dart';

Map<String, String> catalogs = {
  'data-binnen': 'https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragencatalog-Binnen/Spezifische-Fragen-Binnen/Spezifische-Fragen-Binnen-node.html',
  'data-see': 'https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragencatalog-See/Spezifische-Fragen-See/Spezifische-Fragen-See-node.html',
  'data-basis': 'https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Fragencatalog-Binnen/Basisfragen/Basisfragen-node.html'
};

main() async {
  for (var key in catalogs.keys) {
    await parseCatalog(key, catalogs[key]!);
  }
}

parseCatalog(String directory, String urlStr) async {
  Uri url = Uri.parse(urlStr);

  // create directory
  await Directory(directory).create(recursive: true);

  try {
    final response = await http.Client().get(url);

    if (response.statusCode == 200) {
      var document = parse(response.body);
      var elements = document.getElementsByClassName("elwisOL-lowerLiteral");
      var ant = document.querySelectorAll("p");

      List<QuestionImage> fragen = [];
      List<QuestionElement> allElements = [];
      List<Answer> antworten = [];
      int anz = 0;

      Future<String> isbild(val) async {
        if (val.getElementsByTagName("img").isNotEmpty) {
          anz++;
          var test = val.getElementsByTagName("img");
          String alt = test[0].attributes["src"] ?? "";

          try {
            var res = await http.get(Uri.parse(alt));
            String tempString = alt.split("/").last.split(".gif")[0];
            // String dir = test[0].attributes["title"] ?? "";

            await File('$directory/$tempString.gif').writeAsBytes(res.bodyBytes);
            return "$directory/$tempString.gif";
          } catch (e) {
            print("Fehler beim Bildladen: ${e.toString()}");
            return "";
          }
        } else {
          return "";
        }
      }

      for (int i = 0; i < ant.length; i++) {
        if (ant[i].text.contains(RegExp(r"\d+\.")) && !ant[i].text.contains("Stand: 01")) {
          fragen.add(QuestionImage(question: ant[i].text, imagepath: await isbild(ant[i + 1])));
        }
      }

      for (final element in elements) {
        for (int r = 0; r < 4; r++) {
          antworten.add(Answer(type: r == 0, text: element.children[r].text));
        }
      }
      int y = 0;
      for (final val in fragen) {
        List<Answer> temp = [];
        for (int u = 0; u < 4; u++) {
          temp.add(antworten[y + u]);
        }
        y += 4;
        allElements.add(QuestionElement(question: val.question, answer: temp, count: 0, image: val.imagepath));
      }

      print("Anzahl Bilder: $anz");

      allElements = allElements.map((element) {
        element.question = element.question.replaceAll(RegExp(r'(\r|\n)+'), ' ').trim();

        element.answer = element.answer.map((answer) {
          answer.text = answer.text.replaceAll(RegExp(r'(\r|\n)+'), ' ').trim();
          return answer;
        }).toList();

        return element;
      }).toList();

      String objects = jsonEncode(allElements);
      objects = objects.replaceAll(RegExp(r'(\r|\n)+'), ' ').trim();
      await File('$directory/data.json').writeAsString(objects);
    } else {
      print("Fehler beim Laden der Seite: ${response.statusCode}");
    }
  } catch (e) {
    print("Fehler: ${e.toString()}");
  }
}
