import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';


class recordPositionButton extends StatefulWidget {


  @override
  _recordPositionButtonState createState() => _recordPositionButtonState();
}
class _recordPositionButtonState extends State<recordPositionButton> {

  late Timer colorTimer;
  int colorCounter = 100;

  @override
  void initState() {
    colorTimer = Timer.periodic(Duration(milliseconds: 100),(v){
      setState(() {
        if(colorCounter < 1000){
          colorCounter += 100;
        }else{
          colorCounter = 100;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    colorTimer.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return IconButton(
        iconSize: 30,
        style: TextButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          foregroundColor: Colors.white,
          backgroundColor: Colors.orange,
        ),
        onPressed: () {
          setState(() {
            trackModel.recordInProgress = !trackModel.recordInProgress;
            if(!trackModel.recordInProgress) {
              trackModel.stopRecord();
            }else{
              trackModel.startRecord();
            }
            SystemSound.play(SystemSoundType.click);
          });
        },
        icon: Icon(!trackModel.recordInProgress ? Icons.fiber_manual_record : Icons.stop,
          color: trackModel.recordInProgress ? Colors.red.withOpacity(colorCounter /1000) : Colors.green,));
  }
}
