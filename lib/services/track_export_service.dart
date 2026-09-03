import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'fit_service.dart';
import 'gpx_service.dart';
import 'track_model.dart';

enum ExportFormat {
  gpx,
  fit,
}

class SaveLocationOption {
  final String title;
  final String subtitle;
  final String path;
  final IconData icon;

  const SaveLocationOption({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.icon,
  });
}

class TrackExportService {
  /// Конвертация в GPX
  static String convertToGpx(Track track) {
    return GpxService.convertToGpx(track);
  }

  /// Конвертация в FIT
  static List<int> convertToFit(Track track) {
    return FitService.convertToFit(track);
  }

  /// Импорт трека из файла (.gpx или .fit)
  static Future<Track> importTrack({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final name = fileName ??
        (filePath != null
            ? filePath.split(io.Platform.pathSeparator).last
            : 'track');
    final lowerName = name.toLowerCase();

    if (lowerName.endsWith('.fit')) {
      final data = bytes ??
          (filePath != null ? await io.File(filePath).readAsBytes() : null);
      if (data == null) {
        throw Exception('Не удалось прочитать файл FIT');
      }
      final baseName =
          name.replaceAll(RegExp(r'\.fit$', caseSensitive: false), '');
      return FitService.parseFit(data, defaultName: baseName);
    } else if (lowerName.endsWith('.gpx') || lowerName.endsWith('.xml')) {
      final content = bytes != null
          ? utf8.decode(bytes)
          : (filePath != null ? await io.File(filePath).readAsString() : null);
      if (content == null) {
        throw Exception('Не удалось прочитать файл GPX');
      }
      final baseName =
          name.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
      return GpxService.parseGpx(content, defaultName: baseName);
    } else {
      // Попытка автоматического определения формата
      if (bytes != null) {
        try {
          final content = utf8.decode(bytes);
          if (content.contains('<gpx') || content.contains('<trk')) {
            return GpxService.parseGpx(content, defaultName: name);
          }
        } catch (_) {}
        return FitService.parseFit(bytes, defaultName: name);
      } else if (filePath != null) {
        try {
          final content = await io.File(filePath).readAsString();
          if (content.contains('<gpx') || content.contains('<trk')) {
            return GpxService.parseGpx(content, defaultName: name);
          }
        } catch (_) {}
        final data = await io.File(filePath).readAsBytes();
        return FitService.parseFit(data, defaultName: name);
      }
      throw Exception('Неподдерживаемый формат файла (ожидается .gpx или .fit)');
    }
  }

  /// Получение доступных путей для сохранения
  static Future<List<SaveLocationOption>> getAvailableSaveLocations() async {
    final List<SaveLocationOption> locations = [];

    // 1. Папка "Загрузки" (Downloads)
    if (io.Platform.isAndroid) {
      final downloadDir = io.Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        locations.add(SaveLocationOption(
          title: 'Папка "Загрузки"',
          subtitle: '/storage/emulated/0/Download',
          path: downloadDir.path,
          icon: Icons.download_rounded,
        ));
      }
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null &&
          !locations.any((loc) => loc.path == downloads.path)) {
        locations.add(SaveLocationOption(
          title: 'Папка "Загрузки"',
          subtitle: downloads.path,
          path: downloads.path,
          icon: Icons.download_rounded,
        ));
      }
    } catch (_) {}

    // 2. Папка "Документы"
    try {
      final docs = await getApplicationDocumentsDirectory();
      if (!locations.any((loc) => loc.path == docs.path)) {
        locations.add(SaveLocationOption(
          title: 'Папка "Документы"',
          subtitle: docs.path,
          path: docs.path,
          icon: Icons.folder_open_rounded,
        ));
      }
    } catch (_) {}

    // 3. Внешнее хранилище приложения (Android)
    if (io.Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null &&
            !locations.any((loc) => loc.path == extDir.path)) {
          locations.add(SaveLocationOption(
            title: 'Папка приложения',
            subtitle: extDir.path,
            path: extDir.path,
            icon: Icons.sd_storage_rounded,
          ));
        }
      } catch (_) {}
    }

    return locations;
  }

  /// Сохранение файла трека в указанную директорию
  static Future<io.File> saveTrackFile({
    required Track track,
    required ExportFormat format,
    required String targetDirectory,
  }) async {
    final ext = format == ExportFormat.gpx ? 'gpx' : 'fit';
    final sanitizedName = _sanitizeFileName(track.name ?? 'track');
    final fileName =
        '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '$targetDirectory/$fileName';
    final file = io.File(filePath);

    if (format == ExportFormat.gpx) {
      final gpxContent = convertToGpx(track);
      await file.writeAsString(gpxContent, encoding: utf8);
    } else {
      final fitBytes = convertToFit(track);
      await file.writeAsBytes(fitBytes);
    }

    return file;
  }

  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}
