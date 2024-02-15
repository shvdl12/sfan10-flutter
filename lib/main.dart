import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:provider/provider.dart';
import 'package:sfan10/provider/CommonProvider.dart';
import 'package:sfan10/screens/device_list.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<CommonProvider>(create: (_) => CommonProvider()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: const MyHomePage(),
      routes: {
        DeviceList.routeName: (context) => const DeviceList(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CommonProvider provider;

  late StreamSubscription<List<ScanResult>> _scanResultSubscription;

  late Timer receiver;
  bool isNotInit = true;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        BotToast.showText(text: '블루투스를 켜주세요');
        provider.isConnected = false;
        provider.isFanOn = false;
        provider.notifyListeners();
      }
    });

    if (Platform.isAndroid) {
      _turnOnBluetooth();
    } else {
      flutterBlueInit();
      initReceiver();
    }
  }

  Future<void> _turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();

    flutterBlueInit();
    initReceiver();
  }

  void initReceiver() {
    receiver = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (provider.isConnected && provider.device != null) {
        var services = await provider.device.discoverServices();

        var targetService = services[0];

        var c = targetService.characteristics[0];
        var data = await c.read();
        var splitData = data.sublist(7, 12);

        provider.isCharging = splitData[3] == 1;
        provider.batteryLevel = splitData[4];

        provider.selectedWindSpeed = splitData[0].toDouble();
        provider.selectedBrightness = splitData[1].toDouble();
        isNotInit = false;

        if (provider.selectedBrightness > 0 || provider.selectedWindSpeed > 0) {
          provider.isFanOn = true;
        }

        provider.timerValue = splitData[2] / 240.0 * 359.0;
        provider.notifyListeners();

        print('${DateTime.timestamp()} $splitData');
      }
    });
  }

  void cancelAll() {
    // _adapterStateStateSubscription.cancel();
    // _connectionStateSubscription.cancel();
    // receiver.cancel();
    _scanResultSubscription.cancel();
  }

  void flutterBlueInit() async {
    onStartScan();

    print('try connection');

    _scanResultSubscription = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isNotEmpty) {
        ScanResult r = results.last; // the most recently found device
        if (r.device.platformName == "FANMF023") {
          if (provider.isConnected && provider.device != null) {
            await provider.device.disconnect();
          }
          provider.connect(r.device);

        }
      } else {
        print('================== empty');
      }
    }, onError: (e) => print(e));

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;
  }

  Future onStartScan() async {
    int divisor = Platform.isAndroid ? 8 : 1;
    await FlutterBluePlus.startScan(
        timeout: const Duration(days: 1),
        // continuousUpdates: true,
        // continuousDivisor: divisor
    );
  }

  Widget batteryIcon() {

    var btIcon = Ph.battery_warning;
    Color color = Colors.green.shade500;

    if (provider.batteryLevel == 1) {
      btIcon = Ph.battery_low_bold;
      color = Colors.red.shade500;
    } else if (provider.batteryLevel == 2) {
      btIcon = Ph.battery_medium_bold;
      color = Colors.orange.shade500;
    } else if (provider.batteryLevel == 3) {
      btIcon = Ph.battery_high_bold;
    } else if (provider.batteryLevel == 4) {
      btIcon = Ph.battery_full_bold;
    }

    return Column(
      children: [
        IconButton(
            onPressed: () {}, icon: Iconify(btIcon, color: color, size: 30)),
        Row(
          children: [
            const Text('배터리'),
            if (provider.isCharging) const Icon(Icons.electric_bolt, size: 15)
          ],
        )
      ],
    );
  }

  /*
  * 0 -> 0  -> 0
  * 1 -> 6  -> 5
  * 2 -> 12 -> 10
  * 3 -> 18 -> 20
  * 4 -> 24 -> 25
  * 5 -> 30 -> 30
  * 6 -> 36 -> 35
  * 7 -> 42 -> 40
  * 8 -> 48 -> 50
  * 9 -> 54 -> 55
  */

  num getMinute(String value) {
    switch(int.parse(value)) {
      case 1:
        return 5;
      case 2:
        return 10;
      case 3:
        return 20;
      case 4:
        return 25;
      case 5:
        return 30;
      case 6:
        return 35;
      case 7:
        return 40;
      case 8:
        return 50;
      case 9:
        return 55;
      default:
        return 0;
    }
  }

  Widget buildTimerTextLabel() {
    if (provider.timerValue >= 1) {
      var translatedTime =
          ((provider.timerValue / 359.0 * 240.0) / 10).toStringAsFixed(1);
      var splitTranslatedTime = translatedTime.split(".");

      return Text(
        '${splitTranslatedTime[0]}시간 ${getMinute(splitTranslatedTime[1])}분',
        style: TextStyle(color: Colors.green.shade300, fontSize: 18),
      );
    } else {
      return const Text('TIMER OFF');
    }
  }

  String sliderLabelText(double sliderValue) {
    switch (sliderValue.toInt()) {
      case 1:
        return "1단계";
      case 2:
        return "2단계";
      case 3:
        return "3단계";
      case 4:
        return "자연풍";
      default:
        return "꺼짐";
    }
  }

  Widget powerIcon() {
    MaterialColor color = provider.isConnected
        ? (provider.isFanOn ? Colors.green : Colors.red)
        : Colors.grey;

    return IconButton(
      onPressed: () => provider.clickPowerButton(),
      icon: Icon(Icons.power_settings_new, color: color),
      iconSize: 35,
    );
  }

  Padding windSpeedSlider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 50, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wind_power, color: Colors.blue.shade800, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  trackHeight: 20.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 20.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20.0),
                  activeTrackColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.grey.shade400,
                  inactiveTickMarkColor: Colors.grey.shade400),
              child: Slider(
                value: provider.selectedWindSpeed,
                min: 0,
                max: 4,
                divisions: 4,
                label: sliderLabelText(provider.selectedWindSpeed),
                onChanged: (value) {
                  if (value != provider.selectedWindSpeed) {
                    provider.selectedWindSpeed = value;
                    provider.adjustWindSpeed(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget brightnessSlider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb, color: Colors.yellow.shade800, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  trackHeight: 20.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 20.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20.0),
                  activeTrackColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.grey.shade400,
                  inactiveTickMarkColor: Colors.grey.shade400),
              child: Slider(
                value: provider.selectedBrightness,
                min: 0,
                max: 3,
                divisions: 3,
                label: sliderLabelText(provider.selectedBrightness),
                onChanged: (value) {
                  if (value != provider.selectedBrightness) {
                    provider.selectedBrightness = value;
                    provider.adjustBrightness(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isAbsorbing() {
    return !(provider.isConnected && provider.isFanOn);
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<CommonProvider>();

    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.grey.shade200,
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child: Image.asset('assets/nowwin_logo.png',
                      height: 100, width: 100),
                ),
                Image.asset('assets/ic_top2.png', height: 100, width: 100),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      cancelAll();
                      Navigator.pushNamed(context, DeviceList.routeName);
                    },
                    icon: Icon(
                      Icons.bluetooth,
                      color: Colors.blue.shade900,
                      size: 30,
                    ))
              ],
            )),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(40, 10, 40, 40),
                    child: Row(
                      children: [
                        Column(
                          children: [powerIcon(), const Text('전원')],
                        ),
                        const Spacer(),
                        batteryIcon()
                      ],
                    )),
                AbsorbPointer(
                    absorbing: isAbsorbing(), child: circularSlider()),
                const SizedBox(height: 30),
                AbsorbPointer(absorbing: isAbsorbing(), child: timerLabel()),
                AbsorbPointer(
                    absorbing: isAbsorbing(), child: windSpeedSlider()),
                const SizedBox(height: 60),
                AbsorbPointer(
                    absorbing: isAbsorbing(), child: brightnessSlider())
              ],
            ),
          ),
        ));
  }

  Stack circularSlider() {
    return Stack(
      children: [
        Center(
          child: Image.asset(
            'assets/set_alarm_clock_bg.png',
            height: 250,
            width: 200,
          ),
        ),
        Center(
          child: SleekCircularSlider(
            appearance: CircularSliderAppearance(
              startAngle: 270,
              angleRange: 360,
              size: 250,
              customColors: CustomSliderColors(
                  progressBarColor: Colors.grey.shade200,
                  trackColor: Colors.white,
                  dotColor: Colors.grey.shade200,
                  shadowColor: Colors.white),
              customWidths: CustomSliderWidths(
                progressBarWidth: 20,
                trackWidth: 35,
                handlerSize: 15,
              ),
              infoProperties: InfoProperties(modifier: (double value) {
                return '';
              }),
            ),
            min: 0,
            max: 359,
            initialValue: provider.timerValue,
            onChangeEnd: (double value) {
              setState(() {
                provider.timerValue = value;
                provider.setTimer(value);
              });
            },
          ),
        ),
      ],
    );
  }

  TextButton timerLabel() {
    return TextButton(
        onPressed: () {
          if (provider.timerValue >= 1) {
            setState(() {
              provider.timerValue = 0;
            });
            provider.setTimer(0);
          }
        },
        child: buildTimerTextLabel());
  }
}
