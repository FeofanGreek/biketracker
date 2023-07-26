import 'package:geolocator/geolocator.dart';

import 'dialog.dart';
import 'main.dart';

final LocationSettings locationSettings = AppleSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0, ///по хорошему 0 надо поставить, но ставили 3 мигает индикатор GPS
    activityType: ActivityType.automotiveNavigation,
    showBackgroundLocationIndicator: false,
    allowBackgroundLocationUpdates: true,
    pauseLocationUpdatesAutomatically: false
);

startGeolocation(context)async{
  await Geolocator.checkPermission().then((value){
    if(value == LocationPermission.unableToDetermine){
      ///вывести диалог, что на девайсе нет геолокаци
      showAlertDialog(
        context: context,
        title: 'Не обнаружен GPS',
        body: "Для ориентирования на местности необходим приемник сигнала спутников геолокации",
        showBottomButton: true,
        showTopButton:  false,
      );
    }else if(value == LocationPermission.deniedForever || value == LocationPermission.denied){
      ///вывести диалог с предложением открыть настройки и включить геолокацию
      Geolocator.requestPermission().then((value) => startGeolocation(context));
      ///запустить диалог запроса доступа
      // showAlertDialog(
      //   context: context,
      //   title: 'Нет доступа к GPS',
      //   body: "Для ориентирования на местности необхоимо предоставить доступ к спутниковой навигации",
      //   topButtonTitle: 'В настройки',
      //   topButtonFunc: ()=>Geolocator.openLocationSettings(),
      //   showBottomButton: true,
      //   showTopButton:  true,
      // );
    }else if(value == LocationPermission.always || value == LocationPermission.whileInUse){
      ///начать отслеживать геопозицию
      trackModel.positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) => trackModel.setValues(position!));
    }
  });
}