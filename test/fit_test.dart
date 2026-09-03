import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:biketracker/services/track_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:fit_sdk/fit_sdk.dart' as fit;
import 'package:geolocator/geolocator.dart';

Uint8List testConvertToFit(Track track) {
  final encoder = fit.Encode();
  encoder.open();

  const int fitEpochOffset = 631065600;

  final startTime = track.startTime ?? DateTime.now();
  final stopTime = track.stopTime ??
      startTime.add(track.trackDuration ?? const Duration(seconds: 0));
  final startUnixSec = startTime.millisecondsSinceEpoch ~/ 1000;
  final stopUnixSec = stopTime.millisecondsSinceEpoch ~/ 1000;
  final startFitTime = startUnixSec - fitEpochOffset;
  final stopFitTime = stopUnixSec - fitEpochOffset;

  final totalDurationSec = ((track.trackDuration?.inMilliseconds ?? 0) > 0)
      ? track.trackDuration!.inMilliseconds / 1000.0
      : (stopUnixSec - startUnixSec).toDouble();
  final totalDistanceMeters = track.currentDistance ?? 0.0;
  final avgSpeedMs = (track.middleSpeed ?? 0.0) / 3.6;
  final maxSpeedMs = (track.maxSpeed ?? 0.0) / 3.6;

  // 1. File ID Message
  final fileIdMesg = fit.Mesg.fromMesgNum(fit.MesgNum.fileId);
  fileIdMesg.setFieldValue(0, 4); // type: 4 = activity
  fileIdMesg.setFieldValue(1, 1); // manufacturer: 1 = garmin
  fileIdMesg.setFieldValue(2, 1); // product
  fileIdMesg.setFieldValue(
      3, (track.trackID != null && track.trackID! > 0) ? track.trackID! : 12345);
  fileIdMesg.setFieldValue(4, startFitTime);

  final fileIdDef = fit.MesgDefinition.fromMesg(fileIdMesg);
  encoder.writeMesgDefinition(fileIdDef);
  encoder.writeMesg(fileIdMesg, fileIdDef);

  // 2. Activity Message
  final activityMesg = fit.Mesg.fromMesgNum(fit.MesgNum.activity);
  activityMesg.setFieldValue(253, stopFitTime);
  activityMesg.setFieldValue(0, totalDurationSec);
  activityMesg.setFieldValue(1, 1);
  activityMesg.setFieldValue(2, 0);
  activityMesg.setFieldValue(3, 0);
  activityMesg.setFieldValue(4, 0);

  final activityDef = fit.MesgDefinition.fromMesg(activityMesg);
  encoder.writeMesgDefinition(activityDef);
  encoder.writeMesg(activityMesg, activityDef);

  // 3. Session Message
  final sessionMesg = fit.Mesg.fromMesgNum(fit.MesgNum.session);
  sessionMesg.setFieldValue(253, stopFitTime);
  sessionMesg.setFieldValue(2, startFitTime);
  sessionMesg.setFieldValue(7, totalDurationSec);
  sessionMesg.setFieldValue(8, totalDurationSec);
  sessionMesg.setFieldValue(9, totalDistanceMeters);
  sessionMesg.setFieldValue(5, 2);
  sessionMesg.setFieldValue(6, 0);
  sessionMesg.setFieldValue(14, avgSpeedMs);
  sessionMesg.setFieldValue(15, maxSpeedMs);

  final sessionDef = fit.MesgDefinition.fromMesg(sessionMesg);
  encoder.writeMesgDefinition(sessionDef);
  encoder.writeMesg(sessionMesg, sessionDef);

  // 4. Lap Message
  final lapMesg = fit.Mesg.fromMesgNum(fit.MesgNum.lap);
  lapMesg.setFieldValue(253, stopFitTime);
  lapMesg.setFieldValue(2, startFitTime);
  lapMesg.setFieldValue(7, totalDurationSec);
  lapMesg.setFieldValue(8, totalDurationSec);
  lapMesg.setFieldValue(9, totalDistanceMeters);
  lapMesg.setFieldValue(13, avgSpeedMs);
  lapMesg.setFieldValue(14, maxSpeedMs);

  final lapDef = fit.MesgDefinition.fromMesg(lapMesg);
  encoder.writeMesgDefinition(lapDef);
  encoder.writeMesg(lapMesg, lapDef);

  // 5. Record Messages
  final points = track.ploylinePositions ?? [];
  final heights = track.heightStory;
  final numPoints = points.length;

  if (numPoints > 0) {
    final templateRecord = fit.Mesg.fromMesgNum(fit.MesgNum.record);
    templateRecord.setFieldValue(253, startFitTime);
    templateRecord.setFieldValue(0, 0);
    templateRecord.setFieldValue(1, 0);
    templateRecord.setFieldValue(5, 0.0);
    templateRecord.setFieldValue(2, 0.0);
    templateRecord.setFieldValue(6, 0.0);
    final recordDef = fit.MesgDefinition.fromMesg(templateRecord);
    encoder.writeMesgDefinition(recordDef);

    double runningDistance = 0.0;
    for (int i = 0; i < numPoints; i++) {
      final pt = points[i];
      final progress = numPoints > 1 ? (i / (numPoints - 1)) : 0.0;
      final ptFitTime =
          startFitTime + (totalDurationSec * progress).round();

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
      recordMesg.setFieldValue(253, ptFitTime);
      recordMesg.setFieldValue(0, (pt.latitude * (0x80000000 / 180.0)).round());
      recordMesg.setFieldValue(1, (pt.longitude * (0x80000000 / 180.0)).round());
      recordMesg.setFieldValue(5, runningDistance);

      if (i < heights.length && heights[i] != null) {
        final alt = (heights[i] as num).toDouble();
        recordMesg.setFieldValue(2, alt);
      }

      if (avgSpeedMs > 0) {
        recordMesg.setFieldValue(6, avgSpeedMs);
      }

      encoder.writeMesg(recordMesg, recordDef);
    }
  }

  // 6. Event Message (stop event)
  final eventMesg = fit.Mesg.fromMesgNum(fit.MesgNum.event);
  eventMesg.setFieldValue(253, stopFitTime);
  eventMesg.setFieldValue(0, 0); // event: timer
  eventMesg.setFieldValue(1, 1); // event_type: stop

  final eventDef = fit.MesgDefinition.fromMesg(eventMesg);
  encoder.writeMesgDefinition(eventDef);
  encoder.writeMesg(eventMesg, eventDef);

  return encoder.close();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  test('test full testConvertToFit', () {
    final track = Track(
      trackID: 42,
      name: 'Test Track',
      startTime: DateTime(2026, 1, 1, 10, 0, 0),
      stopTime: DateTime(2026, 1, 1, 11, 0, 0),
      trackDuration: const Duration(hours: 1),
      currentDistance: 10000,
      middleSpeed: 20.0,
      maxSpeed: 30.0,
      ploylinePositions: [
        LatLng(55.75, 37.61),
        LatLng(55.76, 37.62),
      ],
      heightStory: [150.0, 160.0],
      circlesStory: [],
    );

    final bytes = testConvertToFit(track);
    print('bytes: ${bytes.length}');

    final decoder = fit.Decode();
    int recordCount = 0;
    decoder.onMesg = (mesg) {
      print('Mesg num ${mesg.num}, name ${mesg.name}');
      if (mesg.num == fit.MesgNum.record) {
        recordCount++;
        print('Record $recordCount: lat=${mesg.getField(0)?.value}, lon=${mesg.getField(1)?.value}, alt=${mesg.getField(2)?.value}, dist=${mesg.getField(5)?.value}');
      }
      if (mesg.num == fit.MesgNum.session) {
        print('Session: dist=${mesg.getField(9)?.value}, dur=${mesg.getField(7)?.value}, avgSpd=${mesg.getField(14)?.value}');
      }
    };
    decoder.read(bytes);
    expect(recordCount, 2);
  });
}
