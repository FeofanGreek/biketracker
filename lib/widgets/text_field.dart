
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:ui';
import '../variables.dart';

///поле ввода
///надо маску
///надо тип клавиатуры
///надо передаваемое и восзвращаемое значение в функции
///тайтл
///хинт

class TextFieldBrand extends StatefulWidget {
  ///0 - нет маски, 1 - телефон, 2 - емайл, 3 - номер авто, 4 - номер кредитки, 5 - СМС код, 6 - простотексты, 7 - маска срока действия карты, 8 - маска CVV
  int maskType;
  ///0 - текст, 1- digits,  2 - phone, 3- email, 4 - цифры с доп параметром
  int keyType;
  ValueChanged<String> func;
  String title;
  String hint;
  double width;
  String initialValue;
  bool errorFromOutside;
  String textErrorFromOutside;
  //bool enable;
  int maxLines;
  dynamic clearFunc;

  TextFieldBrand({
    required this.title,
    required this.hint,
    required this.maskType,
    required this.keyType,
    required this.func,
    required this.width,
    required this.initialValue,
    this.errorFromOutside = false,
    this.textErrorFromOutside = '',
    //this.enable = true,
    this.maxLines = 1,
    this.clearFunc
  });

  @override
  TextFieldBrandState createState() => TextFieldBrandState();

}

class TextFieldBrandState extends State<TextFieldBrand> {
  FocusNode myFocusNode = FocusNode();
  void _requestFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(myFocusNode);
    });
  }


  MaskTextInputFormatter mask(){
    MaskTextInputFormatter value = MaskTextInputFormatter(mask: '', filter: { "#": RegExp(r'[0-9a-zA-Z]') });
    switch(widget.maskType){
      case 1 : {
        value = MaskTextInputFormatter(mask: '+7 (###) ###-##-##', filter: { "#": RegExp(r'[0-9]') });
        break;
      }
      case 2 : {
        value = MaskTextInputFormatter(mask: '', filter: { "#": RegExp(r'[0-9a-zA-Z@.]') });
        break;
      }
      case 3 : {
        value = MaskTextInputFormatter(
            mask: 'A ### AA ###', filter: { "#": RegExp(r'[0-9]'), "A" : RegExp(r'[АВЕКМНОРСТХавекмнорстх]'), },
            initialText: widget.initialValue
            );
        break;
      }
      case 4 : {
        value = MaskTextInputFormatter(mask: '#### #### #### ####', filter: { "#": RegExp(r'[0-9]') });
        break;
      }
      case 5 : {
        value = MaskTextInputFormatter(mask: '######', filter: { "#": RegExp(r'[0-9]') });
        break;
      }
      case 6 : {
        value = MaskTextInputFormatter(mask: '', filter: { "#": RegExp(r'[0-9a-zA-Zа-яА-Я]') });
        break;
      }
      case 7 : {
        value = MaskTextInputFormatter(mask: '##/##', filter: { "#": RegExp(r'[0-9]') });
        break;
      }
      case 8 : {
        value = MaskTextInputFormatter(mask: '###', filter: { "#": RegExp(r'[0-9]') });
        break;
      }
    }
    return value;
  }

  TextEditingController _controllerPhone = TextEditingController(text: '');
  var maskFormatterPhone = MaskTextInputFormatter(mask: '');

  ///выбор типа клавиатуры
  TextInputType inputType(){
    TextInputType type = TextInputType.text;
    switch(widget.keyType){
      case 0 : {

        type = TextInputType.text;
        break;
      }
      case 1 : {
        type = TextInputType.number;
        break;
      }
      case 2 : {
        type = TextInputType.phone;
        break;
      }
      case 3 : {
        type = TextInputType.emailAddress;
        break;
      }
      case 4 : {
        type = const TextInputType.numberWithOptions(
            decimal: true,
            signed: true);
        break;
      }
    }
    return type;
  }

  String errorMessageString = '';

  ///обработчик ошибок
  errorChek(){
    bool error = false; ///ошибки нету
    switch(widget.maskType){
    ///что бы не ввели все ОК
      case 0 : {
        error = false;
        break;
      }
    ///телефон должен быть не менее 18 символов +7 (916) 318-15-00
      case 1 : {
        if(_controllerPhone.text.isEmpty){
          ///ошибки быть не может
          errorMessageString = '';
          error = false;
        }
        else if(_controllerPhone.text.length == 18){
          ///передаем управление внешнему контроллеру
          errorMessageString = widget.textErrorFromOutside;
          error = widget.errorFromOutside;
        }else{
          ///контролируем ввод номера
          errorMessageString = 'Не полностью введен номер телефона';
          error = true;
        }

        break;
      }
    ///емайл должен содержать собаку и точку
      case 2 : {
        RegExp exp = RegExp(r'[0-9a-zA-Z]');
        if(_controllerPhone.text.isEmpty){
          errorMessageString = '';
          error = false;
        }
        else if((_controllerPhone.text.isNotEmpty && _controllerPhone.text.contains('@') && _controllerPhone.text.contains('.') && exp.hasMatch(_controllerPhone.text)) || _controllerPhone.text.isEmpty){
          errorMessageString = '';
          error = false;
        }else{
          errorMessageString = 'Не верно введен адрес электронной почты';
          error = true;

        }
        break;
      }
      case 5 : {
        if(_controllerPhone.text.isEmpty){
          errorMessageString = '';
          error = false;
        }else{
          errorMessageString = widget.textErrorFromOutside;
          error = widget.errorFromOutside;
        }


        break;
      }
      case 6 : {
        errorMessageString = widget.textErrorFromOutside;
        error = widget.errorFromOutside;
        break;
      }
      default : {
        errorMessageString = widget.textErrorFromOutside;
        error = widget.errorFromOutside;
        break;
      }
    }
    return error;
  }

  @override
  void initState() {

    maskFormatterPhone = mask();
    _controllerPhone = TextEditingController(text: widget.initialValue);
    super.initState();
  }
  @override
  void didUpdateWidget(covariant TextFieldBrand oldWidget) {
    errorChek();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.fromLTRB(0,0,0,0),
        padding: const EdgeInsets.fromLTRB(0,0,0,0),
        alignment: Alignment.topCenter,
        width: widget.width - 40,
        child:TextFormField(
          maxLines: widget.maxLines,
          onTap: _requestFocus,
          focusNode: myFocusNode,
          textAlign: TextAlign.left,
          //enabled: widget.enable,
          inputFormatters: [maskFormatterPhone],
          keyboardType: inputType(),
          style: TextStyle(fontSize: 15.0, color: errorChek() ? errorBorder : Colors.white,fontFamily: 'Inter',),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(
              left: 15,
              top: 10,
              bottom: 3
            ),
            hintStyle: TextStyle(fontSize: 15.0, color: semiBlue,fontFamily: 'Inter',),
            hintText: widget.hint,
            suffixIcon: IconButton(
              onPressed: (){
                _controllerPhone.clear();
                setState(() {});
                widget.clearFunc != null ? widget.clearFunc() : null;
              },
              icon: Icon(Icons.clear, color: errorChek() ? errorBorder : semiBlue),
            ),
            border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(7.0)),
                borderSide: BorderSide(color:semiBlue, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(7.0)),
                borderSide: BorderSide(color: semiBlue)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.0),
              borderSide: BorderSide(color: semiBlue, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.0),
              borderSide: BorderSide(
                color: errorBorder,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7.0),
              borderSide: BorderSide(
                color: errorBorder,
                width: 2.0,
              ),
            ),
            labelText: widget.title,
            labelStyle: TextStyle(fontSize: 15.0, color: errorChek() ? errorBorder : semiBlue,fontFamily: 'Inter'),
          ),
          onChanged: (_){

            //!errorChek() ?
            widget.func(_controllerPhone.text);
                //: null;
            setState(() { });
          },
          validator: (value)=>errorChek() ? errorMessageString : null,
          autovalidateMode: AutovalidateMode.always,
          controller: _controllerPhone,
        ));
  }

}

