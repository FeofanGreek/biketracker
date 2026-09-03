

import 'dart:ui';

import 'package:geolocator/geolocator.dart';

class NearbyPeer{
  NearbyPeer({
    required this.deviceId,
    required this.position,
    required this.color,
});
  String deviceId;
  Position position;
  Color color;
}