import 'package:flutter/material.dart';
import 'Front.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
  runApp(const Katal());
}

class Katal extends StatelessWidget {
  const Katal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      return const MaterialApp(title: "Kataloge Sportbootführerschein", home: Front());
    } on Exception catch (_) {
      throw UnimplementedError();
    }
  }
}
