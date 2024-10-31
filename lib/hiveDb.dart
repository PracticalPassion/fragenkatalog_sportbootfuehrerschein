import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

Future initDatabase() async {
  final appDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
}

Future<void> setData(String key, String data) async {
  var box = await Hive.openBox('data');
  box.put(key, data);
}

Future getData(String key) async {
  var box = await Hive.openBox('data');
  return box.get(key);
}
