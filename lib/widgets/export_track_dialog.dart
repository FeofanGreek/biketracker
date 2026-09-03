import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/track_export_service.dart';
import '../services/track_model.dart';
import '../utilites/variables.dart';

Future<void> showExportTrackDialog({
  required BuildContext context,
  required Track track,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return _ExportTrackDialog(track: track);
    },
  );
}

class _ExportTrackDialog extends StatefulWidget {
  final Track track;

  const _ExportTrackDialog({required this.track});

  @override
  State<_ExportTrackDialog> createState() => _ExportTrackDialogState();
}

class _ExportTrackDialogState extends State<_ExportTrackDialog> {
  ExportFormat _selectedFormat = ExportFormat.gpx;
  List<SaveLocationOption> _locations = [];
  int _selectedLocationIndex = 0;
  bool _isLoadingLocations = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locs = await TrackExportService.getAvailableSaveLocations();
    if (mounted) {
      setState(() {
        _locations = locs;
        _isLoadingLocations = false;
        _selectedLocationIndex = 0;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_locations.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final targetLoc = _locations[_selectedLocationIndex];
      final savedFile = await TrackExportService.saveTrackFile(
        track: widget.track,
        format: _selectedFormat,
        targetDirectory: targetLoc.path,
      );

      SystemSound.play(SystemSoundType.click);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: darkBlue,
            duration: const Duration(seconds: 4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Трек успешно выгружен (${_selectedFormat == ExportFormat.gpx ? "GPX" : "FIT"})',
                      style: white14,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  savedFile.path,
                  style: TextStyle(fontSize: 12, color: semiLightBlue),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('Ошибка сохранения: $e', style: white14),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: darkBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(CupertinoIcons.share_up, color: Colors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Выгрузить трек', style: white18),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(CupertinoIcons.clear, color: someBlue, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.track.name ?? 'Трек',
              style: semiLightBlue14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),

            // Выбор формата
            Text('Формат файла:', style: white14),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFormatCard(
                    format: ExportFormat.gpx,
                    title: 'GPX',
                    subtitle: 'GPS XML',
                    icon: CupertinoIcons.map_pin_ellipse,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatCard(
                    format: ExportFormat.fit,
                    title: 'FIT',
                    subtitle: 'Garmin / Strava',
                    icon: CupertinoIcons.flame_fill,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Выбор места сохранения
            Text('Место сохранения:', style: white14),
            const SizedBox(height: 8),
            if (_isLoadingLocations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              )
            else if (_locations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Нет доступных папок для сохранения', style: semiLightBlue14),
              )
            else
              Column(
                children: List.generate(_locations.length, (index) {
                  final loc = _locations[index];
                  final isSelected = _selectedLocationIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLocationIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withAlpha(40)
                              : mainBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.orange : Colors.white10,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              loc.icon,
                              color: isSelected ? Colors.orange : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.orange : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    loc.subtitle,
                                    style: TextStyle(
                                      color: semiLightBlue,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 18),

            // Кнопки управления
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: backGroundColorButtonGrey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Сохранить',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required ExportFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFormat = format;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withAlpha(40) : mainBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: semiLightBlue,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
