import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

List<QuestionElement> catalogFromJson(String str, String catalogstr) => List<QuestionElement>.from(json.decode(str).map((x) => QuestionElement.fromJson(x, catalogstr)));

class Catalog {
  Catalog({
    required this.id,
    required this.countCatalog,
    required this.questionElement,
    this.hasLeading,
    this.color,
  });

  String id;
  String countCatalog;
  bool? hasLeading;
  Color? color;
  List<QuestionElement> questionElement;

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        id: json["id"],
        countCatalog: json["CountCatalog"],
        questionElement: List<QuestionElement>.from(json["QuestionElement"].map((x, str) => QuestionElement.fromJson(x, str))),
      );
}

class QuestionElement {
  QuestionElement({
    this.id,
    required this.question,
    required this.answer,
    required this.count,
    required this.catalog,
    this.image,
    this.currentSelectedItem = 5,
    this.showAnswer = false,
    this.wasRight = false,
    this.checkColor = Colors.black,
  });
  int? id;
  String question;
  String catalog;
  List<Answer> answer;
  int count;
  int? currentSelectedItem;
  String? image;
  bool showAnswer;
  bool wasRight;
  Color checkColor;

  factory QuestionElement.fromJson(Map<String, dynamic> json, String catalog) => QuestionElement(
        question: json["Question"],
        catalog: catalog,
        answer: List<Answer>.from(json["Answers"].map((x) => Answer.fromJson(x))),
        count: json["Count"],
        image: json["Image"],
      );

  factory QuestionElement.fromJsonDB(Map<String, dynamic> json, List<Answer> ant) =>
      QuestionElement(question: json["Question"], id: json["id"], catalog: json["Catalog"], answer: ant, count: json["Count"], image: json["Image"]);

  Map<String, Object?> toJasonDB() => {QuestionFields.count: count, QuestionFields.catalog: catalog, QuestionFields.question: question, QuestionFields.image: image};
}

class Answer {
  Answer({this.id, required this.type, required this.text, this.questionID});
  int? id;
  bool type;
  String text;
  int? questionID;

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        type: json["type"],
        text: json["text"],
      );
  factory Answer.fromJsonDB(Map<String, dynamic> json) =>
      Answer(type: json[AnswersFields.type] == 1 ? true : false, text: json[AnswersFields.answer] as String, questionID: json[AnswersFields.fargenID] as int, id: json[AnswersFields.id] as int);

  Map<String, Object?> toJasonDB(fkKey) => {AnswersFields.type: type ? 1 : 0, AnswersFields.answer: text, AnswersFields.fargenID: fkKey};
}

class CatalogDatabase {
  static final CatalogDatabase instance = CatalogDatabase._init();
  CatalogDatabase._init();
  static Database? _database;

  Future<Database?> get databsase async {
    if (_database != null) return _database!;
    _database = await _initDB("sportbootCatalog.db");
    return _database;
  }

  Future<Database> _initDB(String file) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, file);
    return await openDatabase(path, version: 3, onCreate: _createDb);
  }

  Future _updatedb(Database db, int oldVersion, int newversion) async {
    const textType = "TEXT NULL";

    if (oldVersion < newversion) {
      // you can execute drop table and create table
      db.execute('''ALTER TABLE question ADD COLUMN ${QuestionFields.catalog} $textType''');
    }
  }

  Future _createDb(Database db, int version) async {
    // const idType = "INTEGER PRIMARY KEY";
    const idTypeAi = "INTEGER PRIMARY KEY AUTOINCREMENT";
    const textType = "TEXT NOT NULL";
    const countType = "INTEGER";
    const imageType = "TEXT NULL";
    const boolType = "BOOLEAN NOT NULL";
    const fkType = "FOREIGN KEY(${AnswersFields.fargenID}) REFERENCES $tableQuestion(${QuestionFields.id})";

    await db.execute('''
    create table question (
      ${QuestionFields.id} $idTypeAi,
      ${QuestionFields.question} $textType,
      ${QuestionFields.count} $countType,
      ${QuestionFields.image} $imageType,
      ${QuestionFields.catalog} $textType
    )
      ''');

    await db.execute('''
    create table answers (
      ${AnswersFields.id} $idTypeAi,
      ${AnswersFields.type} $boolType,
      ${AnswersFields.answer} $textType,
      ${AnswersFields.fargenID} $countType,
$fkType
    )''');
  }

  Future clode() async {
    final db = await instance.databsase;
    db!.close();
  }

  Future createData(List<QuestionElement> daten) async {
    for (var element in daten) {
      int id = await createQuestion(element);

      for (var x in element.answer) {
        await createAnswer(x, id);
      }
    }
  }

  Future<int> createQuestion(QuestionElement element) async {
    final db = await instance.databsase;
    final id = await db!.insert(tableQuestion, element.toJasonDB());
    return id;
  }

  Future createAnswer(Answer element, int fkID) async {
    final db = await instance.databsase;
    await db!.insert(answersTable, element.toJasonDB(fkID));
  }

  // Update wrong and Incomplete
  Future updateImagePathSee(List<QuestionElement> daten) async {
    final db = await instance.databsase;

    for (QuestionElement element in daten) {
      if ((element.image ?? '').isNotEmpty) {
        await db!.rawUpdate('''UPDATE $tableQuestion SET ${QuestionFields.image} = '${element.image}'  WHERE  ${QuestionFields.question} = '${element.question}' ''');
      }
    }
  }

  Future<List<QuestionElement>> getAllDataByCatalog(String str) async {
    final db = await instance.databsase;
    final question = await db!.rawQuery('''SELECT * FROM $tableQuestion where ${QuestionFields.catalog} = ? ''', [str]);
    final answers = await db.query(answersTable);
    List<Answer> ant = answers.map((e) => Answer.fromJsonDB(e)).toList();
    List<QuestionElement> el = question.map((json) => QuestionElement.fromJsonDB(json, matchedItems(json["id"] as int, ant))).toList();
    return el;
  }

  Future<List<QuestionElement>> getAllQuestion() async {
    final db = await instance.databsase;
    final question = await db!.query(tableQuestion);
    final answers = await db.query(answersTable);
    List<Answer> ant = answers.map((e) => Answer.fromJsonDB(e)).toList();
    List<QuestionElement> el = question.map((json) => QuestionElement.fromJsonDB(json, matchedItems(json["id"] as int, ant))).toList();
    return el;
  }

  matchedItems(int id, List<Answer> ant) {
    List<Answer> rightAnswers = [];

    for (var element in ant) {
      if (element.questionID == id) {
        rightAnswers.add(element);
      }
    }
    return rightAnswers;
  }

  Future deleteAll() async {
    final db = await instance.databsase;
    await db!.delete(tableQuestion);
    await db.delete(answersTable);
  }

  Future<int> updateKorrCount(int id, int count) async {
    count++;
    final db = await instance.databsase;
    await db!.rawUpdate('''UPDATE $tableQuestion set ${QuestionFields.count} = ? where ${QuestionFields.id} = ?''', [count, id]);
    return count;
  }

  Future<int> resetCount(int id, int count) async {
    count = 0;
    final db = await instance.databsase;
    await db!.rawUpdate('''UPDATE $tableQuestion set ${QuestionFields.count} = ? where ${QuestionFields.id} = ?''', [count, id]);
    return count;
  }
}

const String tableQuestion = "question";
const String answersTable = "answers";

class QuestionFields {
  static const String id = "id";
  static const String question = "Question";
  static const String count = "Count";
  static const String image = "Image";
  static const String catalog = "Catalog";
}

class AnswersFields {
  static const String id = "id";
  static const String answer = "Answer";
  static const String type = "Type";
  static const String fargenID = "ID_Question";
}
