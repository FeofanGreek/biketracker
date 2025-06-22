
import 'dart:ui';

import 'package:biketracker/variables.dart';
import 'package:biketracker/widgets/button.dart';
import 'package:biketracker/widgets/height_margin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



///показываем алерт диалог
showAlertDialog({
  context,
  String title = '',
  String body = '',
  String topButtonTitle = '',
  topButtonFunc,
  showBottomButton = true,
  showTopButton = true,
  showCloseButton = false,
  Widget? dialogBody,
}){
  return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0 , 0),
          insetPadding: const EdgeInsets.all(0),
          elevation: 0.0,
          content:BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 50,
                  alignment: Alignment.center,
                  child: Container(
                    constraints:  const BoxConstraints(minWidth: 200.0, maxWidth: 300, minHeight: 100.0, maxHeight: 550),
                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(11),
                      color: darkBlue,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20 , 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Row(
                          children: [
                            if(showCloseButton)const Spacer(),
                            Container(
                              width: 210,
                              child: Text(title, style: white15_500,),
                            ),
                            if(showCloseButton)Spacer(),
                            if(showCloseButton)IconButton(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              onPressed: ()=>Navigator.pop(context),
                              icon: Icon(CupertinoIcons.clear, color: someBlue,)
                            ),
                          ],
                        ),
                        if(body != '')const SizedBox(height: 10,),
                        if(body != '')Text(body, style: semiLightBlue14,),
                        if(dialogBody != null)dialogBody,
                        heightMargin(),
                        if(showTopButton)ButtonBrand(
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          backGroundColor : backGroundColorButtonOrange,
                          backGroundColorOnTap: backGroundColorButtonGrey,
                          labelColor: labelButtonColorWhite,
                          labelColorOnTap: labelButtonColorBlue,
                          labelTextOnComplite: '',
                          withPreloader: true,
                          changeColorOnTap: false,
                          labelText: topButtonTitle,
                          func: (value)=>topButtonFunc(),
                        ),
                        const SizedBox(height: 15,),
                        if(showBottomButton)ButtonBrand(
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          backGroundColor : backGroundColorButtonGrey,
                          labelColor: labelButtonColorBlue,
                          //iconWidget: SizedBox.shrink(),
                          labelTextOnComplite: '',
                          withPreloader: false,
                          changeColorOnTap: false,
                          labelText: 'Отмена',
                          func: (value)=>Navigator.pop(context),
                        ),
                      ],
                    ),
                  )
              )
          ),
        );
      });

}