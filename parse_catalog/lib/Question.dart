import 'dart:convert';

List<QuestionElement> catalogFromJson(String str) => List<QuestionElement>.from(json.decode(str).map((x) => QuestionElement.fromJson(x)));
String catalogToJson(QuestionElement data) => json.encode(data.toJson());

class QuestionElement {
  QuestionElement({
    required this.question,
    required this.answer,
    required this.count,
    this.image,
  });
  String question;
  List<Answer> answer;
  int count;
  String? image;

  factory QuestionElement.fromJson(Map<String, dynamic> json) => QuestionElement(
        question: json["Question"],
        answer: List<Answer>.from(json["Answers"].map((x) => Answer.fromJson(x))),
        count: json["Count"],
        image: json["Image"],
      );

  Map<String, dynamic> toJson() => {
        "Question": question,
        "Count": count,
        "Image": image ?? "",
        "Answers": List<dynamic>.from(answer.map((x) => x.toJson())),
      };
}

class QuestionImage {
  QuestionImage({required this.question, required this.imagepath});
  String question;
  String imagepath;
}

class Answer {
  Answer({required this.type, required this.text});
  bool type;
  String text;

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        type: json["type"],
        text: json["text"],
      );
  Map<String, dynamic> toJson() => {"type": type, "text": text};
}
