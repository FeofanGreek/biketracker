

import 'dart:async';
import 'dart:io';

import 'package:biketracker/utils.dart';
import 'package:biketracker/widgets/compas.dart';
import 'package:biketracker/widgets/record_position_button.dart';
import 'package:biketracker/widgets/text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'dialog.dart';
import 'main.dart';




class MapFlutter extends StatefulWidget {

  @override
  MapFlutterState createState() => MapFlutterState();
}

class MapFlutterState extends State<MapFlutter> {

  static late MapFlutterState instance;
  Style? _style;

  Future<Style> _readStyle() =>
      StyleReader(
        uri: 'mapbox://styles/koldashev/cliwrnlc7015o01pf71kohae2?access_token={key}',
        // ignore: undefined_identifier
        apiKey: 'pk.eyJ1Ijoia29sZGFzaGV2IiwiYSI6ImNrNDJ5ZTExdDAyMzYzb294NG1zdmlvazEifQ.ph863CVICRWFF1VXL0i57w',
        //logger: Logger.console()
      )
          .read();

  void _initStyle() async {
    try {
      _style = await _readStyle();
    } catch (e, stack) {
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(stack);
      //_error = e;
    }
    setState(() {});
  }




  @override
  void initState() {
    instance = this;
    _initStyle();
    super.initState();
  }



  @override
  void didUpdateWidget(covariant MapFlutter oldWidget) {

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return _style == null ? SizedBox.shrink()
        : FlutterMap(
        mapController: trackModel.controllerMap,
        options: MapOptions(
            center: trackModel.currenLocation,
            zoom: 18,
            maxZoom: 22,
            interactiveFlags: InteractiveFlag.drag |
            InteractiveFlag.flingAnimation |
            InteractiveFlag.pinchMove |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom,

        ),
        nonRotatedChildren: [
          Positioned(
              top:10,
              right: 10,
              child:CompassWidget()
          ),
          Positioned(
              bottom:120,
              right: 10,
              child: IconButton(
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
              )
          ),
          Positioned(
              bottom:70,
              right: 10,
              child: IconButton(
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
                onPressed: ()async{
                  await db.getTrackList().then((value) => showAlertDialog(
                    context: context,
                    title: 'История треков',
                    showBottomButton: false,
                    showTopButton: false,
                    showCloseButton: true,
                    dialogBody: Container(
                      //width: 300,
                      height: 2350,
                        //constraints:  const BoxConstraints(minWidth: 200.0, maxWidth: 300, minHeight: 100.0, maxHeight: 235),
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
                                var cZ = trackModel.controllerMap.centerZoomFitBounds(LatLngBounds.fromPoints(trackModel.ploylinePositions!));
                                await trackModel.controllerMap.move(cZ.center, cZ.zoom - 1);
                                await trackModel.controllerMap.moveAndRotate(trackModel.controllerMap.center, trackModel.controllerMap.zoom, 0.0);
                                Navigator.pop(context);
                              });

                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //Text(value[index].name ?? '', style: const TextStyle(fontSize: 12, color:Colors.white)),
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
                                    SizedBox(height: 5,),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.speedometer, color: Colors.white, size: 12,),
                                        Text('max: ${value[index].maxSpeed!.round()} km/h, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                        Icon(CupertinoIcons.speedometer, color: Colors.white, size: 12,),
                                        Text('mid: ${value[index].middleSpeed!.round()} km/h, ', style: TextStyle(fontSize: 11, color:Colors.white)),

                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.resize_v, color: Colors.white, size: 12,),
                                        Text('max: ${value[index].maxHeight!.round()} m, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                        Icon(CupertinoIcons.resize_h, color: Colors.white, size: 12,),
                                        Text('${(value[index].currentDistance! / 1000).round()} km, ', style: TextStyle(fontSize: 11, color:Colors.white)),
                                        Icon(CupertinoIcons.clock, color: Colors.white, size: 12,),
                                        Text('${printDuration(value[index].trackDuration!)}', style: TextStyle(fontSize: 11, color:Colors.white)),
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
              )
          ),
          Positioned(
              bottom:10,
              right: 10,
              child: recordPositionButton()
          ),
        ],
        children: [
          VectorTileLayer(
              tileProviders: _style!.providers,
              theme: _style!.theme,
              sprites: _style!.sprites,
              maximumZoom: 22,
              tileOffset: TileOffset.mapbox,
              layerMode: VectorTileLayerMode.vector),

          PolylineLayer(
              polylines: [
                Polyline(
                    points: trackModel.ploylinePositions!,
                    strokeWidth: 4,
                    color: Colors.lightGreenAccent
                )
              ]
          ),
          MarkerLayer(
              markers: [
                Marker(
                    point: trackModel.currenLocation,
                    builder: (BuildContext context) => Transform.rotate(
                      angle: trackModel.azimuth * pi / 180,
                      child:const Icon(CupertinoIcons.location_north_fill, color: Colors.orange,)
                    )

                )
              ]
          ),
      ]
    );
  }
}