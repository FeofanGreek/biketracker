import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../screens/track_history.dart';
import '../utilites/utils.dart';
import 'record_position_button.dart';


class Buttons extends StatefulWidget {
  const Buttons({super.key,});

  @override
  State<Buttons> createState() => ButtonsState();
}

class ButtonsState extends State<Buttons> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    nearbyBikers.addListener(_onNearbyChanged);
  }

  @override
  void dispose() {
    nearbyBikers.removeListener(_onNearbyChanged);
    super.dispose();
  }

  void _onNearbyChanged() {
    if (mounted) setState(() {});
  }

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
                      // DropdownMenuItem<int>(
                      //   value: 1,
                      //   child:  ///выключить включить график высот
                      //   IconButton(
                      //     style: TextButton.styleFrom(
                      //       side: const BorderSide(color: Colors.white),
                      //       foregroundColor: Colors.white,
                      //       backgroundColor: Colors.orange,
                      //     ),
                      //     onPressed: (){
                      //       MainPageState.instance.showChart = !MainPageState.instance.showChart;
                      //       MainPageState.instance.setter();
                      //       Navigator.pop(context);
                      //     },
                      //     icon: const Icon(Icons.show_chart),
                      //   ),
                      // ),
                      // DropdownMenuItem<int>(
                      //   value: 3,
                      //   child:  ///кнопки чата
                      //   IconButton(
                      //     style: TextButton.styleFrom(
                      //       side: const BorderSide(color: Colors.white),
                      //       foregroundColor: Colors.white,
                      //       backgroundColor: Colors.orange,
                      //     ),
                      //     onPressed: ()=> Navigator.pushReplacement(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (BuildContext context) => CallSample(host: '141.8.199.89'))),
                      //     icon: Icon(CupertinoIcons.chat_bubble_2_fill),
                      //   ),
                      // ),
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
                            MainPageState.instance.setter();
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
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TrackHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(CupertinoIcons.square_list),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 7,
                        child:  ///поиск устройств рядом
                        IconButton(
                          style: TextButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            foregroundColor: Colors.white,
                            backgroundColor: nearbyBikers.isRunning ? Colors.green : Colors.orange,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await nearbyBikers.toggle();
                          },
                          icon: Icon(nearbyBikers.isRunning ? Icons.radar : Icons.radar_outlined),
                          tooltip: nearbyBikers.isRunning ? 'Остановить поиск рядом' : 'Поиск устройств рядом',
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
            RecordPositionButton(),
          ],
        )
    );
  }
}