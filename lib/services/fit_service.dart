import 'dart:core';
import 'dart:core' show Duration, DateTime, int, double, num, String, List, Map, Set, Iterable, Object, bool, Exception, print;
import 'dart:typed_data';

import 'package:fit_sdk/fit_sdk.dart' as fit;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'track_model.dart';

class FitService {
  /// Конвертация трека в формат Garmin FIT с помощью fit_sdk
  static Uint8List convertToFit(Track track) {
    final encoder = fit.Encode();
    encoder.open();

    // FIT epoch: 1989-12-31 00:00:00 UTC (631065600 секунд после Unix epoch)
    const int fitEpochOffset = 631065600;

    final startTime = track.startTime ?? DateTime.now();
    final stopTime = track.stopTime ??
        startTime.add(track.trackDuration ?? const Duration(seconds: 0));
    final startUnixSec = startTime.millisecondsSinceEpoch ~/ 1000;
    final stopUnixSec = stopTime.millisecondsSinceEpoch ~/ 1000;
    final startFitTime = startUnixSec - fitEpochOffset;
    final stopFitTime = stopUnixSec - fitEpochOffset;

    final totalDurationMs = ((track.trackDuration?.inMilliseconds ?? 0) > 0)
        ? track.trackDuration!.inMilliseconds
        : ((stopUnixSec - startUnixSec) * 1000);
    final totalDistanceMeters = track.currentDistance ?? 0.0;
    final avgSpeedMs = (track.middleSpeed ?? 0.0) / 3.6;
    final maxSpeedMs = (track.maxSpeed ?? 0.0) / 3.6;

    // 1. File ID Message
    final fileIdMesg = fit.Mesg.fromMesgNum(fit.MesgNum.fileId);
    fileIdMesg.setFieldValue(0, 4); // type: 4 = activity
    fileIdMesg.setFieldValue(1, 1); // manufacturer: 1 = garmin
    fileIdMesg.setFieldValue(2, 1); // product
    fileIdMesg.setFieldValue(
        3, (track.trackID != null && track.trackID! > 0) ? track.trackID! : 12345); // serial number
    fileIdMesg.setFieldValue(4, startFitTime); // time_created

    final fileIdDef = fit.MesgDefinition.fromMesg(fileIdMesg);
    encoder.writeMesgDefinition(fileIdDef);
    encoder.writeMesg(fileIdMesg);

    // 2. Activity Message
    final activityMesg = fit.Mesg.fromMesgNum(fit.MesgNum.activity);
    activityMesg.setFieldValue(253, stopFitTime); // timestamp
    activityMesg.setFieldValue(0, totalDurationMs); // total_timer_time in ms
    activityMesg.setFieldValue(1, 1); // num_sessions
    activityMesg.setFieldValue(2, 0); // type: 0 = manual
    activityMesg.setFieldValue(3, 0); // event: 0 = activity
    activityMesg.setFieldValue(4, 0); // event_type: 0 = start

    final activityDef = fit.MesgDefinition.fromMesg(activityMesg);
    encoder.writeMesgDefinition(activityDef);
    encoder.writeMesg(activityMesg);

    // 3. Session Message
    final sessionMesg = fit.Mesg.fromMesgNum(fit.MesgNum.session);
    sessionMesg.setFieldValue(253, stopFitTime); // timestamp
    sessionMesg.setFieldValue(2, startFitTime); // start_time
    sessionMesg.setFieldValue(7, totalDurationMs); // total_elapsed_time in ms
    sessionMesg.setFieldValue(8, totalDurationMs); // total_timer_time in ms
    sessionMesg.setFieldValue(
        9, (totalDistanceMeters * 100).round()); // total_distance (100 * meters)
    sessionMesg.setFieldValue(5, 2); // sport: 2 = cycling
    sessionMesg.setFieldValue(6, 0); // sub_sport: 0 = generic
    sessionMesg.setFieldValue(14, (avgSpeedMs * 1000).round()); // avg_speed (1000 * m/s)
    sessionMesg.setFieldValue(15, (maxSpeedMs * 1000).round()); // max_speed (1000 * m/s)

    final sessionDef = fit.MesgDefinition.fromMesg(sessionMesg);
    encoder.writeMesgDefinition(sessionDef);
    encoder.writeMesg(sessionMesg);

    // 4. Lap Message
    final lapMesg = fit.Mesg.fromMesgNum(fit.MesgNum.lap);
    lapMesg.setFieldValue(253, stopFitTime);
    lapMesg.setFieldValue(2, startFitTime);
    lapMesg.setFieldValue(7, totalDurationMs);
    lapMesg.setFieldValue(8, totalDurationMs);
    lapMesg.setFieldValue(9, (totalDistanceMeters * 100).round());
    lapMesg.setFieldValue(13, (avgSpeedMs * 1000).round());
    lapMesg.setFieldValue(14, (maxSpeedMs * 1000).round());

    final lapDef = fit.MesgDefinition.fromMesg(lapMesg);
    encoder.writeMesgDefinition(lapDef);
    encoder.writeMesg(lapMesg);

    // 5. Record Messages
    final points = track.ploylinePositions ?? [];
    final heights = track.heightStory;
    final numPoints = points.length;

    if (numPoints > 0) {
      final recordDef = fit.MesgDefinition.fromMesg(fit.Mesg.fromMesgNum(fit.MesgNum.record));

      double runningDistance = 0.0;
      for (int i = 0; i < numPoints; i++) {
        final pt = points[i];
        final progress = numPoints > 1 ? (i / (numPoints - 1)) : 0.0;
        final ptFitTime =
            startFitTime + ((totalDurationMs ~/ 1000) * progress).round();

        if (i > 0) {
          final prev = points[i - 1];
          runningDistance += Geolocator.distanceBetween(
            prev.latitude,
            prev.longitude,
            pt.latitude,
            pt.longitude,
          );
        }

        final recordMesg = fit.Mesg.fromMesgNum(fit.MesgNum.record);
        recordMesg.setFieldValue(253, ptFitTime); // timestamp
        recordMesg.setFieldValue(
            0, (pt.latitude * 11930464.7111).round()); // lat semicircles
        recordMesg.setFieldValue(
            1, (pt.longitude * 11930464.7111).round()); // lon semicircles
        recordMesg.setFieldValue(
            5, (runningDistance * 100).round()); // distance (100 * m)

        if (i < heights.length && heights[i] != null) {
          final alt = (heights[i] as num).toDouble();
          recordMesg.setFieldValue(
              2, ((alt + 500) * 5).round()); // altitude: (m + 500) * 5
        }

        if (avgSpeedMs > 0) {
          recordMesg.setFieldValue(
              6, (avgSpeedMs * 1000).round()); // speed (1000 * m/s)
        }

        if (i == 0) {
          encoder.writeMesgDefinition(recordDef);
        }
        encoder.writeMesg(recordMesg);
      }
    }

    // 6. Event Message (stop event)
    final eventMesg = fit.Mesg.fromMesgNum(fit.MesgNum.event);
    eventMesg.setFieldValue(253, stopFitTime);
    eventMesg.setFieldValue(0, 0); // event: timer
    eventMesg.setFieldValue(1, 1); // event_type: stop

    final eventDef = fit.MesgDefinition.fromMesg(eventMesg);
    encoder.writeMesgDefinition(eventDef);
    encoder.writeMesg(eventMesg);

    return encoder.close();
  }

  /// Парсинг FIT файла в объект Track
  static Track parseFit(Uint8List bytes, {String? defaultName}) {
    final List<LatLng> points = [];
    final List<double> heights = [];
    DateTime? startTime;
    DateTime? stopTime;
    double maxSpeed = 0.0;
    double middleSpeed = 0.0;
    double maxHeight = 0.0;
    double sessionDistance = 0.0;
    Duration? sessionDuration;

    const int fitEpochOffset = 631065600;

    final decoder = fit.Decode();

    decoder.onMesg = (fit.Mesg mesg) {
      if (mesg.num == fit.MesgNum.session) {
        final distVal = mesg.getField(9)?.value ?? mesg.getFieldByName('total_distance')?.value;
        if (distVal != null) {
          sessionDistance = (distVal as num).toDouble();
        }
        final maxSpdVal = mesg.getField(15)?.value ?? mesg.getFieldByName('max_speed')?.value;
        if (maxSpdVal != null) {
          final spd = (maxSpdVal as num).toDouble();
          maxSpeed = spd > 100 ? (spd / 1000.0) * 3.6 : spd * 3.6;
        }
        final avgSpdVal = mesg.getField(14)?.value ?? mesg.getFieldByName('avg_speed')?.value;
        if (avgSpdVal != null) {
          final spd = (avgSpdVal as num).toDouble();
          middleSpeed = spd > 100 ? (spd / 1000.0) * 3.6 : spd * 3.6;
        }
        final timeVal = mesg.getField(7)?.value ?? mesg.getFieldByName('total_elapsed_time')?.value;
        if (timeVal != null) {
          final ms = (timeVal as num).toInt();
          sessionDuration = Duration(milliseconds: ms > 100000000 ? ms ~/ 1000 : ms);
        }
      } else if (mesg.num == fit.MesgNum.record) {
        final latVal = mesg.getField(0)?.value ?? mesg.getFieldByName('position_lat')?.value;
        final lonVal = mesg.getField(1)?.value ?? mesg.getFieldByName('position_long')?.value;
        final altVal = mesg.getField(2)?.value ?? mesg.getFieldByName('altitude')?.value;
        final timeVal = mesg.getField(253)?.value ?? mesg.getFieldByName('timestamp')?.value;
        final spdVal = mesg.getField(6)?.value ?? mesg.getFieldByName('speed')?.value;

        if (latVal != null && lonVal != null) {
          double lat = (latVal as num).toDouble();
          double lon = (lonVal as num).toDouble();

          if (lat.abs() > 180.0) {
            lat = lat / 11930464.7111;
          }
          if (lon.abs() > 180.0) {
            lon = lon / 11930464.7111;
          }

          if (lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0) {
            points.add(LatLng(lat, lon));

            if (altVal != null) {
              final alt = (altVal as num).toDouble();
              heights.add(alt);
              if (alt > maxHeight) maxHeight = alt;
            } else {
              heights.add(0.0);
            }

            if (timeVal != null) {
              DateTime ptTime;
              if (timeVal is DateTime) {
                ptTime = timeVal.toLocal();
              } else if (timeVal is int) {
                ptTime = DateTime.fromMillisecondsSinceEpoch(
                  (timeVal + fitEpochOffset) * 1000,
                  isUtc: true,
                ).toLocal();
              } else {
                ptTime = DateTime.now();
              }

              startTime ??= ptTime;
              stopTime = ptTime;
            }

            if (spdVal != null) {
              final spd = (spdVal as num).toDouble() * 3.6;
              if (spd > maxSpeed && spd < 150) {
                maxSpeed = spd;
              }
            }
          }
        }
      }
    };

    try {
      decoder.read(bytes);
    } catch (_) {}

    // Расчет суммарной дистанции если нет в session
    double totalDistance = sessionDistance;
    if (totalDistance <= 0) {
      for (int i = 1; i < points.length; i++) {
        totalDistance += Geolocator.distanceBetween(
          points[i - 1].latitude,
          points[i - 1].longitude,
          points[i].latitude,
          points[i].longitude,
        );
      }
    }

    final start = startTime;
    final end = stopTime;
    final effectiveStartTime = start ?? DateTime.now();
    final effectiveStopTime = end ?? effectiveStartTime;
    final int diffMs = effectiveStopTime.millisecondsSinceEpoch -
        effectiveStartTime.millisecondsSinceEpoch;
    Duration duration = sessionDuration ?? Duration(milliseconds: diffMs > 0 ? diffMs : 0);
    if (duration.inSeconds <= 0 && points.length > 1) {
      duration = Duration(seconds: points.length * 2);
    }

    if (middleSpeed == 0 && duration.inSeconds > 0) {
      middleSpeed = (totalDistance / 1000) / (duration.inSeconds / 3600);
    }
    if (maxSpeed == 0) {
      maxSpeed = middleSpeed * 1.3;
    }

    final trackName =
        defaultName ?? 'Импорт FIT ${DateFormat.yMMMd('ru').format(effectiveStartTime)}';

    return Track(
      name: trackName,
      startTime: effectiveStartTime,
      stopTime: effectiveStopTime,
      trackDuration: duration,
      currentDistance: totalDistance,
      maxSpeed: maxSpeed,
      middleSpeed: middleSpeed,
      maxHeight: maxHeight,
      ploylinePositions: points,
      heightStory: heights,
      circlesStory: [],
    );
  }
}
