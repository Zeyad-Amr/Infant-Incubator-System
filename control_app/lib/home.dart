import 'dart:typed_data';

import 'package:control_app/models/readings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:control_app/widgets/strip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Home extends StatefulWidget {
  const Home({Key? key, this.server}) : super(key: key);
  final BluetoothDevice? server;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Readings? readings =
      Readings(containerLvl: 0, drainLvl: 0, temp: 0, status: 0);
  BluetoothConnection? connection;
  String prevString = '';

  String _messageBuffer = '';

  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;
  // String level = '0.0';

  List<String> dataList = [];
  // List<String> getData = [];

  String msg(int status) {
    switch (status) {
      case 0:
        return 'Process is running';
      case 1:
        return 'Temperature is less than the standard reference\n\nHeater is activated';
      case 2:
        return 'There is a blood detected';
      case 3:
        return 'Dialysate Conatiner is empty, please refill it';
      case 4:
        return 'Drain Container is full, please empty it';
      case 5:
        return 'Please, Maintain PH of the dialyste';

      default:
        return 'Smart Pre-Dialyzer';
    }
  }

  receiveData() {
    BluetoothConnection.toAddress(widget.server!.address).then((_connection) {
      debugPrint('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onData((data) {
        // Allocate buffer for parsed data
        int backspacesCounter = 0;
        for (var byte in data) {
          if (byte == 8 || byte == 127) {
            backspacesCounter++;
          }
        }
        Uint8List buffer = Uint8List(data.length - backspacesCounter);
        int bufferIndex = buffer.length;

        // Apply backspace control character
        backspacesCounter = 0;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i] == 8 || data[i] == 127) {
            backspacesCounter++;
          } else {
            if (backspacesCounter > 0) {
              backspacesCounter--;
            } else {
              buffer[--bufferIndex] = data[i];
            }
          }
        }

        // Create message if there is new line character
        String dataString = String.fromCharCodes(buffer);
        dataList.add(dataString);

        // debugPrint('data ${dataList.join().split("@").last}');
        try {
          String x = dataList.join().split("@").last;
          List<String> data = x.split('*');
          if (data.length == 4) {
            setState(() {
              readings = Readings(
                containerLvl: int.parse(data[0]),
                drainLvl: int.parse(data[1]) <= 50 ? 0 : int.parse(data[1]),
                temp: int.parse(data[2]),
                status: int.parse(data[3]),
              );
              debugPrint(readings.toString());
            });
          } else {
            debugPrint("Waiting ....");
            debugPrint(x.toString());
          }
        } catch (e) {
          // level = '00.0';
        }

        if (isDisconnecting) {
          debugPrint('Disconnecting locally!');
        } else {
          debugPrint('Disconnected remotely!');
        }
        if (mounted) {
          setState(() {});
        }
      });
      setState(() {});
    }).catchError((error) {
      debugPrint('Cannot connect, exception occured');
      debugPrint(error);
    });
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    for (var byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    receiveData();
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      debugPrint("Hello Web");
    }
    double widths = 0;
    // double heights = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      widths = MediaQuery.of(context).size.width;
      // heights = MediaQuery.of(context).size.height;
    } else if (kIsWeb ||
        MediaQuery.of(context).orientation == Orientation.landscape) {
      widths = MediaQuery.of(context).size.height;
      // heights = MediaQuery.of(context).size.width;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Infant Incubator"),
        backgroundColor: Colors.grey[900],
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 15,
          ),
          child: Image.asset('assets/akwa.png'),
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Container(
              child: Center(
                  child: Text(
                      readings!.status == 0
                          ? 'Hemodialysis Machine is Available Now'
                          : 'Warining !',
                      style: const TextStyle(color: Colors.white))),
              color:
                  readings!.status == 0 ? Colors.green[600] : Colors.amber[600],
              width: double.infinity,
              height: 25,
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                      inputBackgroundcolor: Colors.red,
                      label: "Humidty",
                      labelColor: Colors.black,
                      labelBackgroundcolor: Colors.white,
                      inputWidget: Text(
                        "50",
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Divider(),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
