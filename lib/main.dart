import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // theme: ThemeData(
      //   // colorScheme: ColorScheme.fromSeed(seedColor: Colors.black12),
      //   useMaterial3: true,
      // ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedMinute = 0;

  bool isWindSwitchClicked = false;
  int selectedWindSpeed = 0;
  double _selectedWindSpeed = 0;
  double _selectedBrightness = 0;

  Widget getIcon() {
    return Column(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.battery_full),
          iconSize: 35,
          color: Colors.green.shade500,
        ),
        const Text('배터리')
      ],
    );
  }

  Widget buildTimerTextLabel() {
    return Text(
      '${(_selectedMinute / 6).floor()}시간 ${(_selectedMinute % 6) * 10}분',
      style: const TextStyle(color: Colors.black, fontSize: 18),
    );
  }

  Container buildWindSpeedController() {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
          color: Colors.grey.shade300,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.all(Radius.circular(40))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            child: Image.asset(
              isWindSwitchClicked
                  ? 'assets/bt_switch_wind_open.png'
                  : 'assets/bt_switch_wind.png',
              width: 35,
              height: 35,
            ),
            onTap: () {
              setState(() {
                isWindSwitchClicked = !isWindSwitchClicked;
                selectedWindSpeed = isWindSwitchClicked ? 1 : 0;
              });
            },
          ),
          for (var i = 1; i <= 4; i++) ...[
            const SizedBox(width: 20),
            GestureDetector(
              child: Image.asset(
                'assets/bt_wind_0$i${i == selectedWindSpeed ? '_open' : ''}.png',
                width: 35,
                height: 35,
              ),
              onTap: () {
                setState(() {
                  isWindSwitchClicked = true;
                  selectedWindSpeed = i;
                });
              },
            ),
          ]
        ],
      ),
    );
  }

  String sliderLabelText(sliderValue) {
    switch (sliderValue) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.grey.shade200,
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  child:
                      Image.asset('assets/ic_top1.png', height: 100, width: 70),
                ),
                Image.asset('assets/ic_top2.png', height: 100, width: 100),
                const Spacer(),
                IconButton(
                    onPressed: () {},
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
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.power_settings_new,
                                  color: Colors.grey),
                              iconSize: 35,
                            ),
                            const Text('전원')
                          ],
                        ),
                        const Spacer(),
                        getIcon()
                      ],
                    )),
                Stack(
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
                          infoProperties:
                              InfoProperties(modifier: (double value) {
                            return '';
                          }),
                        ),
                        min: 0,
                        max: 144,
                        initialValue: 0,
                        onChange: (double value) {
                          setState(() {
                            _selectedMinute = value.toInt();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: () {}, child: buildTimerTextLabel()),
                // buildWindSpeedController(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wind_power,
                          color: Colors.blue.shade800, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                              trackHeight: 20.0,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 20.0),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20.0),
                              activeTrackColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade300,
                              thumbColor: Colors.grey.shade400,
                              inactiveTickMarkColor: Colors.grey.shade400),
                          child: Slider(
                            value: _selectedWindSpeed,
                            min: 0,
                            max: 4,
                            divisions: 4,
                            label: sliderLabelText(_selectedWindSpeed),
                            onChanged: (value) {
                              setState(() {
                                _selectedWindSpeed = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb,
                          color: Colors.yellow.shade800, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                              trackHeight: 20.0,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 20.0),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20.0),
                              activeTrackColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade300,
                              thumbColor: Colors.grey.shade400,
                              inactiveTickMarkColor: Colors.grey.shade400),
                          child: Slider(
                            value: _selectedBrightness,
                            min: 0,
                            max: 3,
                            divisions: 3,
                            label: sliderLabelText(_selectedBrightness),
                            onChanged: (value) {
                              setState(() {
                                _selectedBrightness = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
