import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dialog.dart';
import '../main.dart';
import '../p2p/src/call_sample/call_sample.dart';
import '../utils.dart';
import '../widgets/record_position_button.dart';
import '../widgets/text_field.dart';


class Buttons extends StatefulWidget {
  const Buttons({super.key,});

  @override
  State<Buttons> createState() => ButtonsState();
}

class ButtonsState extends State<Buttons> with WidgetsBindingObserver {


  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom:10,
        right: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                    alignment: AlignmentDirectional.center,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0 , 0),
                    value: null,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu, color: Colors.white,),
                    ),
                    elevation: 0,
                    dropdownColor: Colors.transparent,

                    style: const TextStyle(  //te
                        color: Colors.transparent, //Font color
                        fontSize: 20 //font size on dropdown button
                    ),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (int? value) {},
                    items: [
                      DropdownMenuItem<int>(
                        value: 1,
                        child:  ///выключить включить график высот
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: (){
                            MyHomePageState.instance.showCart = !MyHomePageState.instance.showCart;
                            MyHomePageState.instance.setter();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.show_chart),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 3,
                        child:  ///кнопки чата
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: ()=> Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) => CallSample(host: '141.8.199.89'))),
                          icon: Icon(CupertinoIcons.chat_bubble_2_fill),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 4,
                        child:  ///режим табличное или с картой спидометром
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: ()async{
                            viewTunes.mapTable == 0 ? viewTunes.mapTable = 1 : viewTunes.mapTable = 0;
                            var prefs = await SharedPreferences.getInstance();
                            prefs.setInt('mapTable', viewTunes.mapTable);
                            MyHomePageState.instance.setter();
                            Navigator.pop(context);
                          },
                          icon: Icon(viewTunes.mapTable == 1 ? CupertinoIcons.map : CupertinoIcons.table),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 6,
                        child:  ///история треков
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: ()async{
                            Navigator.pop(context);
                            await db.getTrackList().then((value) => showAlertDialog(
                                context: context,
                                title: 'История треков',
                                showBottomButton: false,
                                showTopButton: false,
                                showCloseButton: true,
                                dialogBody: Container(
                                  //width: 300,
                                  height: 350,
                                  child: ListView.separated(
                                    physics: const ScrollPhysics(),
                                    itemCount: value.length,
                                    shrinkWrap: true,
                                    separatorBuilder: (BuildContext context, int index) =>
                                    const Divider(thickness: 1, color: Colors.white),
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap:()async{
                                          trackModel = value[index];
                                          MyHomePageState.instance.setter();
                                          Timer(const Duration(seconds: 1),()async{
                                            try{
                                              var cZ = trackModel.controllerMap.centerZoomFitBounds(LatLngBounds.fromPoints(trackModel.ploylinePositions!));
                                              await trackModel.controllerMap.move(cZ.center, cZ.zoom - 1);
                                              await trackModel.controllerMap.moveAndRotate(trackModel.controllerMap.center, trackModel.controllerMap.zoom, 0.0);
                                            }catch(e){}

                                            Navigator.pop(context);
                                          });

                                        },
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                TextFieldBrand(
                                                  title: 'Название трека',
                                                  hint: 'Название трека',
                                                  maskType: 6,
                                                  keyType: 0,
                                                  func: (String _value) {
                                                    value[index].name = _value;
                                                    db.updateTrack(value[index]);
                                                  },
                                                  width: 250,
                                                  initialValue: value[index].name ?? '',),
                                                const SizedBox(height: 5,),
                                                Row(
                                                  children: [
                                                    const Icon(CupertinoIcons.speedometer, color: Colors.white, size: 12,),
                                                    Text('max: ${value[index].maxSpeed!.round()} km/h, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                                    const Icon(CupertinoIcons.speedometer, color: Colors.white, size: 12,),
                                                    Text('mid: ${value[index].middleSpeed!.round()} km/h, ', style: TextStyle(fontSize: 11, color:Colors.white)),

                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(CupertinoIcons.resize_v, color: Colors.white, size: 12,),
                                                    Text('max: ${value[index].maxHeight!.round()} m, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                                    const Icon(CupertinoIcons.resize_h, color: Colors.white, size: 12,),
                                                    Text('${(value[index].currentDistance! / 1000).round()} km, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                                    const Icon(CupertinoIcons.clock, color: Colors.white, size: 12,),
                                                    Text(printDuration(value[index].trackDuration!), style: TextStyle(fontSize: 11, color:Colors.white)),
                                                  ],
                                                )
                                              ],
                                            ),
                                            Spacer(),
                                            IconButton(
                                                onPressed: ()async{
                                                  await db.deleteRecord(value[index]).then((value){
                                                    SystemSound.play(SystemSoundType.click);
                                                    Navigator.pop(context);
                                                  });

                                                },
                                                icon: const Icon(CupertinoIcons.trash, color: Colors.blue,)
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                            ));

                          },
                          icon: const Icon(CupertinoIcons.square_list),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 2,
                        child:  ///ссылка на политику конфиденциальности
                        IconButton(
                            style: TextButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: (){
                              launch('https://koldashev.ru/policy.html');
                              Navigator.pop(context);
                              },
                            icon: Icon(Icons.policy),
                            tooltip: 'Политика конфиденциальности'
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 5,
                        child:  ///выход
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: ()async{
                            trackModel.recordInProgress = !trackModel.recordInProgress;
                            if(!trackModel.recordInProgress) {
                              await trackModel.stopRecord().then((value) => exit(0));
                            }else{
                              exit(0);
                            }
                          },
                          icon: const Icon(Icons.exit_to_app_outlined),
                        ),
                      ),
                    ]
                ),
              ),




            ///отсечка круга
            if(trackModel.recordInProgress && viewTunes.mapTable == 1)IconButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
              ),
              onPressed: (){
                trackModel.circlesStory.add(trackModel.circleDuration!);
                trackModel.circleDuration = const Duration(seconds: 0);
                trackModel.startCircle = DateTime.now();
              },
              icon: const Icon(CupertinoIcons.clock),
            ),



            ///начать запись
            recordPositionButton(),
          ],
        )
    );
  }
}