import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../command.dart';

class CommonProvider extends ChangeNotifier {
  var targetServiceUuid = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  var targetCharacteristicUuid = Guid('0000ffe1-0000-1000-8000-00805f9b34fb');
  var characterUuidNotify = Guid("0000ffe2-0000-1000-8000-00805f9b34fb");

  late BluetoothDevice device;
  bool isConnected = false;
  bool isFanOn = false;

  double selectedWindSpeed = 0;
  double selectedBrightness = 0;
  double timerValue = 0;

  Timer? timer;

  int batteryLevel = 0;
  bool isCharging = false;

  Future<BluetoothCharacteristic> getChar() async {
    List<BluetoothService> services = await device.discoverServices();

    var targetService =
        services.firstWhere((service) => service.uuid == targetServiceUuid);

    return targetService.characteristics.firstWhere(
        (characteristic) => characteristic.uuid == targetCharacteristicUuid);
  }

  Future<BluetoothCharacteristic> getReadChar() async {
    List<BluetoothService> services = await device.discoverServices();

    var targetService =
    services.firstWhere((service) => service.uuid == targetServiceUuid);

    return targetService.characteristics.firstWhere(
            (characteristic) => characteristic.uuid == targetCharacteristicUuid);
  }

  void send(c, cmdList) async {
    List<int> cmd = [53, 8, 2, 1, 0, 1];
    cmd.addAll(cmdList);

    print(cmd);
    await c.write(cmd);
  }

  void clickPowerButton() async {
    if (!isConnected || device == null) {
      return;
    }

    List<int> cmd;

    if (!isFanOn) {
      cmd = Command.turnOn.value;
    } else {
      cmd = Command.turnOff.value;
    }

    getChar().then((c) => {send(c, cmd)});
    isFanOn = !isFanOn;
    selectedWindSpeed = isFanOn ? 1 : 0;

    if(!isFanOn) {
      adjustBrightness(0.0);
      timerValue = 0;
      timer?.cancel();
    }

    notifyListeners();
  }

  void adjustWindSpeed(windSpeed) {
    Command windSpeedCmd = Command.windOff;
    switch (windSpeed) {
      case 0:
        windSpeedCmd = Command.windOff;
      case 1:
        windSpeedCmd = Command.wind_1;
      case 2:
        windSpeedCmd = Command.wind_2;
      case 3:
        windSpeedCmd = Command.wind_3;
      case 4:
        windSpeedCmd = Command.windNatural;
    }

    getChar().then((c) => {send(c, windSpeedCmd.value)});
    selectedWindSpeed = windSpeed;

    notifyListeners();
  }

  void adjustBrightness(brightness) {
    Command windSpeedCmd = Command.lightOff;
    switch (brightness) {
      case 0:
        windSpeedCmd = Command.lightOff;
      case 1:
        windSpeedCmd = Command.light_1;
      case 2:
        windSpeedCmd = Command.light_2;
      case 3:
        windSpeedCmd = Command.light_3;
    }

    getChar().then((c) => {send(c, windSpeedCmd.value)});
    selectedBrightness = brightness;

    notifyListeners();
  }

  void setTimer(value) {
    var i = (value / 359.0 * 240.0).toInt();
    List<int> cmd = [4, i, 125, 187];

    getChar().then((c) => {send(c, cmd)});

    notifyListeners();
  }

  void connect(device) async {
    BotToast.showText(text: '연결 시작');
    await FlutterBluePlus.stopScan();
    // await device.device.connect(mtu: null, autoConnect: true);

    while(true) {
      try {
        await device.connect(mtu: null);
        break;
      } catch(e) {
        print(e);
        BotToast.showText(text: '연결 재시도');
      }
    }

    BotToast.showText(text: '연결되었습니다.');

    //todo 연결 성공 검증, 실패 얼럿
    isConnected = true;
    this.device = device;

    notifyListeners();
  }
}
