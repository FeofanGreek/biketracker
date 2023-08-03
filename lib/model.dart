import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';
import 'dart:io';

late SharedPreferences prefs;


///класс описывающий сеанс трека записываемого или уже записанного

class Track{
  ///trackID
  int? trackID =0;
  ///track name
  String? name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
  DateTime? startTime = DateTime.now();
  DateTime? stopTime = DateTime.now();
  DateTime? startCircle = DateTime.now();
  ///speed km/h
  double speed = 0;
  List speeds = [];
  ///maxSpeed km/h
  double? maxSpeed = 0;
  ///midleSpeed km/h
  double? middleSpeed = 0;
  ///currentHeight m
  double currentHeigth = 0;
  ///maxHeight per track m
  double? maxHeight = 0;
  ///массив высот, для отображения на графики и записи в БД
  List heightStory = [];
  ///track duration in seconds
  Duration? trackDuration = const Duration(seconds: 0);
  ///circle duration in seconds
  Duration? circleDuration = const Duration(seconds: 0);
  ///circle duration story
  List<Duration> circlesStory = [];
  ///current distance track in meters to double kilometers
  double? currentDistance = 0;
  double cumulativeDistance = 0;

  ///service units
  double azimuth = 0;
  List<Position> positions = [];
  List<LatLng>? ploylinePositions = [];
  bool recordInProgress = false;
  late StreamSubscription<Position> positionStream;
  LatLng currenLocation = LatLng(0.0,0.0);
  final MapController controllerMap = MapController();

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
  });


  factory Track.fromMap(Map<String, dynamic> _json) => Track();

  ///stoping record track
  Future<bool>stopRecord()async{
    recordInProgress = false;
    await db.recordTrack(trackModel).then((value){
      name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
      middleSpeed = 0;
      maxSpeed = 0;
      maxHeight = 0;
      ploylinePositions = [];
      positions = [];
      trackDuration = Duration(seconds: 0);
      circleDuration = Duration(seconds: 0);
      //circlesStory = [];
      stopTime = DateTime.now();
      startCircle = DateTime.now();
      trackID = value;
      currentDistance = 0;
      heightStory = [];
    });
    return true;
  }

  ///starting record track
  startRecord(){
    name = '${DateFormat.yMMMd('ru').format(DateTime.now())} ${DateFormat.Hms('ru').format(DateTime.now())}';
    startTime = DateTime.now();
    trackID = 0;
    recordInProgress = true;
    middleSpeed = 0;
    maxSpeed = 0;
    maxHeight = 0;
    ploylinePositions = [];
    positions = [];
    trackDuration = Duration(seconds: 0);
    circleDuration = Duration(seconds: 0);
    circlesStory = [];
    startTime = DateTime.now();
    startCircle = DateTime.now();
    heightStory = [];
  }


  setValues(Position position)async{

      speed = position.speed * 3.6;
      speeds.add(position.speed * 3.6);
      double sum = speeds.fold(0, (p, c) => p + c);
      if (sum > 0) {
        middleSpeed = sum / speeds.length;
      }
      ///maxSpeed km/h
      maxSpeed = maxSpeed! < position.speed * 3.6  ? position.speed * 3.6 : maxSpeed;
      ///currentHeight m
      currentHeigth = position.altitude;
      heightStory.add(currentHeigth);
      ///maxHeight per track m
      maxHeight = maxHeight! < position.altitude ? position.altitude : maxHeight;
      ///track duration in seconds
      trackID == 0 && recordInProgress ? trackDuration = Duration(seconds: DateTime.now().difference(startTime!).inSeconds) : null;
      trackID == 0 && recordInProgress ? circleDuration = Duration(seconds: DateTime.now().difference(startCircle!).inSeconds) : null;
      try{
        cumulativeDistance = prefs.getDouble('cumulative') ?? 0;
      }catch(e){
        if (kDebugMode) {
          print(e);
        }
      }
      ///service units
      azimuth = position.heading;
      ///positions.add(position);
      currenLocation = LatLng(position.latitude, position.longitude);

      if(ploylinePositions!.length > 2 && trackID == 0 && recordInProgress){
        double tempDistance = Geolocator.distanceBetween(currenLocation.latitude, currenLocation.longitude, ploylinePositions!.last.latitude, ploylinePositions!.last.longitude);
        currentDistance = currentDistance! + tempDistance;
        await prefs.setDouble('cumulative', cumulativeDistance + tempDistance );
      }
      ///add one more position to draw on map
      trackID == 0 && recordInProgress ? ploylinePositions!.add(currenLocation) : null;
      try{
        ///перемещать карту тогда когда идет запись трека и трекИД == 0
        trackID == 0 ? controllerMap.move(currenLocation, controllerMap.zoom) : null;
      }catch(e){}

      MyHomePageState.instance.setter();

  }

}

class DBdriver{

  getDBPath()async{
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'test.db');
    return path;
  }

  ///определяем есть ли БД или еще нет
  Future<bool>ExistsDB()async{
    return await File(await getDBPath()).exists();
  }

  setDB()async{
    if(await ExistsDB()){
      ///БД есть возвращаем удачу
      return true;
    }else{
      ///создаем таблицы
      await createTables();
      return true;
    }
  }

  ///создавалка всех таблиц
  createTables()async{
    Database database = await openDatabase(await getDBPath(), version: 1,);
    await database.transaction((DB) async {
      ///создаем таблицу треков

      await DB.rawQuery('CREATE TABLE Tracks ('
          'id INTEGER PRIMARY KEY, '
          'maxSpeed REAL, '
          'middleSpeed REAL, '
          'maxHeight REAL, '
          'trackDuration INTEGER, '
          'currentDistance REAL, '
          'ploylinePositions TEXT, '
          'startTime INTEGER, '
          'stopTime INTEGER, '
          'name TEXT)');
    });
  }

  ///записать трек
  Future<int>recordTrack(Track track)async{
    int result = 0;
    Database database = await openDatabase(await getDBPath(), version: 1,);
    await database.transaction((DB) async {
      result = await DB.rawInsert('INSERT INTO [Tracks] ([maxSpeed], [middleSpeed], [maxHeight], [trackDuration], [currentDistance], [ploylinePositions], [startTime], [stopTime], [name]) '
          'VALUES(?,?,?,?,?,?,?,?,?)',
          [
            track.maxSpeed,
            track.middleSpeed,
            track.maxHeight,
            track.trackDuration!.inSeconds,
            track.currentDistance,
            json.encode(track.ploylinePositions!.map((e) => {"lat" : e.latitude, "lng" : e.longitude}).toList()),
            track.startTime!.millisecondsSinceEpoch,
            DateTime.now().millisecondsSinceEpoch,
            track.name
          ]);
    });
    return result;
  }

  ///get track list
  Future<List<Track>> getTrackList()async{
    List<Track> tracks = [];
    Database database = await openDatabase(await getDBPath(), version: 1,);
    await database.transaction((DB) async {
      await DB.rawQuery('SELECT * FROM [Tracks] WHERE 1').then((value){
        for(Map item in value){
          tracks.add(Track(
            trackID: item['id'],
            name: item['name'],
            startTime: DateTime.fromMillisecondsSinceEpoch(item['startTime']),
            maxSpeed: item['maxSpeed'],
            maxHeight: item['maxHeight'],
            middleSpeed: item['middleSpeed'],
            trackDuration : Duration(seconds: item['trackDuration']),
            currentDistance: item['currentDistance'],
            ploylinePositions: (json.decode(item['ploylinePositions']) as List).map((e) => LatLng(e['lat'], e['lng'])).toList().cast<LatLng>(),
            stopTime: DateTime.fromMillisecondsSinceEpoch(item['stopTime']),
          ));
        }
      });
    });
    return tracks;
  }

  Future<bool>deleteRecord(Track track)async{
    Database database = await openDatabase(await getDBPath(), version: 1,);
    await database.transaction((DB) async {
      await DB.rawDelete('DELETE FROM [Tracks] WHERE [id] = ?',
          [
            track.trackID,

          ]);
    });
    return true;
  }


  ///обновить пользователя
  updateTrack(Track track)async{
    Database database = await openDatabase(await getDBPath(), version: 1,);
    await database.transaction((DB) async {
      await DB.rawUpdate('UPDATE [Tracks] SET [name] = ? WHERE [id] = ? ',
          [
            track.name,
            track.trackID
          ]);
    });
  }

}