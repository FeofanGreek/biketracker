
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../screens/map.dart';
import 'nearby_peer_model.dart';

class NearbyController with ChangeNotifier {
  NearbyController();

  List<Device> devices = [];
  List<Device> connectedDevices = [];
  List<NearbyPeer> nearbyPeers = [];
  NearbyService? nearbyService;
  StreamSubscription? subscription;
  StreamSubscription? receivedDataSubscription;
  String deviceId = '';
  bool isRunning = false;

  Future<void> start() async {
    if (isRunning) return;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const uuid = Uuid();
    deviceId = uuid.v4();
    final service = NearbyService();
    nearbyService = service;

    await service.init(
        serviceType: 'bike-con',
        deviceName: deviceId,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunningState) async {
          if (isRunningState) {
            await service.startAdvertisingPeer();
            await service.startBrowsingForPeers();
          }
        });

    subscription =
        service.stateChangedSubscription(callback: (devicesList) {
          for (var element in devicesList) {
            if (kDebugMode) {
              //print("deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");
            }

            if (Platform.isAndroid) {
              if (element.state == SessionState.connected) {
                service.stopBrowsingForPeers();
              } else {
                service.startBrowsingForPeers();
              }
            }
          }

          devices.clear();
          devices.addAll(devicesList);
          connectedDevices.clear();
          connectedDevices.addAll(devicesList
              .where((d) => d.state == SessionState.connected)
              .toList());
          notifyListeners();
        });

    receivedDataSubscription =
        service.dataReceivedSubscription(callback: (data) {
          final peer = data;
          int indexedPeer = nearbyPeers.indexWhere((e)=>e.deviceId == peer['deviceId']);
          if(nearbyPeers.isEmpty && indexedPeer == -1){
            nearbyPeers.add(NearbyPeer(deviceId: peer['deviceId'], position: Position.fromMap(jsonDecode(peer['message'])), color: getRandomColor()));
          }else{
            nearbyPeers.firstWhere((e)=>e.deviceId == peer['deviceId']).position = Position.fromMap(jsonDecode(peer['message']));
          }
          notifyListeners();
        });

    isRunning = true;
    notifyListeners();
  }

  Future<void> stop() async {
    if (!isRunning) return;

    try {
      await subscription?.cancel();
      await receivedDataSubscription?.cancel();
      subscription = null;
      receivedDataSubscription = null;
      await nearbyService?.stopBrowsingForPeers();
      await nearbyService?.stopAdvertisingPeer();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping nearby: $e');
      }
    }

    devices.clear();
    connectedDevices.clear();
    nearbyPeers.clear();
    isRunning = false;
    notifyListeners();
  }

  Future<void> toggle() async {
    if (isRunning) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> sendPositions(Position position) async {
    if (!isRunning || nearbyService == null) return;
    if (devices.isNotEmpty) {
      for (final item in devices) {
        if (item.deviceId != deviceId) {
          if (item.state == SessionState.notConnected) {
            await nearbyService?.invitePeer(
              deviceID: item.deviceId,
              deviceName: item.deviceName,
            );
            await Future.delayed(const Duration(seconds: 1));
          }
          if (item.state == SessionState.connected) {
            await nearbyService?.sendMessage(
              item.deviceId,
              jsonEncode(position.toJson()),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    receivedDataSubscription?.cancel();
    nearbyService?.stopBrowsingForPeers();
    nearbyService?.stopAdvertisingPeer();
    super.dispose();
  }

  void update() {
    notifyListeners();
  }
}