import 'dart:async';
import 'dart:math';

import 'package:biketracker/screens/p2p/src/call_sample/call_sample.dart';
import 'package:biketracker/services/nearby/nearby_service.dart';
import 'package:biketracker/widgets/buttons.dart';
import 'package:biketracker/screens/graphics_view.dart';
import 'package:biketracker/widgets/table_view.dart';
import 'package:biketracker/services/db_model.dart';
import 'package:biketracker/services/track_model.dart';
import 'package:biketracker/utilites/utils.dart';
import 'package:biketracker/utilites/variables.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/geolocation.dart';
//import 'model.dart';
import 'package:go_router/go_router.dart';


import 'dart:core';
import 'package:flutter_background/flutter_background.dart';

//import 'p2p/main_video_call.dart';
//import 'p2p/src/call_sample/call_sample.dart';

late SharedPreferences prefs;



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

DbDriver db = DbDriver();

ViewTunes viewTunes = ViewTunes();

NearbyController nearbyBikers = NearbyController();


/// описываем роутинги при запуске по ссылке
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const MainPage(),
      routes: [
        GoRoute(
          path: 'videocall',
          builder: (_, __) => const CallSample(host: '141.8.199.89'),
        ),
        GoRoute(
          path: 'getsharedroute',
          builder: (_, __) => const MainPage(),
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
    runApp(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          title: 'Велосипедный трекер',
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
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'Title of the notification',
    notificationText: 'Text of the notification',
    notificationImportance: AndroidNotificationImportance.normal,
    notificationIcon: AndroidResource(
        name: 'background_icon',
        defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  return FlutterBackground.enableBackgroundExecution();
}





class MainPage extends StatefulWidget {
  const MainPage({super.key,});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> with WidgetsBindingObserver {
  static late MainPageState instance;
  double screenWidth = 0.0;
  bool showChart = true;

  setter(){
    if(mounted)setState(() {});
  }

  openVariables()async {
    prefs = await SharedPreferences.getInstance();
  }

  bool portrait = true;

  showSnack() {
    Timer(const Duration(seconds: 1), () {
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
    instance = this;
    ///проверить доступ к геолокаци
    startGeolocation(context);
    ///создать доступ к переменным средам, чтоб выыудить пробег устройства
    openVariables();
    ///проверить наличие БД
    db.setdb();
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
      if (kDebugMode) {
        print('Приложение не активно');
      }
    }
    else if(state == AppLifecycleState.detached){
      if (kDebugMode) {
        print('Приложение выключено');
      }
      if(!trackModel.recordInProgress) {
        trackModel.stopRecord();
      }
    }
    else if(state == AppLifecycleState.paused){
      if (kDebugMode) {
        print('приложение свернуто');
      }
    }
    else if(state == AppLifecycleState.resumed){
      if(kDebugMode )print('🔙 Вернулись в приложение');

    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    final Orientation orientation = MediaQuery.of(context).orientation;
    portrait = orientation == Orientation.portrait;
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.black,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        backgroundColor: Colors.black,
        body: viewTunes.mapTable == 0 ? const Stack(
          children: [
            GraphicsView(),
            Buttons(),
          ],
        )
            : const Stack(
          children: [
            TableView(),
            Buttons(),

          ],
        )
    );
  }
}