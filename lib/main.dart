import 'package:biketracker/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'geolocation.dart';
import 'map.dart';
import 'model.dart';

Track trackModel = Track(
    trackID : 0,
    name : DateFormat.yMMMd('ru').format(DateTime.now()) + ' ' + DateFormat.Hms('ru').format(DateTime.now()),
    startTime: DateTime.now(),
    maxSpeed : 0,
    maxHeight : 0,
    middleSpeed : 0,
    trackDuration: Duration(seconds: 0),
    currentDistance : 0,
    ploylinePositions : [],
    stopTime:DateTime.now()
);
DBdriver db = DBdriver();


void main() {

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Велосипедный трекер',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),

      ],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static late MyHomePageState instance;

setter(){
  setState(() {

  });
}

openVariables()async {
    prefs = await SharedPreferences.getInstance();
}


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
  instance = this;
  ///проверить доступ к геолокаци
    startGeolocation(context);
    ///создать доступ к переменным средам, чтоб выыудить пробег устройства
    openVariables();
    ///проверить наличие БД

    db.setDB();
    WakelockPlus.enable();
    WakelockPlus.toggle(enable: true);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    ///AppLifecycleState.inactive
    // Приложение не активно
    // AppLifecycleState.paused
    // приложение свернуто
    // AppLifecycleState.detached
    // Приложение выключено

    if(state == AppLifecycleState.inactive){
      print('Приложение не активно');
    }
    else if(state == AppLifecycleState.detached){
      print('Приложение выключено');
      if(!trackModel.recordInProgress) {
        trackModel.stopRecord();
      }
    }
    else if(state == AppLifecycleState.paused){
      print('приложение свернуто');
    }
    else if(state == AppLifecycleState.resumed){
      kDebugMode ? print('🔙 Вернулись в приложение') : null;

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Stack(
        children: [
          ///карта и спидометр
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.height,
                color: Colors.blueGrey,
                child: Stack(
                  children: [
                SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(
                              minorTickStyle: const MinorTickStyle(color: Colors.orange,),
                              majorTickStyle: const MinorTickStyle(color: Colors.orange),
                              axisLabelStyle: const GaugeTextStyle(color: Colors.white),
                              //axisLineStyle: AxisLineStyle(color: Colors.white),
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
                                             Spacer(),
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
                                              SizedBox(height: MediaQuery.of(context).size.height /3.5,),
                                            ])
                                    ),
                                    angle: 90, positionFactor: 0.5
                                )]
                          )]),

                    Positioned(
                      top: 10,
                      child: Container(
                        width: MediaQuery.of(context).size.height,
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
              ),
              Expanded(
                child: MapFlutter(),
              )
            ],
          ),

        ],
      ),
    );
  }
}
