import 'dart:async';
import 'hiveDb.dart' as db;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'Questions.dart';

class CardMode extends StatefulWidget {
  final Catalog catalog;
  const CardMode(this.catalog, {Key? key}) : super(key: key);

  @override
  State<CardMode> createState() => _CardModeState();
}

class _CardModeState extends State<CardMode> {
  Timer? timer;
  double fontSizeAnswer = 14;
  double fontSizeQuestion = 16;

  static const keyFontziseNormalFont = "keyFontziseNormalFont";
  static const keyQuestion = "KeyQuestionFontSize";

  getfontSize() async {
    var change = await db.getData("chnageFontsize");

    if (change == null) {
      await db.setData("chnageFontsize", "false");
    }

    if (change == "true") {
      fontSizeQuestion = double.parse(await db.getData(keyQuestion));
      fontSizeAnswer = double.parse(await db.getData(keyFontziseNormalFont));
      await db.setData("chnageFontsize", "false");
      setState(() {});
    }
  }

  static const countdownDuration = Duration(minutes: 10);
  Duration duration = const Duration();
  bool countDown = false;

  @override
  void initState() {
    getfontSize();
    super.initState();
    reset();

    for (var element in widget.catalog.questionElement) {
      element.answer.shuffle();
    }
  }

  void reset() {
    if (countDown) {
      setState(() => duration = countdownDuration);
      startTimer();
    } else {
      setState(() => duration = const Duration());
      startTimer();
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());
  }

  void addTime() {
    const addSeconds = 1;
    setState(() {
      final seconds = duration.inSeconds + addSeconds;
      if (seconds < 0) {
        timer?.cancel();
      } else {
        duration = Duration(seconds: seconds);
      }
    });
  }

  void stopTimer({bool resets = true}) {
    if (resets) {
      reset();
    }
    setState(() => timer?.cancel());
  }

  late Size deviceSize;
  late double scaleY;
  bool checked = false;
  static const _kDuration = Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;
  final _controller = PageController();

  bool checkQuestion(int ind, int pos) {
    setState(() {
      widget.catalog.questionElement[pos].showAnswer = true;
    });
    var val = widget.catalog.questionElement[pos].answer[ind].type;
    if (val == true) {
      setState(() {
        widget.catalog.questionElement[pos].wasRight == true;
        widget.catalog.questionElement[pos].checkColor = Colors.green;
      });
      return true;
    } else {
      setState(() {
        widget.catalog.questionElement[pos].checkColor = Colors.red;
      });
      return false;
    }
  }

  Future<int> updatecounter(bool val, int position) async {
    if (val == true) {
      return await CatalogDatabase.instance.updateKorrCount(widget.catalog.questionElement[position].id!, widget.catalog.questionElement[position].count);
    } else {
      return await CatalogDatabase.instance.resetCount(widget.catalog.questionElement[position].id!, widget.catalog.questionElement[position].count);
    }
  }

  getPercentColor(double val) {
    if (val > 0.65) return Colors.green;
    return Colors.red;
  }

  double getPercent(int val) {
    if (val == 0) return 0;
    double per = val / 3;
    if (per > 1.0) return 1;
    return per;
  }

  @override
  void dispose() {
    super.dispose();
    timer!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    scaleY = deviceSize.height / 100;

    return Scaffold(
      appBar: CupertinoNavigationBar(
          middle: Text(widget.catalog.id),
          leading: GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: const Icon(CupertinoIcons.back),
          )),
      body: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Container(
              height: deviceSize.height,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.catalog.questionElement.length,
                  itemBuilder: (context, position) {
                    return ListView(children: [
                      Center(child: buildTime()),
                      const Divider(),
                      Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Text(
                            widget.catalog.questionElement[position].question,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSizeQuestion),
                          )),
                      const SizedBox(
                        height: 20,
                      ),
                      widget.catalog.questionElement[position].image == null || widget.catalog.questionElement[position].image == ""
                          ? Container()
                          : Image.asset("data/${widget.catalog.questionElement[position].image!}", width: 100, height: 100,
                              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return Container(padding: const EdgeInsets.fromLTRB(0, 0, 0, 10), child: const Text("Bild kann nicht geladen werden. Nummer und Question notieren bzw Screenshot!"));
                            }),
                      PreferredSize(
                          preferredSize: const Size(double.infinity, 150),
                          child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: widget.catalog.questionElement[position].answer.length,
                              itemBuilder: (context, index) {
                                return Column(children: [
                                  RadioListTile<int>(
                                      contentPadding: const EdgeInsets.all(1),
                                      value: index,
                                      onChanged: (ind) => setState(() => widget.catalog.questionElement[position].currentSelectedItem = (ind!)),
                                      groupValue: widget.catalog.questionElement[position].currentSelectedItem,
                                      title: widget.catalog.questionElement[position].answer[index].type == true && widget.catalog.questionElement[position].showAnswer == true
                                          ? Text(widget.catalog.questionElement[position].answer[index].text,
                                              style: TextStyle(
                                                fontSize: fontSizeAnswer,
                                                color: widget.catalog.questionElement[position].checkColor,
                                              ))
                                          : Text(
                                              widget.catalog.questionElement[position].answer[index].text,
                                              style: TextStyle(fontSize: fontSizeAnswer),
                                            )),
                                  index == widget.catalog.questionElement[position].answer.length - 1
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            //crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                  onPressed: () async {
                                                    try {
                                                      if (widget.catalog.questionElement[position].currentSelectedItem == null) return;
                                                      var val = checkQuestion(widget.catalog.questionElement[position].currentSelectedItem!, position);
                                                      widget.catalog.questionElement[position].count = await updatecounter(val, position);
                                                      setState(() {});
                                                    } catch (_) {}
                                                  },
                                                  child: const Text("Prüfen")),
                                              const SizedBox(width: 30),
                                              Text((position + 1).toString() + "/" + widget.catalog.questionElement.length.toString()),
                                              const SizedBox(width: 30),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    _controller.nextPage(duration: _kDuration, curve: _kCurve);
                                                  },
                                                  child: const Text("Nächste"))
                                            ],
                                          ))
                                      : Container(),
                                  index == widget.catalog.questionElement[position].answer.length - 1
                                      ? Container(
                                          padding: const EdgeInsets.fromLTRB(50, 5, 50, 5),
                                          child: LinearPercentIndicator(
                                            progressColor: getPercentColor(getPercent(widget.catalog.questionElement[position].count)),
                                            percent: getPercent(widget.catalog.questionElement[position].count),
                                          ))
                                      : Container(),
                                  index == widget.catalog.questionElement[position].answer.length - 1
                                      ? Center(child: Text("Vom Katalog " + widget.catalog.questionElement[position].catalog))
                                      : Container(),
                                  index == widget.catalog.questionElement[position].answer.length - 1
                                      ? const SizedBox(
                                          height: 60,
                                        )
                                      : Container(),
                                ]);
                              })),
                    ]);
                  }))),
    );
  }

  Widget buildTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return Text(hours + ":" + minutes + ":" + seconds);
  }
}
