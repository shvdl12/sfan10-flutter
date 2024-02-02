import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:sfan10/provider/CommonProvider.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  static const routeName = '/device-list';

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  late CommonProvider provider;
  final targetName = 'FANMF023';
  int divisor = Platform.isAndroid ? 8 : 1;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.startScan(
        timeout: const Duration(days: 1),
        continuousUpdates: true,
        continuousDivisor: divisor);
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBluePlus.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<CommonProvider>();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text('연결 관리'),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 15),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => () async {
                FlutterBluePlus.stopScan();
                FlutterBluePlus.startScan(
                    timeout: const Duration(days: 1),
                    continuousUpdates: true,
                    continuousDivisor: divisor);
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: FlutterBluePlus.scanResults,
        initialData: const [],
        builder: (c, snapshot) {
          var filteredDevices = snapshot.data!
              .where((result) => result.device.platformName == targetName)
              .toList();

          if (filteredDevices.isNotEmpty) {
            return ListView(
              children: filteredDevices
                  .map((scanResult) => ListTile(
                        title: Text(scanResult.device.platformName),
                        subtitle: Text(scanResult.device.remoteId.toString()),
                        onTap: () async {
                          if (provider.isConnected  &&
                              provider.device != null) {
                            await provider.device.disconnect();
                          }
                          provider.connect(scanResult.device);
                        }, // 여기에 연결 로직 추가
                      ))
                  .toList(),
            );
          }

          return const Center(
              child: CircularProgressIndicator(
            color: Colors.black,
          ));
        },
      ),
    );
  }
}
