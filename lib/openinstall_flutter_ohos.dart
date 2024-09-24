import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

typedef Future EventHandler(Map<String, Object> data);

class OpeninstallFlutterPlugin {
  // 单例
  static final OpeninstallFlutterPlugin _instance = new OpeninstallFlutterPlugin._internal();

  factory OpeninstallFlutterPlugin() => _instance;

  OpeninstallFlutterPlugin._internal();

  Future defaultHandler() async {}

  late EventHandler _wakeupHandler;
  late EventHandler _installHandler;

  static const MethodChannel _channel = const MethodChannel('openinstall_flutter_ohos');

  // wakeupHandler 拉起回调.
  void init(EventHandler wakeupHandler) {
    _wakeupHandler = wakeupHandler;
    _channel.setMethodCallHandler(_handleMethod);
    // _channel.invokeMethod("registerWakeup");
    _channel.invokeMethod("init");
  }

  // SDK内部将会一直保存安装数据，每次调用install方法都会返回值。
  // 如果调用install获取到数据并处理了自己的业务，后续不想再被触发，那么可以自己在业务调用成功时，设置一个标识，不再调用install方法
  void install(EventHandler installHandler, [int seconds = 10]) {
    var args = new Map();
    args["seconds"] = seconds;
    this._installHandler = installHandler;
    _channel.invokeMethod('getInstall', args);
  }


  void reportRegister() {
    _channel.invokeMethod('reportRegister');
  }

  void reportEffectPoint(String pointId, int pointValue, [Map<String, String>? extraMap]) {
    var args = new Map();
    args["pointId"] = pointId;
    args["pointValue"] = pointValue;
    if (extraMap != null) {
      args["extras"] = extraMap;
    }
    _channel.invokeMethod('reportEffectPoint', args);
  }

  Future<Map<Object?, Object?>> reportShare(String shareCode, String platform) async {
    var args = new Map();
    args["shareCode"] = shareCode;
    args["platform"] = platform;
    Map<Object?, Object?> data = await _channel.invokeMethod('reportShare', args);
    return data;
  }

  Future<String?> getOpid() async {
    print("getOpid 当初始化未完成时，将返回空，请在业务需要时再获取，并且使用时做空判断");
    String? opid = await _channel.invokeMethod('getOpid');
    return opid;
  }

  Future _handleMethod(MethodCall call) async {
    print(call.method);
    switch (call.method) {
      case "onWakeupNotification":
        return _wakeupHandler(call.arguments.cast<String, Object>());
      case "onInstallNotification":
        return _installHandler(call.arguments.cast<String, Object>());
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
  }
}
