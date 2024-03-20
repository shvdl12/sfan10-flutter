import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../vo/command.dart';

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

  int batteryLevel = 0;
  bool isCharging = false;
  bool isFirst = true;

  late List<BluetoothService> services;

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  Future<BluetoothCharacteristic> getChar() async {
    var targetService =
        services.firstWhere((service) => service.uuid == targetServiceUuid);

    return targetService.characteristics.firstWhere(
        (characteristic) => characteristic.uuid == targetCharacteristicUuid);
  }



  void send(BluetoothCharacteristic c, cmdList) async {
    List<int> cmd = [53, 8, 2, 1, 0, 1];
    cmd.addAll(cmdList);

    await c.write(cmd);
  }

  void clickPowerButton() async {
    if (!isConnected || device == null) {
      return;
    }

    List<int> cmd = isFanOn ? Command.turnOff.value : Command.turnOn.value;

    getChar().then((c) => {send(c, cmd)});
    isFanOn = !isFanOn;
    selectedWindSpeed = isFanOn ? 1 : 0;

    if(!isFanOn) {
      adjustBrightness(0.0);
      timerValue = 0;
    }

    notifyListeners();
  }

  void adjustWindSpeed(double windSpeed) {
    Command windSpeedCmd = Command.windOff;
    switch (windSpeed.toInt()) {
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

  void adjustBrightness(double brightness) {
    Command windSpeedCmd = Command.lightOff;
    switch (brightness.toInt()) {
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

  void connect(BluetoothDevice device) async {
    BotToast.showText(text: '연결 시작');
    await FlutterBluePlus.stopScan();
    // await device.device.connect(mtu: null, autoConnect: true);

    while(true) {
      try {
        await device.connect();
        break;
      } catch(e) {
        print(e);
        BotToast.showText(text: '연결 재시도');
      }
    }

    BotToast.showText(text: '연결되었습니다.');

    //todo 연결 성공 검증, 실패 얼럿
    isConnected = true;
    isFirst = true;
    this.device = device;

    services = await device.discoverServices();

    _connectionStateSubscription?.cancel();

    _connectionStateSubscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("${device.disconnectReason}");
        BotToast.showText(text: '기기 연결이 해제되었습니다.');

        isConnected = false;
        isFanOn = false;

        notifyListeners();
      }
    });

    var targetService = services[0];

    var c = targetService.characteristics[0];
    var data = await c.read();
    var splitData = data.sublist(7, 12);

    selectedWindSpeed = splitData[0].toDouble();
    selectedBrightness = splitData[1].toDouble();
    isCharging = splitData[3] == 1;
    batteryLevel = splitData[4];
    timerValue = splitData[2] / 240.0 * 359.0;

    if (selectedBrightness > 0 || selectedWindSpeed > 0) {
      isFanOn = true;
    }

    notifyListeners();
  }
}
