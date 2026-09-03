
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class LineChartWidget extends StatefulWidget {
  const LineChartWidget({super.key});

  @override
  State<LineChartWidget> createState() => _LineChartState();
}

class _LineChartState extends State<LineChartWidget> {
  List<Color> gradientColors = [
    Colors.blue,
    Colors.green,
  ];

  @override
  void initState() {
    trackModel.addListener(setter);
    super.initState();
  }

  @override
  void dispose() {
    trackModel.removeListener(setter);
    super.dispose();
  }

  void setter(){
    if(mounted)setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: MediaQuery.of(context).size.width,
      //margin: EdgeInsets.fromLTRB(0, 0, 0 , MediaQuery.of(context).viewInsets.bottom),
      child: LineChart(
          mainData()
      ),
    );

  }


  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.transparent,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: const FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: trackModel.heightStory.length.toDouble(),///длина массива высот
      minY: 0,
      maxY: trackModel.maxHeight,///максимальная высота
      lineBarsData: [
        LineChartBarData(
          spots: trackModel.heightStory.asMap().map((index, e) => MapEntry(index, FlSpot(index.toDouble().roundToDouble(), e))).values.toList().cast<FlSpot>(),
          isCurved: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: gradientColors
                  .map((color) => color.withValues(alpha: 0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}