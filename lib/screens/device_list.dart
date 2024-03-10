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

    refresh();
  }

  @override
  void dispose() {
    super.dispose();
    FlutterBluePlus.stopScan();
  }

  Widget buildCurrentDevice() {
    if (provider.isConnected && provider.device != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('연결 기기',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(7, 7, 7, 2),
                        child: Text(
                          provider.device.platformName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        )),
                    SizedBox(
                      width: 190,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(7, 0, 0, 0),
                          child: Text(
                            provider.device.remoteId.toString(),
                            style: TextStyle(color: Colors.grey.shade600),
                          )),
                    ),
                  ])),
          const Spacer(),
          Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                  onPressed: () async {
                    await provider.device.disconnect();
                    await refresh();
                  },
                  child: const Text('연결 해제', style: TextStyle(color: Colors.blue))))
        ],
      );
    } else {
      return const Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [Text('연결 기기 없음')],
          ));
    }
  }

  Future<void> refresh() async {
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 60),
      // continuousUpdates: true,
      // continuousDivisor: divisor
    );
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
              onPressed: () async {
                await refresh();
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCurrentDevice(),
          const Divider(color: Colors.grey, height: 10),
          const Padding(
            padding: EdgeInsets.all(8),
            child:
                Text('주변 기기 목록', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (c, snapshot) {
                var filteredDevices = snapshot.data!
                    .where((result) => result.device.platformName == targetName)
                    .toList();

                if (filteredDevices.isNotEmpty) {
                  return SizedBox(
                    height: 500,
                    child: ListView(
                      children: filteredDevices
                          .map((scanResult) => ListTile(
                              title: Text(scanResult.device.platformName),
                              subtitle:
                                  Text(scanResult.device.remoteId.toString()),
                              trailing: TextButton(
                                  onPressed: () async {
                                    if (provider.isConnected &&
                                        provider.device != null) {
                                      await provider.device.disconnect();
                                    }
                                    provider.connect(scanResult.device);
                                    await refresh();
                                  },
                                  child: const Text('연결',style: TextStyle(color: Colors.blue)))))
                          .toList(),
                    ),
                  );
                } else if (FlutterBluePlus.isScanningNow) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.black,
                  ));
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
