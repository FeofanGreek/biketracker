
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
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
  }

  Widget element(String data, String title){
    TextStyle titleStyle = const TextStyle(fontSize: 10, color:Colors.white);
    TextStyle dataStyle = const TextStyle(fontSize: 30,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent);

    Widget e = Container(
      width: MyHomePageState.instance.ScreenWidth / 2.2,
      height: 65,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
      ),
      margin: const EdgeInsets.fromLTRB(5, 5, 0 , 0),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title ,style: titleStyle),
            Text(data,style: dataStyle),
          ]),
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
        child: Column(
          children: [
            ///switch or save
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.fromLTRB(16, 5, 16 , 0),
              height: 50,
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 100,
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

                            },
                            onLongPress: ()async{
                              ///удалить пресет по долгому нажатию
                              viewTunes.presets.removeAt(index);
                              var prefs = await SharedPreferences.getInstance();
                              prefs.setString('presets', json.encode(viewTunes.presets));
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
                children: viewTunes.contentData.map((item) => element(getData(int.parse(item['id'])), item['title'])).toList().cast<Widget>()
            ),
            const Text('Круги', style: TextStyle(fontSize: 16, color:Colors.white),),
            Wrap(
              children: trackModel.circlesStory.asMap().map((index, e) => MapEntry(index, element(printDuration(e), 'Круг ${index + 1}'))).values.toList().cast<Widget>(),
            )
          ],
        ),
      ),
    );
  }
}