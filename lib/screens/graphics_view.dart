import 'package:biketracker/screens/speedometr.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../map.dart';
import '../widgets/chart_height.dart';

class GraphicsView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MyHomePageState.instance.portrait ? Column(
      children: [
        Speedometr(),
        Expanded(
          child: MapFlutter(),
        ),
        ///график отображать в портретной ориентации
        if(MyHomePageState.instance.showCart) LineChartWidget()
      ],
    ) : Row(
      children: [
        Speedometr(),
        Expanded(
          child: MapFlutter(),
        )
      ],
    );
  }
}