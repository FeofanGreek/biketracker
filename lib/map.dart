
import 'dart:async';
import 'dart:math';
import 'package:biketracker/utils.dart';
import 'package:biketracker/variables.dart';
import 'package:biketracker/widgets/compas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'main.dart';




class MapFlutter extends StatefulWidget {

  @override
  MapFlutterState createState() => MapFlutterState();
}

class MapFlutterState extends State<MapFlutter> {

  static late MapFlutterState instance;
  Style? _style;

  Future<Style> _readStyle() =>
      StyleReader(///https://api.mapbox.com/styles/v1/putikoff/clvauocc800um01pka3d3bsss.html?title=view&access_token=pk.eyJ1IjoicHV0aWtvZmYiLCJhIjoiY2x1cnp0cXdjMGNkYjJxbGdjaDJqaWVxcyJ9._iVV1vIjaVLrLTWXqnfwkw&zoomwheel=true&fresh=true#15.8/59.959122/30.316377
        uri: 'mapbox://styles/putikoff/clvauocc800um01pka3d3bsss?access_token={key}',
        // ignore: undefined_identifier
        apiKey: 'pk.eyJ1IjoicHV0aWtvZmYiLCJhIjoiY2x1cnp0cXdjMGNkYjJxbGdjaDJqaWVxcyJ9._iVV1vIjaVLrLTWXqnfwkw',
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
    if(mounted)setState(() {});
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
          onLongPress: (position, coords){
            trackModel.targetCoords = coords;
            MyHomePageState.instance.setter();
          },
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

                ),
                Marker(
                    point: trackModel.targetCoords,
                    builder: (BuildContext context) => Transform.rotate(
                        angle: trackModel.azimuth * pi / 180,
                        child:GestureDetector(
    onTap: (){
      trackModel.targetCoords = LatLng(0.0, 0.0);
    },
                          child: const Icon(CupertinoIcons.star, color: Colors.yellow,),
    )
                    )

                )
              ]
          ),
      ]
    );
  }
}