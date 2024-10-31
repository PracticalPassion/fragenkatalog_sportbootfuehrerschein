import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'Questions.dart';
import 'hiveDb.dart' as db;
import 'CardMode.dart';

class ListOfCatalogs extends StatefulWidget {
  const ListOfCatalogs({Key? key}) : super(key: key);

  @override
  State<ListOfCatalogs> createState() => _ListOfCatalogsState();
}

class _ListOfCatalogsState extends State<ListOfCatalogs> {
  static const String path = "data";

  List<Catalog> catalogs = [];
  List<QuestionElement> see = [], binnen = [], basis = [];

  int laenge = 0, pageIndex = 0;
  bool loading = false;

  Future deleteAll() async {
    await Future.wait([CatalogDatabase.instance.deleteAll(), db.setData("DataExists", "false")]);
  }

  Future<void> checkOnUpdate() async {
    final dataExists = await db.getData("DataExists");

    if (dataExists == "true") {
      await _updateExistingData();
    } else {
      setState(() => loading = true);
      await _initializeAndLoadData();
    }

    setState(() => loading = false);
    getQuestion();
  }

  Future<void> _updateExistingData() async {
    await _loadDataFromDatabase();
  }

  Future<void> _initializeAndLoadData() async {
    final questionSee = await _loadJsonFile('$path/data-see/data.json');
    final questionBinnen = await _loadJsonFile('$path/data-binnen/data.json');
    final questionBasis = await _loadJsonFile('$path/data-basis/data.json');

    final List<QuestionElement> tempBasis = catalogFromJson(questionBasis, "Basisfragen");
    final List<QuestionElement> tempBinnen = catalogFromJson(questionBinnen, "Binnen");
    final List<QuestionElement> qSea = catalogFromJson(questionSee, "See");

    await Future.wait([
      CatalogDatabase.instance.createData(tempBasis),
      CatalogDatabase.instance.createData(tempBinnen),
      CatalogDatabase.instance.createData(qSea),
      db.setData("DataExists", "true"),
    ]);

    await _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    final results = await Future.wait([
      CatalogDatabase.instance.getAllDataByCatalog("See"),
      CatalogDatabase.instance.getAllDataByCatalog("Binnen"),
      CatalogDatabase.instance.getAllDataByCatalog("Basisfragen"),
    ]);

    see = results[0];
    binnen = results[1];
    basis = results[2];
  }

  Future<String> _loadJsonFile(String filePath) async {
    return await DefaultAssetBundle.of(context).loadString(filePath);
  }

  refresh() {
    catalogs.removeRange(0, catalogs.length);
    setState(() {});
    checkOnUpdate();
  }

  Future<void> getQuestion() async {
    var allQuestions = [...basis, ...see, ...binnen];
    allQuestions.shuffle();

    Map<int, List<QuestionElement>> categorizedQuestions = {
      0: [],
      1: [],
      2: [],
      3: [],
      4: [],
    };

    for (var element in allQuestions) {
      categorizedQuestions[element.count.clamp(0, 4)]?.add(element);
    }

    setState(() {
      catalogs.addAll([
        Catalog(id: "Katalog Basis", countCatalog: "0", questionElement: basis),
        Catalog(id: "Katalog Binnen", countCatalog: "0", questionElement: binnen),
        Catalog(id: "Katalog See", countCatalog: "0", questionElement: see),
        // add categorized questions to catalogs
        ...List.generate(
            5,
            (index) => Catalog(
                  id: "$index-mal",
                  countCatalog: "0",
                  questionElement: categorizedQuestions[index]!,
                  hasLeading: true,
                  color: index == 0 ? Colors.red : Colors.green[900 - (index * 200)],
                ))
      ]);
      loading = false;
    });

    laenge = allQuestions.length;
  }

  @override
  void initState() {
    super.initState();
    //deleteAll();
    checkOnUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CupertinoNavigationBar(
          middle: Text("Kataloge"),
        ),
        body: loading == false
            ? ListView.builder(
                itemCount: catalogs.length,
                itemBuilder: (context, index) {
                  return (ListTile(
                    leading: catalogs[index].hasLeading == true ? Icon(CupertinoIcons.circle_filled, color: catalogs[index].color) : const Icon(CupertinoIcons.book_circle),
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => CardMode(catalogs[index]))).then((value) {
                        refresh();
                      });
                    },
                    title: Text(catalogs[index].id),
                    trailing: const Icon(CupertinoIcons.chevron_forward),
                    subtitle: Text(catalogs[index].questionElement.length.toString() + "/" + laenge.toString()),
                  ));
                })
            : const Center(child: CupertinoActivityIndicator()));
  }
}
