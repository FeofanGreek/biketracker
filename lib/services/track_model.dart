// Обновленный файл: model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../screens/map.dart';
import '../utilites/calories_calculator.dart';
import '../widgets/odometer.dart';
import 'health_data_service.dart'; // Импортируем новый сервис


class Track with ChangeNotifier{
  int? trackID = 0;
  String? name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
  DateTime? startTime = DateTime.now();
  DateTime? stopTime = DateTime.now();
  DateTime? startCircle = DateTime.now();
  double speed = 0;
  double speedLimit = 0;
  List speeds = [];
  double? maxSpeed = 0;
  double? middleSpeed = 0;
  double currentHeigth = 0;
  double? maxHeight = 0;
  List heightStory = [];
  Duration? trackDuration = const Duration(seconds: 0);
  Duration? circleDuration = const Duration(seconds: 0);
  List<Duration> circlesStory = [];
  double? currentDistance = 0;
  double cumulativeDistance = 0;
  double azimuth = 0;
  List<Position> positions = [];
  List<LatLng>? ploylinePositions = [];
  bool recordInProgress = false;
  late StreamSubscription<Position> positionStream;
  LatLng currenLocation = const LatLng(0.0, 0.0);
  LatLng targetCoords = const LatLng(0.0, 0.0);
  final MapController controllerMap = MapController();
  final HealthDataService _healthDataService = HealthDataService(); // Создаем экземпляр сервиса

  double get durationInHours => trackDuration!.inSeconds / 3600;
  double get caloriesBurned => elevationCoeff() * userWeight * durationInHours;

  Track({
    this.trackID,
    this.name,
    this.startTime,
    this.maxSpeed,
    this.maxHeight,
    this.middleSpeed,
    this.trackDuration,
    this.currentDistance,
    this.ploylinePositions,
    this.stopTime,
    required this.circlesStory,
    required this.heightStory
  });

  double elevationCoeff() {
    double gainUp = 0;
    double gainDown = 0;

    for (int i = 1; i < heightStory.length; i++) {
      double delta = heightStory[i] - heightStory[i - 1];

      if (delta > 0) {
        gainUp += delta;
      } else {
        gainDown += -delta;
      }
    }

    double elevationFactor = 1.0;

    if (gainUp > 50 && gainUp > gainDown) {
      elevationFactor += (gainUp - gainDown) / 200;
      elevationFactor = elevationFactor.clamp(1.0, 1.5);
    }

    double metBase = getMET(middleSpeed!);
    double metCorrected = metBase * elevationFactor;
    return metCorrected;
  }

  factory Track.fromMap(Map<String, dynamic> json) => Track(circlesStory: [], heightStory: []);

  Future<bool> stopRecord() async {
    recordInProgress = false;
    stopTime = DateTime.now();

    // Сохранение данных в HealthKit/Health Connect
    if (currentDistance! > 0) {
      await syncWithHealthServices();
    }

    await db.recordTrack(trackModel).then((value) {
      name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
      middleSpeed = 0;
      maxSpeed = 0;
      maxHeight = 0;
      ploylinePositions = [];
      positions = [];
      trackDuration = const Duration(seconds: 0);
      circleDuration = const Duration(seconds: 0);
      stopTime = DateTime.now();
      startCircle = DateTime.now();
      trackID = value;
      currentDistance = 0;
      heightStory = [];
    });
    return true;
  }

  // Новый метод для синхронизации с сервисами здоровья
  Future<void> syncWithHealthServices() async {
    try {
      await _healthDataService.saveWorkoutData(
        startTime: startTime!,
        endTime: stopTime!,
        distanceMeters: currentDistance!,
        caloriesBurned: caloriesBurned,
        workoutName: 'Bicycling',
      );
    } catch (e) {
      debugPrint('Failed to sync with health services: $e');
    }
  }

  void startRecord() {
    name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
    startTime = DateTime.now();
    trackID = 0;
    recordInProgress = true;
    middleSpeed = 0;
    maxSpeed = 0;
    maxHeight = 0;
    ploylinePositions = [];
    positions = [];
    trackDuration = const Duration(seconds: 0);
    circleDuration = const Duration(seconds: 0);
    circlesStory = [];
    startTime = DateTime.now();
    startCircle = DateTime.now();
    heightStory = [];
  }

  Future<void> setValues(Position position) async {
    speed = position.speed * 3.6;
    speeds.add(position.speed * 3.6);
    double sum = speeds.fold(0, (p, c) => p + c);
    if (sum > 0) {
      middleSpeed = sum / speeds.length;
    }
    maxSpeed = maxSpeed! < position.speed * 3.6 ? position.speed * 3.6 : maxSpeed;
    currentHeigth = position.altitude;
    heightStory.add(currentHeigth);
    maxHeight = maxHeight! < position.altitude ? position.altitude : maxHeight;
    trackID == 0 && recordInProgress ? trackDuration = Duration(seconds: DateTime.now().difference(startTime!).inSeconds) : null;
    trackID == 0 && recordInProgress ? circleDuration = Duration(seconds: DateTime.now().difference(startCircle!).inSeconds) : null;
    try {
      cumulativeDistance = prefs.getDouble('cumulative') ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    azimuth = position.heading;
    currenLocation = LatLng(position.latitude, position.longitude);
    unawaited(nearbyBikers.sendPositions(position));

    if (ploylinePositions!.length > 2 && trackID == 0 && recordInProgress) {
      double tempDistance = Geolocator.distanceBetween(currenLocation.latitude, currenLocation.longitude, ploylinePositions!.last.latitude, ploylinePositions!.last.longitude);
      currentDistance = currentDistance! + tempDistance;
      await prefs.setDouble('cumulative', cumulativeDistance + tempDistance);
    }
    trackID == 0 && recordInProgress ? ploylinePositions!.add(currenLocation) : null;
    try {
      //trackID == 0 ?
      //Двигаем карту только когда Пишем трек
     if(recordInProgress) {
       controllerMap.move(currenLocation, controllerMap.camera.zoom);

     }
    } catch (e) {
      debugPrint(e.toString());
    }
    MainPageState.instance.setter();
    update();
  }

  void update(){
    notifyListeners();
  }
}
