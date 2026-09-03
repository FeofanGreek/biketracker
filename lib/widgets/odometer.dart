import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../main.dart';
import '../utilites/utils.dart';

class Odometer extends StatefulWidget {

  final double maxSpeed;
  final double speedLimit;
  final Function(double) onSpeedLimitChanged;

  const Odometer({
    Key? key,

    this.maxSpeed = 70.0,
    required this.speedLimit,
    required this.onSpeedLimitChanged,
  }) : super(key: key);

  @override
  OdometerState createState() => OdometerState();
}

class OdometerState extends State<Odometer> {
  late double _speedLimit;



  double currentSpeed = 0;

  @override
  void initState() {
    trackModel.addListener(updateOdometer);
    super.initState();
    _speedLimit = widget.speedLimit;
  }

  @override
  void dispose() {
    trackModel.removeListener(updateOdometer);
    super.dispose();
  }

  final Iterable<Duration> pauses = [
    const Duration(milliseconds: 500),
    const Duration(milliseconds: 1000),
    const Duration(milliseconds: 500),
  ];

  void updateOdometer(){
    currentSpeed = trackModel.speed < 70 ? trackModel.speed : 70;
    if(mounted) {
      setState(() {
        if(trackModel.speed > _speedLimit && _speedLimit > 5){
          Vibrate.vibrateWithPauses(pauses);
          SystemSound.play(SystemSoundType.alert);
        }
      });
    }
  }


  @override
  void didUpdateWidget(covariant Odometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speedLimit != oldWidget.speedLimit) {
      _speedLimit = widget.speedLimit;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localOffset = box.globalToLocal(details.globalPosition);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final offset = localOffset - Offset(centerX, centerY);

    final angle = math.atan2(offset.dy, offset.dx);

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;
    double newSpeedLimit;

    double adjustedAngle = angle - startAngle;
    if (adjustedAngle < 0) {
      adjustedAngle += 2 * math.pi;
    }

    if (adjustedAngle > sweepAngle) {
      if (adjustedAngle < 2 * math.pi - (startAngle - sweepAngle)) {
        // За пределами дуги, но ближе к началу. Устанавливаем 0.
        newSpeedLimit = 0;
      } else {
        // За пределами дуги, но ближе к концу. Устанавливаем maxSpeed.
        newSpeedLimit = widget.maxSpeed;
      }
    } else {
      newSpeedLimit = (adjustedAngle / sweepAngle) * widget.maxSpeed;
    }

    if (newSpeedLimit < 0) {
      newSpeedLimit = 0;
    } else if (newSpeedLimit > widget.maxSpeed) {
      newSpeedLimit = widget.maxSpeed;
    }

    setState(() {
      _speedLimit = newSpeedLimit;
    });

    widget.onSpeedLimitChanged(_speedLimit);
  }

  @override
  Widget build(BuildContext context) {
    final width = MainPageState.instance.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height;
    return SizedBox(
      width: width,
      height: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: SpeedometerPainter(
              currentSpeed: currentSpeed,
              maxSpeed: widget.maxSpeed,
              speedLimit: _speedLimit,
            ),
            child: Container(),
          ),
          Positioned(
            child: GestureDetector(
              onPanUpdate: (details) => _onPanUpdate(details, Size(width, width)),
              child: Container(
                width: width,
                height: width,
                color: Colors.transparent,
              ),
            ),
          ),
          ///информеры
          Positioned(
            top: 0,
            left: 10,
            child: Column(
              children: [
                const Text('Сожжено каллорий',
                    style: TextStyle(fontSize: 10, color:Colors.white)),
                Text('${trackModel.caloriesBurned.toStringAsFixed(0)} ккал',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),

                // const Text('Текущее время',style: TextStyle(fontSize: 10, color:Colors.white)),
                // Text(DateFormat.Hms('ru').format(DateTime.now()),style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 10,
            child: Column(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Длительность трека',
                    style: TextStyle(fontSize: 10, color:Colors.white)),
                Text(printDuration(trackModel.trackDuration!),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            child: Column(
              children: [
                Text('${trackModel.speed < 0 ? 0 : trackModel.speed.round()} км/ч',
                    style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent)),

                const Text('Пробег трека',style: TextStyle(fontSize: 10, color:Colors.white)),
                Text('${(trackModel.currentDistance! / 1000).toStringAsFixed(2)} км',style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),

                const Text('Общий пробег',style: TextStyle(fontSize: 10, color:Colors.white)),
                Text('${(trackModel.cumulativeDistance / 1000 ).round()} км',style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1, color: Colors.lightGreenAccent)),

              ],
            ),
          ),
          Positioned(
              top: width / 2 - 30,
              child: Column(
                children: [
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
                ],
              ))
        ],
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double currentSpeed;
  final double maxSpeed;
  final double speedLimit;

  SpeedometerPainter({
    required this.currentSpeed,
    required this.maxSpeed,
    required this.speedLimit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) * 0.9;
    const startAngle = 0.75 * math.pi; // Изменен начальный угол на 135 градусов
    const sweepAngle = 1.5 * math.pi;

    // Сектора
    final greenPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final orangePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final sector1Angle = (25 / maxSpeed) * sweepAngle;
    final sector2Angle = (50 / maxSpeed) * sweepAngle;
    final sector3Angle = (70 / maxSpeed) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle,
      sector1Angle,
      false,
      greenPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle + sector1Angle,
      sector2Angle - sector1Angle,
      false,
      orangePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      startAngle + sector2Angle,
      sector3Angle - sector2Angle,
      false,
      redPaint,
    );

    // Штрихи и текст
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (double i = 0; i <= maxSpeed; i += 2.5) {
      final angle = startAngle + (i / maxSpeed) * sweepAngle;
      final x1 = centerX + (radius) * math.cos(angle);
      final y1 = centerY + (radius) * math.sin(angle);

      final isMajorTick = i % 5 == 0;
      final tickLength = isMajorTick ? 15 : 8;

      final x2 = centerX + (radius - tickLength) * math.cos(angle);
      final y2 = centerY + (radius - tickLength) * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);

      if (isMajorTick) {
        textPainter.text = TextSpan(
          text: i.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final textX = centerX + (radius - 30) * math.cos(angle);
        final textY = centerY + (radius - 30) * math.sin(angle);
        canvas.save();
        canvas.translate(textX, textY);
        canvas.rotate(angle + math.pi / 2);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }

    // Стрелка
    final needleAngle = startAngle + (currentSpeed / maxSpeed) * sweepAngle;

    const innerRadius = 20.0;
    final outerRadius = radius - 20;

    final needlePath = Path();

    // Угол смещения для основания
    final baseOffsetAngle = math.atan((6 ) / innerRadius);

    // Угол смещения для вершины
    final tipOffsetAngle = math.atan((1.5) / outerRadius);

    // Точки основания стрелки (ширина 6 пикселей)
    final basePoint1X = centerX + innerRadius * math.cos(needleAngle - baseOffsetAngle);
    final basePoint1Y = centerY + innerRadius * math.sin(needleAngle - baseOffsetAngle);

    final basePoint2X = centerX + innerRadius * math.cos(needleAngle + baseOffsetAngle);
    final basePoint2Y = centerY + innerRadius * math.sin(needleAngle + baseOffsetAngle);

    // Точки вершины стрелки (ширина 3 пикселя)
    final tipPoint1X = centerX + outerRadius * math.cos(needleAngle - tipOffsetAngle);
    final tipPoint1Y = centerY + outerRadius * math.sin(needleAngle - tipOffsetAngle);

    final tipPoint2X = centerX + outerRadius * math.cos(needleAngle + tipOffsetAngle);
    final tipPoint2Y = centerY + outerRadius * math.sin(needleAngle + tipOffsetAngle);

    // Отрисовка трапеции
    needlePath.moveTo(basePoint1X, basePoint1Y);
    needlePath.lineTo(tipPoint1X, tipPoint1Y);
    needlePath.lineTo(tipPoint2X, tipPoint2Y);
    needlePath.lineTo(basePoint2X, basePoint2Y);
    needlePath.close();

    final needlePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawPath(needlePath, needlePaint);

    final centerCirclePaint = Paint()..color = Colors.grey;
    canvas.drawCircle(Offset(centerX, centerY), 20, centerCirclePaint);

    // Кружок ограничителя
    final speedLimitAngle = startAngle + (speedLimit / maxSpeed) * sweepAngle;
    final speedLimitX = centerX + (radius) * math.cos(speedLimitAngle);
    final speedLimitY = centerY + (radius) * math.sin(speedLimitAngle);
    final speedLimitPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(speedLimitX, speedLimitY), 15, speedLimitPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}