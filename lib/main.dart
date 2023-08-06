
import 'dart:async';
import 'dart:math';

import 'package:biketracker/screens/buttons.dart';
import 'package:biketracker/screens/graphics_view.dart';
import 'package:biketracker/screens/table_view.dart';
import 'package:biketracker/utils.dart';
import 'package:biketracker/variables.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'geolocation.dart';
import 'model.dart';
import 'package:go_router/go_router.dart';


import 'dart:core';
import 'package:flutter_background/flutter_background.dart';

import 'p2p/src/call_sample/call_sample.dart';



Track trackModel = Track(
    trackID : 0,
    name : '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}',
    startTime: DateTime.now(),
    maxSpeed : 0,
    maxHeight : 0,
    middleSpeed : 0,
    trackDuration: const Duration(seconds: 0),
    currentDistance : 0,
    ploylinePositions : [],
    stopTime:DateTime.now(),
    circlesStory: [],
    heightStory: []
);
DBdriver db = DBdriver();

ViewTunes viewTunes = ViewTunes();





/// описываем роутинги при запуске по ссылке
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => MyApp(),
      routes: [
        GoRoute(
          path: 'videocall',
          builder: (_, __) => CallSample(host: '141.8.199.89'),
        ),
        GoRoute(
          path: 'getsharedroute',
          builder: (_, __) => MyApp(),
        ),
      ],
    ),
  ],
);



void main() {

  WidgetsFlutterBinding.ensureInitialized();
  if (WebRTC.platformIsDesktop) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  } else if (WebRTC.platformIsAndroid) {
    //startForegroundService();
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ])
      .then((_) {
    runApp(MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
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
    ));
  });
}


///for chat
Future<bool> startForegroundService() async {
  final androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return
      MaterialApp(
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
      home: const MyHomePage()
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
  double ScreenWidth = 0.0;
  bool showCart = true;

setter(){
  if(mounted)setState(() {});
}

openVariables()async {
    prefs = await SharedPreferences.getInstance();
}

bool portrait = true;

showSnack() {
  Timer(Duration(seconds: 1), () {
    if (viewTunes.mapTable == 0) {
      Random random = Random();
      int randomNumber = random.nextInt(promts_map.length - 1);
      snackBarShow(context, promts_map[randomNumber]);
    } else {
      Random random = Random();
      int randomNumber = random.nextInt(promts_table.length - 1);
      snackBarShow(context, promts_table[randomNumber]);
    }
  });
}

  @override
  void initState() {
    viewTunes.initTunes();
    WidgetsBinding.instance.addObserver(this);

    ///ориентация телефона
    motionSensors.screenOrientation.listen((ScreenOrientationEvent event) {
      event.angle == 0 || event.angle == 180 || event.angle == -180.0 ?
      portrait = true : portrait = false;
      print(event.angle);
      setter();
    });

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

    showSnack();
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
    ScreenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: viewTunes.mapTable == 0 ? Stack(
        children: [
          GraphicsView(),
          Buttons()

        ],
      )
          : Stack(
          children: [
            TableView(),
            Buttons()

          ],
      )
    );
  }
}
