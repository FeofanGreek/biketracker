import 'package:biketracker/widgets/speedometr.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/odometer.dart';
import 'map.dart';
import '../widgets/chart_height.dart';

class GraphicsView extends StatelessWidget {
  const GraphicsView({super.key});


  @override
  Widget build(BuildContext context) {

    return MainPageState.instance.portrait ? Column(
      children: [
        Odometer(
          maxSpeed: 70,
          speedLimit: trackModel.speedLimit,
          onSpeedLimitChanged: (value){
          trackModel.speedLimit = value;
          },
        ),
        const Expanded(
          child: MapFlutter(),
        ),

      ],
    ) : Row(
      children: [
        Odometer(
          maxSpeed: 70,
          speedLimit: trackModel.speedLimit,
          onSpeedLimitChanged: (value){
            trackModel.speedLimit = value;
          },
        ),
        const Expanded(
          child: MapFlutter(),
        )
      ],
    );
  }
}