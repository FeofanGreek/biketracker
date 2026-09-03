import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'track_model.dart';

class GpxService {
  /// Конвертация трека в формат GPX 1.1
  static String convertToGpx(Track track) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="BikeTracker"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln(
        '  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');

    final startTime = track.startTime ?? DateTime.now();
    final trackName = (track.name != null && track.name!.trim().isNotEmpty)
        ? track.name!.trim()
        : 'Track_${startTime.millisecondsSinceEpoch}';

    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml(trackName)}</name>');
    buffer.writeln('    <time>${startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml(trackName)}</name>');
    buffer.writeln('    <type>Cycling</type>');
    buffer.writeln('    <trkseg>');

    final points = track.ploylinePositions ?? [];
    final heights = track.heightStory;
    final totalDurationSeconds = track.trackDuration?.inSeconds ?? 0;
    final numPoints = points.length;

    for (int i = 0; i < numPoints; i++) {
      final pt = points[i];
      final progress = numPoints > 1 ? (i / (numPoints - 1)) : 0.0;
      final ptTime = startTime.add(
        Duration(seconds: (totalDurationSeconds * progress).round()),
      );
      final ele = (i < heights.length && heights[i] != null)
          ? (heights[i] as num).toDouble()
          : null;

      buffer.writeln(
          '      <trkpt lat="${pt.latitude.toStringAsFixed(7)}" lon="${pt.longitude.toStringAsFixed(7)}">');
      if (ele != null) {
        buffer.writeln('        <ele>${ele.toStringAsFixed(1)}</ele>');
      }
      buffer.writeln('        <time>${ptTime.toUtc().toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Парсинг GPX файла в объект Track
  static Track parseGpx(String gpxContent, {String? defaultName}) {
    // Извлечение имени трека
    String? trackName = defaultName;
    final nameMatch = RegExp(r'<name>(.*?)</name>', caseSensitive: false)
        .firstMatch(gpxContent);
    if (nameMatch != null && nameMatch.group(1) != null) {
      final extracted = nameMatch.group(1)!.trim();
      if (extracted.isNotEmpty) {
        trackName = _unescapeXml(extracted);
      }
    }

    final List<LatLng> points = [];
    final List<double> heights = [];
    DateTime? startTime;
    DateTime? stopTime;
    double maxHeight = 0;
    double maxSpeed = 0;

    // Поиск всех точек trkpt, wpt или rtept
    final pointRegex = RegExp(
      r'<(?:trkpt|wpt|rtept)\s+[^>]*?lat="([^"]+)"[^>]*?lon="([^"]+)"[^>]*?>(.*?)</(?:trkpt|wpt|rtept)>|<(?:trkpt|wpt|rtept)\s+[^>]*?lon="([^"]+)"[^>]*?lat="([^"]+)"[^>]*?>(.*?)</(?:trkpt|wpt|rtept)>',
      caseSensitive: false,
      dotAll: true,
    );

    DateTime? prevTime;
    LatLng? prevPoint;

    for (final match in pointRegex.allMatches(gpxContent)) {
      String? latStr;
      String? lonStr;
      String body = '';

      if (match.group(1) != null && match.group(2) != null) {
        latStr = match.group(1);
        lonStr = match.group(2);
        body = match.group(3) ?? '';
      } else if (match.group(4) != null && match.group(5) != null) {
        lonStr = match.group(4);
        latStr = match.group(5);
        body = match.group(6) ?? '';
      }

      if (latStr == null || lonStr == null) continue;

      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) continue;

      final currentPoint = LatLng(lat, lon);
      points.add(currentPoint);

      // Извлечение высоты
      final eleMatch = RegExp(r'<ele>(.*?)</ele>', caseSensitive: false)
          .firstMatch(body);
      if (eleMatch != null && eleMatch.group(1) != null) {
        final ele = double.tryParse(eleMatch.group(1)!.trim());
        if (ele != null) {
          heights.add(ele);
          if (ele > maxHeight) maxHeight = ele;
        } else {
          heights.add(0.0);
        }
      } else {
        heights.add(0.0);
      }

      // Извлечение времени
      final timeMatch = RegExp(r'<time>(.*?)</time>', caseSensitive: false)
          .firstMatch(body);
      if (timeMatch != null && timeMatch.group(1) != null) {
        final parsedTime = DateTime.tryParse(timeMatch.group(1)!.trim())?.toLocal();
        if (parsedTime != null) {
          startTime ??= parsedTime;
          stopTime = parsedTime;

          if (prevTime != null && prevPoint != null) {
            final dtSeconds = parsedTime.difference(prevTime).inMilliseconds / 1000.0;
            if (dtSeconds > 0) {
              final distMeters = Geolocator.distanceBetween(
                prevPoint.latitude,
                prevPoint.longitude,
                currentPoint.latitude,
                currentPoint.longitude,
              );
              final speedKmh = (distMeters / dtSeconds) * 3.6;
              if (speedKmh > maxSpeed && speedKmh < 150) {
                maxSpeed = speedKmh;
              }
            }
          }
          prevTime = parsedTime;
        }
      }
      prevPoint = currentPoint;
    }

    // Расчет суммарной дистанции
    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    startTime ??= DateTime.now();
    stopTime ??= startTime;
    Duration duration = stopTime.difference(startTime);
    if (duration.inSeconds <= 0 && points.length > 1) {
      duration = Duration(seconds: points.length * 2);
    }

    double middleSpeed = 0.0;
    if (duration.inSeconds > 0) {
      middleSpeed = (totalDistance / 1000) / (duration.inSeconds / 3600);
    }
    if (maxSpeed == 0) {
      maxSpeed = middleSpeed * 1.3;
    }

    trackName ??= 'Импорт GPX ${DateFormat.yMMMd('ru').format(startTime)}';

    return Track(
      name: trackName,
      startTime: startTime,
      stopTime: stopTime,
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

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
