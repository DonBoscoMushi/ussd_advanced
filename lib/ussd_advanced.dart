/// Run ussd code directly in your application
import 'dart:async';

import 'package:flutter/services.dart';

class UssdAdvanced {
  static const MethodChannel _channel =
      MethodChannel('method.com.phan_tech/ussd_advanced');
  //Initialize BasicMessageChannel
  static const BasicMessageChannel<String> _basicMessageChannel =
      BasicMessageChannel("message.com.phan_tech/ussd_advanced", StringCodec());

  static Future<void> sendUssd(
      {required String code, int subscriptionId = 1}) async {
    await _channel.invokeMethod(
        'sendUssd', {"subscriptionId": subscriptionId, "code": code});
  }

  static Future<String?> sendAdvancedUssd(
      {required String code, int subscriptionId = 1}) async {
    final String? response = await _channel
        .invokeMethod('sendAdvancedUssd',
            {"subscriptionId": subscriptionId, "code": code})
        .timeout(const Duration(seconds: 30))
        .catchError((e) {
          throw e;
        });
    return response;
  }

  static Future<String?> multisessionUssd(
      {required String code, int subscriptionId = 1}) async {
    var _codeItem = _CodeAndBody.fromUssdCode(code);
    String response = await _channel.invokeMethod('multisessionUssd', {
          "subscriptionId": subscriptionId,
          "code": _codeItem.code
        }).catchError((e) {
          throw e;
        }) ??
        '';

    if (_codeItem.messages != null) {
      var _res = await sendMultipleMessages(_codeItem.messages!);
      response += "\n$_res";
    }
    return response;
  }

  static Future<void> cancelSession() async {
    await _channel
        .invokeMethod(
      'multisessionUssdCancel',
    )
        .catchError((e) {
      throw e;
    });
  }

  static Future<String?> sendMessage(String message) async {
    var _response = await _basicMessageChannel.send(message).catchError((e) {
      throw e;
    });
    return _response;
  }

  static Future<String?> sendMultipleMessages(List<String> messages) async {
    var _response = "";
    for (var m in messages) {
      // var _res = await sendMessage(m);
      var _res = sendAdvancedUssd(code: m, subscriptionId: 0);
      _response += "\n$_res";
    }

    return _response;
  }

  static StreamController<String?> onEnd() {
    StreamController<String?> _streamController = StreamController<String?>();
    _basicMessageChannel.setMessageHandler((message) async {
      _streamController.add(message);
      return message ?? '';
    });

    return _streamController;
  }

  static Future<bool> hasPermissions()async{
    try{
      return (await _channel.invokeMethod('hasPermissions')) == true;
    }catch(_){return false;}
  }

  static void requestPermissions(){
    try{
      _channel.invokeMethod('requestPermissions');
    }catch(_){}
  }
}

class _CodeAndBody {
  _CodeAndBody(this.code, this.messages);
  _CodeAndBody.fromUssdCode(String _code) {
    //Find the first '#' position
    int hashIndex = _code.indexOf('#');

    if (hashIndex == -1) {
      throw Exception("Invalid USSD code format");
    }

    //Split the code part (including '#')
    code = _code.substring(0, hashIndex + 1);

    //Extract the remaining part after the first '#'
    String remaining = _code.substring(hashIndex + 1);

    if (remaining.endsWith('#')) {
      //If the remaining part ends with '#', remove it
      remaining = remaining.substring(0, remaining.length - 1);
    }

    //If there is something after the first '#', split it by '*'
    if (remaining.isNotEmpty) {
      messages = remaining.split('*');
    } else {
      messages = [];
    }
  }
  late String code;
  List<String>? messages;
}
