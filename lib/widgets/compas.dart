
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart';


class CompassWidget extends StatefulWidget {
  @override
  CompassWidgetState createState() => CompassWidgetState();
}

class CompassWidgetState extends State<CompassWidget> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
return Container(
  width: 50,
  height: 50,
  child: Stack(
    alignment: Alignment.center,
    children: [
      const Positioned(
        top:0,
          left: 22,
          child: Text('C',style: TextStyle(fontSize: 10, color:Colors.white))),
    const Positioned(
      bottom:0,
      left: 22,
      child: Text('Ю',style: TextStyle(fontSize: 10, color:Colors.white))),
    const Positioned(
      bottom:18,
      right: 0,
      child: Text('З',style: TextStyle(fontSize: 10, color:Colors.white))),
    const Positioned(
      bottom:18,
      left: 0,
      child: Text('В',style: TextStyle(fontSize: 10, color:Colors.white))),
      Transform.rotate(
          angle: trackModel.azimuth * pi / 180,
          child:const Icon(CupertinoIcons.location_north_fill, color: Colors.orange,)
      )
    ],
  )
);

  }


}