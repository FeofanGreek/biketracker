
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../utils.dart';



getData(int id){
  String result = '';
  switch(id){
    case 1 :
      result = '${trackModel.speed < 0 ? 0 : trackModel.speed.round()} км/ч';
      break;
    case 2 :
      result = '${trackModel.maxSpeed!.roundToDouble()} км/ч';
      break;
    case 3 :
      result = '${trackModel.maxHeight!.round()} м';
      break;
    case 4 :
      result = '${trackModel.middleSpeed!.roundToDouble()} км/ч';
      break;
    case 5 :
      result = '${trackModel.currentHeigth.round()} м';
      break;
    case 6 :
      result = '${(trackModel.currentDistance! / 1000).toStringAsFixed(2)} км';
      break;
    case 7 :
      result = '${(trackModel.cumulativeDistance / 1000 ).round()} км';
      break;
    case 8 :
      result = printDuration(trackModel.trackDuration!);
      break;
    case 9 :
      result = printDuration(trackModel.trackDuration!);
      break;
    case 10 :
      result = DateFormat.Hms('ru').format(DateTime.now());
      break;
    case 11 :{
      if(trackModel.targetCoords.latitude != 0.0){
        double dist = Geolocator.distanceBetween(trackModel.currenLocation.latitude, trackModel.currenLocation.longitude, trackModel.targetCoords.latitude, trackModel.targetCoords.longitude);
        double hoursToTarget = (dist / 1000) / (trackModel.middleSpeed ?? 1);
        result = printDuration(Duration(seconds: (hoursToTarget * 60 * 60).round()));
      }else{
        result = '';
      }

      break;
    }

  }

  return result;
}




class TableView extends StatelessWidget {

  void _onReorder(int oldIndex, int newIndex) async{
    Map row = viewTunes.contentData.removeAt(oldIndex);
    viewTunes.contentData.insert(newIndex, row);
    ///сохранить настройки, если пресет выбран
    if(viewTunes.selectedPreset != -1){
      var prefs = await SharedPreferences.getInstance();
      prefs.setString('presets', json.encode(viewTunes.presets));
    }
    MyHomePageState.instance.setter();
  }



  Widget element(String data, String title, double? width, double? height, bool visible, bool withbutton){
    TextStyle titleStyle = const TextStyle(fontSize: 10, color:Colors.white);
    TextStyle dataStyleVeryBig = const TextStyle(fontSize: 70,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent);
    if(width == 0.0){
      width = MyHomePageState.instance.ScreenWidth / 2.2;
      viewTunes.contentData.where((element) => element['title'] == title).first['width'] = MyHomePageState.instance.ScreenWidth / 2.2;
    }
    if(height == 0.0){
      height = 63.0;
      viewTunes.contentData.where((element) => element['title'] == title).first['height'] = 63.0;
    }

    Widget e = GestureDetector(
      onPanUpdate: (details) async{
        if(!trackModel.recordInProgress){
          // Swiping in right direction.
          if (details.delta.dx > 0) {
            width = MyHomePageState.instance.ScreenWidth - 34;
            viewTunes.contentData.where((element) => element['title'] == title).first['width'] = width;
            //print('right');
            MyHomePageState.instance.setter();
          }

          // Swiping in left direction.
          if (details.delta.dx < 0) {
            width = MyHomePageState.instance.ScreenWidth / 2.2;
            viewTunes.contentData.where((element) => element['title'] == title).first['width'] = width;
            //print('left');
            MyHomePageState.instance.setter();
          }
          if (details.delta.dy < 0) {
            height = 65;
            viewTunes.contentData.where((element) => element['title'] == title).first['height'] = 65.0;
            //print('right');
            MyHomePageState.instance.setter();
          }

          // Swiping in left direction.
          if (details.delta.dy > 0) {
            height = 130.0;
            viewTunes.contentData.where((element) => element['title'] == title).first['height'] = 130.0;
            //print('left');
            MyHomePageState.instance.setter();
          }
          if(viewTunes.selectedPreset != -1){
            var prefs = await SharedPreferences.getInstance();
            prefs.setString('presets', json.encode(viewTunes.presets));
          }
        }

      },
      onPanEnd: (v){
        MyHomePageState.instance.setter();
      },
      onPanCancel: (){
        MyHomePageState.instance.setter();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
        ),
        margin: const EdgeInsets.fromLTRB(5, 5, 0 , 0),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child:Stack(
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(title ,style: titleStyle),
                      Spacer(),
                      if(withbutton && !trackModel.recordInProgress)GestureDetector(
                        onTap: ()async{
                          viewTunes.contentData.where((element) => element['title'] == title).first['visible'] = false;
                          if(viewTunes.selectedPreset != -1){
                            var prefs = await SharedPreferences.getInstance();
                            prefs.setString('presets', json.encode(viewTunes.presets));
                          }
                          MyHomePageState.instance.setter();
                        },
                        child: Container(
                          width: 10,
                          height: 10,
                          color: Colors.transparent,
                          child: Icon(CupertinoIcons.clear, size: 10, color: Colors.white,),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: width,
                    height: height! - 26,
                    child: AutoSizeText(
                      data,
                      //style: width == MyHomePageState.instance.ScreenWidth - 34 && height == 130 ? dataStyleVeryBig : width == MyHomePageState.instance.ScreenWidth / 2.2 && height == 130 ? dataStyleBig : dataStyle,
                      style: dataStyleVeryBig,
                    ),
                  ),
                ]),
            if(!trackModel.recordInProgress)Positioned(
              right: -7,
                top: 15,
                child: Icon(CupertinoIcons.resize_v, color: Colors.orange,)
            ),
            if(!trackModel.recordInProgress)Positioned(
                right: 13,
                top: -5,
                child: Icon(CupertinoIcons.resize_h, color: Colors.orange,)
            )
          ],
        ),
      ),
    );
    return e;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 50, 0 , 0),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        physics: trackModel.recordInProgress ? ScrollPhysics() : NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            ///switch or save
            ///прессеты отображения таблицы
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.fromLTRB(16, 5, 16 , 0),
              height: 50,
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ScrollPhysics(),
                      itemCount: viewTunes.presets.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                            onTap:()async{
                              ///переключиться на выбранный пресет
                              viewTunes.contentData = viewTunes.presets[index];
                              viewTunes.selectedPreset = index;
                              var prefs = await SharedPreferences.getInstance();
                              prefs.setInt('selectedPreset', index);
                              MyHomePageState.instance.setter();

                            },
                            onLongPress: ()async{
                              ///удалить пресет по долгому нажатию
                              viewTunes.presets.removeAt(index);
                              var prefs = await SharedPreferences.getInstance();
                              prefs.setString('presets', json.encode(viewTunes.presets));
                              MyHomePageState.instance.setter();
                              viewTunes.contentData = [
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
                              MyHomePageState.instance.setter();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 1),
                                  color: index != viewTunes.selectedPreset ? Colors.transparent : Colors.orange
                              ),
                              margin: const EdgeInsets.fromLTRB(5, 5, 0 , 0),
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              alignment: Alignment.center,
                              child: Text((index + 1).toString(), style: const TextStyle(fontSize: 16, color:Colors.white),),
                            )
                        );
                      },
                    ),
                  ),
                  IconButton(
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: ()async{
                      viewTunes.contentData = [
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
                      MyHomePageState.instance.setter();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: ()async{
                      List contentData = json.decode(json.encode(viewTunes.contentData));
                      viewTunes.presets.add(contentData);
                      var prefs = await SharedPreferences.getInstance();
                      prefs.setString('presets', json.encode(viewTunes.presets));
                    },
                    icon: const Icon(Icons.save),
                  ),

                ],
              ),
            ),
            ///values of route
            ReorderableWrap(
                spacing: 0.0,
                runSpacing: 0.0,
                padding: const EdgeInsets.all(8),
                onReorder: _onReorder,
                onNoReorder: (int index) {
                  //this callback is optional
                  debugPrint('${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
                },
                onReorderStarted: (int index) {
                  //this callback is optional
                  debugPrint('${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
                },
                children: viewTunes.contentData.map((item) => item['visible'] ? element(getData(int.parse(item['id'])), item['title'], item['width'], item['height'], item['visible'], true ) : SizedBox.shrink()).toList().cast<Widget>(),
                buildDraggableFeedback:(context, constrain, child)=>child,
            ),
            if(trackModel.recordInProgress) const Text('Круги', style: TextStyle(fontSize: 16, color:Colors.white),),
            Wrap(
              children: trackModel.circlesStory.asMap().map((index, e) => MapEntry(index, element(printDuration(e), 'Круг ${index + 1}',MyHomePageState.instance.ScreenWidth / 2.2, 63.0 ,true, false))).values.toList().cast<Widget>(),
            )
          ],
        ),
      ),
    );
  }
}