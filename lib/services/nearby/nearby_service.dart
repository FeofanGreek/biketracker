
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../screens/map.dart';
import 'nearby_peer_model.dart';

class NearbyController with ChangeNotifier{
  NearbyController(){
    init();
  }

  List<Device> devices = [];
  List<Device> connectedDevices = [];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;
  String deviceId = '';

  void init() async {
    const uuid = Uuid();
    deviceId = uuid.v4();
    nearbyService = NearbyService();
    //deviceId = '${DateTime.now()}';
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // if (Platform.isAndroid) {
    //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //   devInfo = androidInfo.model;
    // }
    // if (Platform.isIOS) {
    //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    //   devInfo = iosInfo.localizedModel;
    // }
    await nearbyService.init(
        serviceType: 'bike-con',
        deviceName: deviceId,
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            //if (widget.deviceType == DeviceType.browser) {

              //await nearbyService.stopBrowsingForPeers();
              //await Future.delayed(const Duration(microseconds: 200));
              //await nearbyService.startBrowsingForPeers();
            //} else {
              //await nearbyService.stopAdvertisingPeer();
              //await nearbyService.stopBrowsingForPeers();
              //await Future.delayed(const Duration(microseconds: 200));
              await nearbyService.startAdvertisingPeer();
              await nearbyService.startBrowsingForPeers();
            //}
          }
        });
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
          for (var element in devicesList) {
            if (kDebugMode) {
              //print("deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");
            }

            if (Platform.isAndroid) {
              if (element.state == SessionState.connected) {
                nearbyService.stopBrowsingForPeers();
              } else {
                nearbyService.startBrowsingForPeers();
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
        nearbyService.dataReceivedSubscription(callback: (data) {
          final peer = data;
          //print("dataReceivedSubscription: ${peer}");
          // showToast(jsonEncode(data),
          //     context: context,
          //     axis: Axis.horizontal,
          //     alignment: Alignment.center,
          //     position: StyledToastPosition.bottom);
          int indexedPeer = nearbyPeers.indexWhere((e)=>e.deviceId == peer['deviceId']);
          if(nearbyPeers.isEmpty && indexedPeer == -1){
            nearbyPeers.add(NearbyPeer(deviceId: peer['deviceId'], position: Position.fromMap(jsonDecode(peer['message'])), color: getRandomColor()));
          }else{
            nearbyPeers.firstWhere((e)=>e.deviceId == peer['deviceId']).position = Position.fromMap(jsonDecode(peer['message']));
          }
        });
  }

  List<NearbyPeer> nearbyPeers = [];

Future<void> sendPositions(Position position)async{

  //final device = devices.firstWhere((e)=>e.deviceId == deviceId, orElse: ()=>devices.first);
  if(devices.isNotEmpty) {
    for (final item in devices) {
      if(item.deviceId != deviceId) {
        if(item.state == SessionState.notConnected) {
          await nearbyService.invitePeer(
          deviceID: item.deviceId,
          deviceName: item.deviceName,
        );
         await Future.delayed(const Duration(seconds: 1));
        }
        if(item.state == SessionState.connected) {
          await nearbyService.sendMessage(
            item.deviceId,
            jsonEncode(position.toJson(),),);
          //await nearbyService.disconnectPeer(deviceID: item.deviceId);
        }
      }
    }
  }
}


  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsingForPeers();
    nearbyService.stopAdvertisingPeer();
    super.dispose();
  }

  void update(){
    notifyListeners();
  }
}