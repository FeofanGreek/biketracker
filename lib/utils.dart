

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}


class ViewTunes{
  ///0 - map and speedometer, 1 - table with data
  int mapTable = 0;

  ///настройки прессетов отображения в таблице
  List contentData = [
    {"title" : 'Текущ. скорость', "id" : "1"},
    {"title" : 'Макс. скорость',  "id" : "2"},
    {"title" : 'Макс. высота',  "id" : "3"},
    {"title" : 'Средн. скорость',  "id" : "4"},
    {"title" : 'Текущая. высота', "id" : "5"},
    {"title" : 'Пробег трека',  "id" : "6"},
    {"title" : 'Общий пробег',  "id" : "7"},
    {"title" : 'Длительность трека',  "id" : "8"},
  ];

  ///массив прессетов табличного отображения
  List presets = [];
  ///прессет выбранный пользователем
  int selectedPreset = -1;

  initTunes()async{
    var prefs = await SharedPreferences.getInstance();
    ///при старте карты подгружаем настройки
    mapTable = prefs.getInt('mapTable') ?? 0;
    selectedPreset = prefs.getInt('selectedPreset') ?? -1;
    presets = json.decode(prefs.getString('presets') ?? "[]");
    ///print(json.decode(prefs.getString('presets') ?? "[]").runtimeType);
    if(selectedPreset != -1) {
      //print(presets[selectedPreset]);
      contentData = presets[selectedPreset];
    }
  }

}

