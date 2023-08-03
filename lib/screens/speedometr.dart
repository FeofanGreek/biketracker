import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../main.dart';
import '../utils.dart';


class Speedometr extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MyHomePageState.instance.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height,
      height: MyHomePageState.instance.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height,
      color: Colors.blueGrey,
      child: Stack(
        children: [
          SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                    minorTickStyle: const MinorTickStyle(color: Colors.orange,),
                    majorTickStyle: const MinorTickStyle(color: Colors.orange),
                    axisLabelStyle: const GaugeTextStyle(color: Colors.white),
                    minimum: 0,
                    maximum: 70,
                    ranges: <GaugeRange>[
                      GaugeRange(startValue: 0, endValue: 25, color:Colors.green),
                      GaugeRange(startValue: 25,endValue: 50,color: Colors.orange),
                      GaugeRange(startValue: 50,endValue: 70,color: Colors.red)],
                    pointers: <GaugePointer>[
                      NeedlePointer(value: trackModel.speed, needleColor: Colors.orange),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                          widget: Container(
                              child: Column(
                                  children: [
                                    Text('${trackModel.speed < 0 ? 0 : trackModel.speed.round()} км/ч',style: TextStyle(fontSize: 35,fontWeight: FontWeight.bold, color: Colors.lightGreenAccent)),
                                    const SizedBox(height: 30,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Макс. скорость',style: TextStyle(fontSize: 10, color:Colors.white)),
                                            Text('${trackModel.maxSpeed!.roundToDouble()} км/ч',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                          ],
                                        ),
                                        const SizedBox(width: 80,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Макс. высота',style: TextStyle(fontSize: 10, color:Colors.white)),
                                            Text('${trackModel.maxHeight!.round()} м',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                          ],
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 15,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Средн. скорость',style: TextStyle(fontSize: 10, color:Colors.white)),
                                            Text('${trackModel.middleSpeed!.roundToDouble()} км/ч',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                          ],
                                        ),
                                        const SizedBox(width: 75,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Текущая. высота',style: TextStyle(fontSize: 10, color:Colors.white)),
                                            Text('${trackModel.currentHeigth.round()} м',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                          ],
                                        )
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      children: [
                                        const Text('Пробег трека',style: TextStyle(fontSize: 10, color:Colors.white)),
                                        Text('${(trackModel.currentDistance! / 1000).toStringAsFixed(2)} км',style: const TextStyle(fontSize: 25,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Text('Общий пробег',style: TextStyle(fontSize: 10, color:Colors.white)),
                                        Text('${(trackModel.cumulativeDistance / 1000 ).round()} км',style: const TextStyle(fontSize: 25,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                                      ],
                                    ),
                                    SizedBox(height: !MyHomePageState.instance.portrait ? MediaQuery.of(context).size.height /3.5 : MediaQuery.of(context).size.width /3.5,),
                                  ])
                          ),
                          angle: 90, positionFactor: 0.5
                      )]
                )]),
          Positioned(
            top: MyHomePageState.instance.portrait ? 50 : 10,
            child: SizedBox(
              width: MyHomePageState.instance.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height,
              child:Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20,),
                  Column(
                    children: [
                      const Text('Текущее время',style: TextStyle(fontSize: 10, color:Colors.white)),
                      Text(DateFormat.Hms('ru').format(DateTime.now()),style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                    ],
                  ),
                  Spacer(),
                  Column(
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Длительность трека',style: TextStyle(fontSize: 10, color:Colors.white)),
                      Text(printDuration(trackModel.trackDuration!),style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
                    ],
                  ),
                  const SizedBox(width: 20,),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}