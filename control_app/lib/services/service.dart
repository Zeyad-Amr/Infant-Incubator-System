import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bluetooth_status.dart';
import 'connection_route.dart';

class Services extends StatelessWidget {
  const Services({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FlutterBluetoothSerial.instance.requestEnable(),
      builder: (context, future) {
        if (future.connectionState == ConnectionState.waiting) {
          return BluetoothStatus();
        } else {
          return ConnectionRoute();
        }
      },
    );
  }
}
