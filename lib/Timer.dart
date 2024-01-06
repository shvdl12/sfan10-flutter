import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Fan Slider',
      home: FanSpeedControl(),
    );
  }
}

class FanSpeedControl extends StatefulWidget {
  @override
  _FanSpeedControlState createState() => _FanSpeedControlState();
}

class _FanSpeedControlState extends State<FanSpeedControl> {
  double _currentSliderValue = 0;

  String labelText() {
    switch (_currentSliderValue) {
      case 1:
        return "1단계";
      case 2:
        return "2단계";
      case 3:
        return "3단계";
      case 4:
        return "자연풍";
      default:
        return "OFF";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

          ],
        ),
      ),
    );
  }
}
