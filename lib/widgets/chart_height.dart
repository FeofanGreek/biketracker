
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
  Widget build(BuildContext context) {
    return Container(
      height: (trackModel.maxHeight! > 0 ? 130 : 10),
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(0, 0, 0 , MediaQuery.of(context).viewInsets.bottom),
      child: LineChart(
          mainData()
      ),
    );

  }

  /*Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('MAR', style: style);
        break;
      case 5:
        text = const Text('JUN', style: style);
        break;
      case 8:
        text = const Text('SEP', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }*/

  // Widget leftTitleWidgets(double value, TitleMeta meta) {
  //   const style = TextStyle(
  //     fontWeight: FontWeight.bold,
  //     fontSize: 15,
  //   );
  //   String text;
  //   switch (value.toInt()) {
  //     case 1:
  //       text = '10K';
  //       break;
  //     case 3:
  //       text = '30k';///средняя высота
  //       break;
  //     case 5:
  //       text = '50k';///максимальная высота
  //       break;
  //     default:
  //       return Container();
  //   }
  //
  //   return Text(text, style: style, textAlign: TextAlign.left);
  // }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.black,
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
          // spots: const [
          //   ///X номер из массива высот, У высота
          //   FlSpot(0, 3),
          //   FlSpot(1, 2),
          //   FlSpot(2, 5),
          //   FlSpot(3, 3.1),
          //   FlSpot(4, 4),
          //   FlSpot(5, 3),
          //   FlSpot(6, 4),
          // ],
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
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}