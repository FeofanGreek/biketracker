
import 'dart:convert';
import 'dart:io';

import 'package:biketracker/services/track_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbDriver{

  getDbPath()async{
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'test.db');
    return path;
  }

  ///определяем есть ли БД или еще нет
  Future<bool>existsDb()async{
    return await File(await getDbPath()).exists();
  }

  Future<bool> setdb()async{
    if(await existsDb()){
      ///БД есть возвращаем удачу
      return true;
    }else{
      ///создаем таблицы
      await createTables();
      return true;
    }
  }

  ///создавалка всех таблиц
  Future<void> createTables()async{
    Database database = await openDatabase(await getDbPath(), version: 1,);
    await database.transaction((db) async {
      ///создаем таблицу треков

      await db.rawQuery('CREATE TABLE Tracks ('
          'id INTEGER PRIMARY KEY, '
          'maxSpeed REAL, '
          'middleSpeed REAL, '
          'maxHeight REAL, '
          'trackDuration INTEGER, '
          'currentDistance REAL, '
          'ploylinePositions TEXT, '
          'circles TEXT, '
          'heights TEXT, '
          'startTime INTEGER, '
          'stopTime INTEGER, '
          'name TEXT)');
    });
  }

  ///записать трек
  Future<int>recordTrack(Track track)async{
    int result = 0;
    Database database = await openDatabase(await getDbPath(), version: 1,);
    await database.transaction((db) async {
      result = await db.rawInsert('INSERT INTO [Tracks] ([maxSpeed], [middleSpeed], [maxHeight], [trackDuration], [currentDistance], [ploylinePositions], [circles], [heights], [startTime], [stopTime], [name]) '
          'VALUES(?,?,?,?,?,?,?,?,?,?,?)',
          [
            track.maxSpeed,
            track.middleSpeed,
            track.maxHeight,
            track.trackDuration!.inSeconds,
            track.currentDistance,
            json.encode(track.ploylinePositions!.map((e) => {"lat" : e.latitude, "lng" : e.longitude}).toList()),
            json.encode(track.circlesStory.map((e)=> e.inSeconds).toList()),
            json.encode(track.heightStory.map((e) => e).toList()),
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
    Database database = await openDatabase(await getDbPath(), version: 1,);
    await database.transaction((db) async {
      await db.rawQuery('SELECT * FROM [Tracks] WHERE 1').then((value){
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
            heightStory: (json.decode(item['heights']) as List),
            circlesStory: (json.decode(item['circles']) as List).map((e) => Duration(seconds: e)).toList().cast<Duration>(),
            stopTime: DateTime.fromMillisecondsSinceEpoch(item['stopTime']),
          ));
        }
      });
    });
    return tracks;
  }

  Future<bool>deleteRecord(Track track)async{
    Database database = await openDatabase(await getDbPath(), version: 1,);
    await database.transaction((db) async {
      await db.rawDelete('DELETE FROM [Tracks] WHERE [id] = ?',
          [
            track.trackID,

          ]);
    });
    return true;
  }


  ///обновить пользователя
  Future<void> updateTrack(Track track)async{
    Database database = await openDatabase(await getDbPath(), version: 1,);
    await database.transaction((db) async {
      await db.rawUpdate('UPDATE [Tracks] SET [name] = ? WHERE [id] = ? ',
          [
            track.name,
            track.trackID
          ]);
    });
  }

}