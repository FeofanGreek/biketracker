

import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    {"title" : 'Текущ. скорость', "id" : "1", "width" : 0.0, "height" : 0.0, "visible" : true},
    {"title" : 'Макс. скорость',  "id" : "2", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Макс. высота',  "id" : "3", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Средн. скорость',  "id" : "4", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Текущая. высота', "id" : "5", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Пробег трека',  "id" : "6", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Общий пробег',  "id" : "7", "width" : 0.0, "height" : 0.0, "visible" : true},
    {"title" : 'Длительность трека',  "id" : "8", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Время сейчас',  "id" : "10", "width" : 0.0, "height" : 0.0,"visible" : true},
    {"title" : 'Время до цели',  "id" : "11", "width" : 0.0, "height" : 0.0,"visible" : true},
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
      if(selectedPreset > presets.length -1){
        selectedPreset = 0;
      }
      contentData = presets[selectedPreset];
    }
  }

}

Future<void> launch(_url) async {
  if (!await launchUrl(Uri.parse(_url))) {
    throw Exception('Could not launch $_url');
  }
}

///показать снекбар
snackBarShow(context, String message){
  final snackBar = SnackBar(
    content: Text(message),
  );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
