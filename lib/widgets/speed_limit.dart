import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../main.dart';


class SpeedControlSlider extends StatefulWidget {
  const SpeedControlSlider({super.key});

  @override
  State<SpeedControlSlider> createState() => _SpeedControlSliderState();
}

class _SpeedControlSliderState extends State<SpeedControlSlider> {
  double _maxSpeed = 0.0; // Initial maximum speed setting
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isBeeping = false;

late Timer speedTimer;

  @override
  void initState() {
    super.initState();
    speedTimer = Timer.periodic(Duration(seconds: 5), (v)=>_checkSpeed());
    _checkSpeed(); // Initial check
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    speedTimer.cancel();
    super.dispose();
  }

  void _checkSpeed() {
    // This function checks if the current speed exceeds the maximum speed
    // and plays/stops the beep sound accordingly.
    if (trackModel.speed < _maxSpeed && !_isBeeping) {
      _startBeeping();
    } else if (trackModel.speed >= _maxSpeed && _isBeeping) {
      _stopBeeping();
    }
  }

  void _startBeeping() async {
    _isBeeping = true;
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('notif.wav'));
    print('Speed limit exceeded! Beeping started.');
  }

  void _stopBeeping() async {
    _isBeeping = false;
    await _audioPlayer.stop();
    print('Speed is now within limit. Beeping stopped.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Text(
        //   'Текущая скорость: ${trackModel.speed.toStringAsFixed(1)} км/ч',
        //   style: const TextStyle(fontSize: 20),
        // ),
        // const SizedBox(height: 20),
        // Text(
        //   'Максимальная скорость: ${_maxSpeed.toStringAsFixed(1)} км/ч',
        //   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        // ),
        Row(
          children: [
            Slider(
              activeColor: Colors.orange,
              value: _maxSpeed,
              min: 0,
              max: 200, // Adjust max value as needed
              divisions: 200, // Gives 200 discrete steps
              label: _maxSpeed.toStringAsFixed(1),
              onChanged: (double newValue) {
                setState(() {
                  _maxSpeed = newValue;
                  _checkSpeed(); // Re-check speed whenever the max speed changes
                });
              },
            ),
            Text(
              _maxSpeed.toStringAsFixed(1),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        // const SizedBox(height: 20),
        // // This button is just for demonstration to simulate changing currentSpeed
        // ElevatedButton(
        //   onPressed: () {
        //     setState(() {
        //       // Simulate increasing current speed
        //       trackModel.speed += 10.0;
        //       if (trackModel.speed > 150) trackModel.speed = 0.0; // Reset for demo
        //       _checkSpeed();
        //     });
        //   },
        //   child: const Text('Увеличить текущую скорость (для теста)'),
        // ),
      ],
    );
  }
}

