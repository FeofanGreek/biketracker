import 'dart:async';
import 'dart:math';
import 'package:biketracker/widgets/compas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../main.dart';
import '../secrets.dart';
import '../widgets/chart_height.dart';

Future<Style> _readStyle() => StyleReader(
      uri: mapUri,
      // ignore: undefined_identifier
      apiKey: mapSecret,
      //logger: Logger.console()
    ).read();

class MapFlutter extends StatefulWidget {
  const MapFlutter({super.key});

  @override
  MapFlutterState createState() => MapFlutterState();
}

class MapFlutterState extends State<MapFlutter> {
  Style? _style;

  void _initStyle() async {
    try {
      _style = await _readStyle();
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
    if (mounted) setState(() {});
  }

  void setter() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    trackModel.addListener(setter);
    _initStyle();
    super.initState();
  }

  @override
  void dispose() {
    trackModel.removeListener(setter);
    super.dispose();
  }

  Widget get background => VectorTileLayer(
        tileProviders: _style!.providers,
        theme: _style!.theme,
        //sprites: _style!.sprites,
        //maximumZoom: 22,
        tileOffset: TileOffset.mapbox,
        //layerMode: VectorTileLayerMode.vector,
      );

  @override
  Widget build(BuildContext context) {
    return _style == null
        ? const SizedBox.shrink()
        : FlutterMap(
            mapController: trackModel.controllerMap,
            options: MapOptions(
              onLongPress: (position, coords) {
                trackModel.targetCoords = coords;
                trackModel.update();
              },
              initialCenter: trackModel.currenLocation,
              initialZoom: 18,
              maxZoom: 22,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
                background,
                if ((trackModel.ploylinePositions ?? []).isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(points: trackModel.ploylinePositions ?? [], strokeWidth: 4, color: Colors.lightGreenAccent)
                  ]),
                MarkerLayer(markers: [
                  ...nearbyBikers.nearbyPeers
                      .map((peer) => Marker(
                          point: LatLng(peer.position.latitude, peer.position.longitude),
                          child: Icon(
                            Icons.directions_bike,
                            color: peer.color,
                          )))
                      .toList(),
                  Marker(
                      point: trackModel.currenLocation,
                      child: Transform.rotate(
                          angle: trackModel.azimuth * pi / 180,
                          child: const Icon(
                            CupertinoIcons.location_north_fill,
                            color: Colors.orange,
                          ))),
                  Marker(
                      point: trackModel.targetCoords,
                      child: Transform.rotate(
                          angle: trackModel.azimuth * pi / 180,
                          child: GestureDetector(
                            onTap: () {
                              trackModel.targetCoords = const LatLng(0.0, 0.0);
                            },
                            child: const Icon(
                              CupertinoIcons.star,
                              color: Colors.yellow,
                            ),
                          )))
                ]),
                Positioned(top: 10, right: 10, child: CompassWidget()),

                ///график отображать в портретной ориентации
                if (MainPageState.instance.showChart) const Positioned(bottom: 10, child: LineChartWidget())
              ]);
  }
}

// Массив из 10 цветов. Вы можете использовать любые цвета.
final List<Color> colors = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.pink,
  Colors.teal,
  Colors.cyan,
  Colors.brown,
];

// Функция, которая возвращает случайный цвет из массива.
Color getRandomColor() {
  final random = Random();
  // Выбираем случайный индекс от 0 до 9 (размер массива - 1).
  final int randomIndex = random.nextInt(colors.length);
  // Возвращаем цвет по этому индексу.
  return colors[randomIndex];
}
