import 'package:flutter/material.dart';

///цвета
Color backGroundColorButtonOrange = const Color(0xFFFF6A2B);
Color backGroundColorButtonGrey = const Color(0xFF5E7280);
Color labelButtonColorWhite = const Color(0xFFFFFFFF);
Color labelButtonColorBlue = const Color(0xFF92E3F4);
Color mainBackgroundColor = const Color(0xFF1D2830);
Color semiBlue = const Color(0xFF849EAF);
Color semiGrey = const Color(0xFFD4F4FB);
Color errorBorder = const Color(0xFFF15D69);
Color darkBlue = const Color(0xFF304655);
Color semiLightBlue = const Color(0xFFB1C5D3);
Color newRed = const Color(0xFFF4542D);
Color lightBlue = const Color(0xFF15ABCA);
Color someBlue = const Color(0xFF628BA7);
Color semiWhite = const Color(0xFFE8ECEF);
Color green = const Color(0xFF1EE184);
///стили шрифтов
TextStyle inputHintTextStyle = TextStyle(fontSize: 15.0, color: semiBlue,fontFamily: 'Inter',);
TextStyle inputTextStyle = TextStyle(fontSize: 15.0, color: backGroundColorButtonGrey,fontFamily: 'Inter',);

TextStyle notifBodyText = TextStyle(fontSize: 14.0, color: const Color(0xFF5E7280), fontFamily: 'Inter',);
TextStyle white12 = const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500 , color: Color(0xFFFFFFFF), fontFamily: 'Inter',);
TextStyle semiBlue12 = TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500 , color: semiBlue, fontFamily: 'Inter',);
TextStyle white14 = const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500 , color: Color(0xFFFFFFFF), fontFamily: 'Inter',);
TextStyle semiWhite14 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400 , color: semiWhite, fontFamily: 'Inter',);
TextStyle semiLightBlue14 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400 , color: semiLightBlue, fontFamily: 'Inter',);
TextStyle semiBlue14 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400 , color: semiBlue, fontFamily: 'Inter',);
TextStyle semiBlue14_500 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500 , color: semiBlue, fontFamily: 'Inter',);
TextStyle backGroundColorButtonOrange14_500 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400 , color: backGroundColorButtonOrange, fontFamily: 'Inter',);
TextStyle green14_500 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400 , color: green, fontFamily: 'Inter',);
TextStyle backGroundColorButtonGrey14 = TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500 , color: backGroundColorButtonGrey, fontFamily: 'Inter',);
TextStyle white10 = const TextStyle(fontSize: 10.0, fontWeight: FontWeight.w400 , color: Color(0xFFE8ECEF), fontFamily: 'Inter',);
TextStyle white15 = const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w400 , color: Color(0xFFE8ECEF), fontFamily: 'Inter',);
TextStyle semiLightBlue15 = TextStyle(fontSize: 15.0, fontWeight: FontWeight.w400 , color: semiLightBlue, fontFamily: 'Inter',);
TextStyle white15_500 = const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500 , color: Color(0xFFE8ECEF), fontFamily: 'Inter', height: 1.5);
TextStyle green15_500 = TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500 , color: green, fontFamily: 'Inter', height: 1.5);
TextStyle backGroundColorButtonOrange15_500 = TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500 , color: backGroundColorButtonOrange, fontFamily: 'Inter', height: 1.5);
TextStyle white18 = const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700 , color: Color(0xFFFFFFFF), fontFamily: 'Inter',);
TextStyle white22 = const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w700 , color: Color(0xFFFFFFFF), fontFamily: 'Inter',);


///массив подсказок для экрана с картой
List promts_map = [
  "В режиме портрет можно выключить отображения графика высот",
  "Запустите режим записи трека кнопкой с зеленым кругом",
  "Переключайтесь между режимами отображения Карта и  Таблица",
  "Долгим нажатием на карту установите цель"
];
///массив подсказок для экрана с таблицей
List promts_table = [
  'Назмите и удерживайте плитку для перемещения',
  "Проведите по плитке в лево или вправо для изменения ширины",
  "Проведите по плитке вверх или в низ для изменения высоты",
  "Настройки плиток можно сохранять",
  "Долгое нажате по селектору сохраненного значения удалит его",
  "Размещение и размер плиток можно сбросить",
  "Делайте отсечки круга в режиме записи трека нажатием по иконке часов",
  "Нажмите на крестик, что бы удалить плитку",
  "Пока не активирована запись трека плитки с данными можно настраивать по размеру"
];