// Новый файл: health_data_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthDataService {
  final Health health = Health();

  // Все типы данных для записи
  List<HealthDataType> get _typesToWrite => (Platform.isAndroid)
      ? [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_CYCLING,
  ]
      : [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_CYCLING, // Для iOS
  ];

  // Все разрешения на чтение и запись
  List<HealthDataAccess> get _permissions => _typesToWrite
      .map((e) => HealthDataAccess.READ_WRITE)
      .toList();

  // Запрашивает разрешения у пользователя
  Future<bool> requestPermissions() async {
    // Запрашиваем разрешения, необходимые для записи тренировок
    await Permission.activityRecognition.request();
    await Permission.location.request();

    bool? hasPermissions = await health.hasPermissions(_typesToWrite, permissions: _permissions);

    // Если разрешений нет, запрашиваем их
    if (hasPermissions != true) {
      try {
        hasPermissions = await health.requestAuthorization(_typesToWrite, permissions: _permissions);
      } catch (e) {
        debugPrint("Error requesting permissions: $e");
      }
    }
    return hasPermissions ?? false;
  }

  // Сохраняет данные о тренировке
  Future<void> saveWorkoutData({
    required DateTime startTime,
    required DateTime endTime,
    required double distanceMeters,
    required double caloriesBurned,
    required String workoutName,
  }) async {
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      debugPrint("Authorization not granted. Cannot save data.");
      return;
    }

    try {
      final success = await health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.BIKING,
        title: workoutName,
        start: startTime,
        end: endTime,
        totalDistance: distanceMeters.toInt(),
        totalEnergyBurned: caloriesBurned.toInt(),
      );

      if (success) {
        debugPrint('Workout data successfully saved.');
      } else {
        debugPrint('Failed to save workout data.');
      }
    } catch (e) {
      debugPrint('Error saving workout data: $e');
    }
  }
}