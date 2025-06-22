

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



///кнопка
///можно менять цвет фона
///можно менять цвет шрифта
///можно менять статус при нажатии
///можно отображать рпелоадер
class ButtonBrand extends StatefulWidget {
  Color backGroundColor;
  Color backGroundColorOnTap;
  Color labelColor;
  Color labelColorOnTap;
  Widget iconWidget;
  String labelText;
  String labelTextOnComplite;
  ValueChanged<String> func;
  bool withPreloader;
  Duration preloaderDuration;
  bool changeColorOnTap;
  bool active;
  EdgeInsetsGeometry? margin;



  ButtonBrand({
  super.key,
  this.backGroundColor = const Color(0xFFFF6A2B),
  this.backGroundColorOnTap = const Color(0xFFFF6A2B),
  this.labelColor = const Color(0xFFFFFFFF),
  this.labelColorOnTap = const Color(0xFFFFFFFF),
  this.iconWidget = const SizedBox.shrink(),
  required this.labelText,
  this.labelTextOnComplite = '',
  this.withPreloader = false,
  this.changeColorOnTap = false,
  required this.func,
  this.active = true,
  this.margin = const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
  this.preloaderDuration = const Duration(seconds: 1)
  });

  @override
  ButtonBrandState createState() => ButtonBrandState();
}
class ButtonBrandState extends State<ButtonBrand> {

bool tap = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  returnColor(){
    if(widget.active){
      if(!tap){
        return widget.backGroundColor;
      }else{
        if(!widget.changeColorOnTap){
          return widget.backGroundColor.withOpacity(0.2);
        }else{
          return  widget.backGroundColorOnTap;
        }
      }
    }else{
      return Color(0xFFE8ECEF);
    }

  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        ///запускаем процедуру анимации нажатия
        setState(() {
         tap = true;
        });
        widget.active ?
        widget.func(DateTime.now().toString()) : null;
        Timer(widget.preloaderDuration, (){
          widget.withPreloader ? tap = false : null;
          if(mounted)
          setState(() {

          });
        });
      },
      child: AnimatedContainer(
        height: 48,
        margin: widget.margin,
          decoration: BoxDecoration(
            // color: widget.active ?
            // !tap ? widget.backGroundColor
            //     : !widget.changeColorOnTap
            //     ? widget.backGroundColor.withOpacity(0.2)
            //     : widget.backGroundColorOnTap
            //     : Color(0xFFE8ECEF).withOpacity(0.1),
            color: returnColor(),
            borderRadius: const BorderRadius.all(Radius.circular(7.0)),
          ),
        duration: Duration(milliseconds: 100),
        onEnd: (){
          ///завершаем процедуру анимации нажатия, сменой переменной tap будет управлять функция onTap
          setState(() {
            !widget.changeColorOnTap && !widget.withPreloader ? tap = false : null;
          });
        },
        child: widget.withPreloader && tap ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(width: 30, height: 30, child: CircularProgressIndicator())
            ])
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.iconWidget,
            const SizedBox(width: 5,),
            Text(widget.labelText, style: TextStyle(fontSize: 14, color: widget.active ? !tap ? widget.labelColor : !widget.changeColorOnTap ? widget.labelColor : widget.labelColorOnTap : widget.labelColor.withOpacity(0.3), fontWeight: FontWeight.w500),)
          ],
        )
      ),
    );
  }

}