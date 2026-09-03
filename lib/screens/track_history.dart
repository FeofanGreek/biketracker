import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';

import '../main.dart';
import '../services/track_export_service.dart';
import '../services/track_model.dart';
import '../utilites/utils.dart';
import '../utilites/variables.dart';
import '../widgets/export_track_dialog.dart';
import '../widgets/text_field.dart';

class TrackHistoryScreen extends StatefulWidget {
  const TrackHistoryScreen({super.key});

  @override
  State<TrackHistoryScreen> createState() => _TrackHistoryScreenState();
}

class _TrackHistoryScreenState extends State<TrackHistoryScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tracks = await db.getTrackList();
      setState(() {
        _tracks = tracks.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectTrack(Track track) {
    trackModel.loadFrom(track);
    MainPageState.instance.setter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if ((trackModel.ploylinePositions ?? []).isNotEmpty) {
          CameraFit fit = CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(trackModel.ploylinePositions!),
            padding: const EdgeInsets.all(30),
          );
          trackModel.controllerMap.fitCamera(fit);
          trackModel.controllerMap.moveAndRotate(
            trackModel.controllerMap.camera.center,
            trackModel.controllerMap.camera.zoom,
            0.0,
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });

    Navigator.pop(context);
  }

  void _exportTrack(Track track) {
    showExportTrackDialog(
      context: context,
      track: track,
    );
  }

  Future<void> _importTrack() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        //type: FileType.any,
        //allowedExtensions: ['gpx', 'fit', 'xml'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      setState(() {
        _isLoading = true;
      });

      final importedTrack = await TrackExportService.importTrack(
        filePath: pickedFile.path,
        bytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      final newId = await db.recordTrack(importedTrack);
      importedTrack.trackID = newId;

      SystemSound.play(SystemSoundType.click);

      await _loadTracks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: darkBlue,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Трек "${importedTrack.name}" успешно импортирован',
                    style: white14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('Ошибка импорта: $e', style: white14),
          ),
        );
      }
    }
  }

  Future<void> _deleteTrack(int index) async {
    final trackToDelete = _tracks[index];
    await db.deleteRecord(trackToDelete);
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _tracks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBlue,
        title: Text('История треков', style: white18),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_down_doc, color: Colors.orange),
            tooltip: 'Импортировать GPX / FIT',
            onPressed: _importTrack,
          ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : _tracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Нет сохраненных треков',
                        style: semiLightBlue15,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _importTrack,
                        icon: const Icon(CupertinoIcons.arrow_down_doc, size: 18),
                        label: const Text('Импортировать трек (GPX / FIT)'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    final dateStr = track.startTime != null
                        ? DateFormat.yMMMMd('ru').add_Hm().format(track.startTime!)
                        : '';

                    return Container(
                      decoration: BoxDecoration(
                        color: darkBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () => _selectTrack(track),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFieldBrand(
                                    title: 'Название трека',
                                    hint: 'Название трека',
                                    maskType: 6,
                                    keyType: 0,
                                    func: (String value) {
                                      track.name = value;
                                      db.updateTrack(track);
                                    },
                                    width: MediaQuery.of(context).size.width - 120,
                                    initialValue: track.name ?? '',
                                  ),
                                  if (dateStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: semiLightBlue,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.speedometer,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'max: ${track.maxSpeed?.round() ?? 0} km/h',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.speedometer,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'mid: ${track.middleSpeed?.round() ?? 0} km/h',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.resize_v,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'max: ${track.maxHeight?.round() ?? 0} m',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.resize_h,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${((track.currentDistance ?? 0) / 1000).toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.clock,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            track.trackDuration != null
                                                ? printDuration(track.trackDuration!)
                                                : '00:00:00',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _exportTrack(track),
                                  icon: const Icon(
                                    CupertinoIcons.share_up,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Выгрузить трек',
                                ),
                                IconButton(
                                  onPressed: () => _deleteTrack(index),
                                  icon: const Icon(
                                    CupertinoIcons.trash,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Удалить трек',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
