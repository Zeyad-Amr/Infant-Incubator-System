import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:control_app/models/readings.dart';
import 'package:dotted_border/dotted_border.dart';
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
        return 'Incubator is on';
      case 1:
        return 'Adusting Humidty ...';
      case 2:
        return 'Adusting Temperature ...';
      case 3:
        return 'Incubator is ready ...';
      case 4:
        return 'Incubator needs for adjusting!';
      case 5:
        return 'Warning, Temperature is High!';
      case 6:
        return 'Warning, Humidty is High!';

      default:
        return 'Incubator is Off';
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

  Color? getCornerColor(int index) {
    List<double> temps = [];
    temps.addAll(cornersTemp);
    temps.sort();
    if (cornersTemp[index] == temps[0]) {
      return Colors.red[100];
    }
    if (cornersTemp[index] == temps[1]) {
      if (temps[0] == temps[1]) {
        return Colors.red[100];
      } else {
        return Colors.red[200];
      }
    }
    if (cornersTemp[index] == temps[2]) {
      if (temps[0] == temps[2] && temps[1] == temps[2]) {
        return Colors.red[100];
      } else if (temps[1] == temps[2]) {
        return Colors.red[200];
      } else {
        return Colors.red[300];
      }
    }
    if (cornersTemp[index] == temps[3]) {
      if (temps[0] == temps[3] &&
          temps[1] == temps[3] &&
          temps[2] == temps[3]) {
        return Colors.red[100];
      } else if (temps[1] == temps[3] && temps[2] == temps[3]) {
        return Colors.red[200];
      } else if (temps[2] == temps[3]) {
        return Colors.red[300];
      } else {
        return Colors.red[400];
      }
    }
    return Colors.red;
  }

  bool modeSwitchValue = false;
  List<bool> selectedMode = [true, false];
  List<double> cornersTemp = [22.3, 22.3, 25.7, 21.5];
  bool isAdjusting = false;
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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: isAdjusting
                  ? Icon(Icons.stop, color: Colors.red)
                  : Icon(Icons.adjust, color: Colors.green),
              onPressed: () {
                setState(() {
                  isAdjusting = !isAdjusting;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                AwesomeDialog(
                  context: context,
                  animType: AnimType.topSlide,
                  headerAnimationLoop: false,
                  dialogType: DialogType.question,
                  showCloseIcon: true,
                  btnOkOnPress: () {
                    // Navigator.of(context).pop();
                  },
                  btnOkText: 'Save',
                  btnOkColor: Colors.grey[900],
                  onDismissCallback: (type) {
                    debugPrint('Dialog Dissmiss from callback $type');
                  },
                  body: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Enter suitable references',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: TextFormField(
                          onChanged: (val) {
                            setState(() {});
                          },
                          validator: (value) {
                            if (int.parse(value!) >= 50) {}
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.black,
                              decorationColor: Colors.black),
                          decoration: const InputDecoration(
                              labelStyle: TextStyle(
                                  color: Colors.black,
                                  decorationColor: Colors.black),
                              hintStyle: TextStyle(
                                  color: Colors.black,
                                  decorationColor: Colors.black),
                              labelText: 'Temperature Reference',
                              hintText: 'Temperature Reference',
                              prefixIcon: Icon(Icons.thermostat_outlined,
                                  color: Colors.red),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              ),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        child: TextFormField(
                          onChanged: (val) {
                            setState(() {});
                          },
                          validator: (value) {
                            if (int.parse(value!) >= 50) {}
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.black,
                              decorationColor: Colors.black),
                          decoration: const InputDecoration(
                              labelStyle: TextStyle(
                                  color: Colors.black,
                                  decorationColor: Colors.black),
                              hintStyle: TextStyle(
                                  color: Colors.black,
                                  decorationColor: Colors.black),
                              labelText: 'Humidty Reference',
                              hintText: 'Humidty Reference',
                              prefixIcon: Icon(Icons.thermostat_outlined,
                                  color: Colors.red),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              ),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey, width: 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                              )),
                        ),
                      ),
                    ],
                  ),
                ).show();
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Container(
              child: Center(
                  child: Text(isAdjusting ? msg(1) : msg(4),
                      style: const TextStyle(color: Colors.white))),
              color: isAdjusting ? Colors.blue[700] : Colors.orange,
              width: double.infinity,
              height: 25,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                      left: 20,
                      right: 20,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Temperature Mode",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ToggleButtons(
                    children: <Widget>[
                      Container(
                        width: widths * 0.3,
                        height: widths * 0.15,
                        child: Center(
                          child: Text(
                            "Baby",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: widths * 0.3,
                        height: widths * 0.15,
                        child: Center(
                          child: Text(
                            "Air",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                    isSelected: selectedMode,
                    onPressed: (int index) {
                      if (!isAdjusting) {
                        setState(() {
                          selectedMode[0] = index == 0;
                          selectedMode[1] = index == 1;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    fillColor:
                        isAdjusting ? Colors.grey[700] : Colors.grey[900],
                    selectedColor: Colors.white,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                      inputBackgroundcolor: Colors.blue[700],
                      label: "Humidty",
                      labelColor: Colors.black,
                      labelBackgroundcolor: Colors.white,
                      inputWidget: Text(
                        "50%",
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Strip(
                      inputBackgroundcolor: Colors.red,
                      label: "Temperature",
                      labelColor: Colors.black,
                      labelBackgroundcolor: Colors.white,
                      inputWidget: Text(
                        ((cornersTemp[0] +
                                        cornersTemp[1] +
                                        cornersTemp[2] +
                                        cornersTemp[3]) /
                                    4)
                                .toStringAsFixed(1) +
                            "℃",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  selectedMode[0]
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: DottedBorder(
                              color: Colors.black,
                              strokeWidth: 1,
                              dashPattern: [10, 10],
                              borderType: BorderType.RRect,
                              radius: Radius.circular(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: widths * 0.3,
                                          decoration: BoxDecoration(
                                            color: getCornerColor(0),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cornersTemp[0].toString() + '℃',
                                              style: TextStyle(
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: widths * 0.3,
                                          decoration: BoxDecoration(
                                            color: getCornerColor(1),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cornersTemp[1].toString() + '℃',
                                              style: TextStyle(
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: widths * 0.3,
                                          decoration: BoxDecoration(
                                            color: getCornerColor(2),
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cornersTemp[2].toString() + '℃',
                                              style: TextStyle(
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: widths * 0.3,
                                          decoration: BoxDecoration(
                                            color: getCornerColor(3),
                                            borderRadius: BorderRadius.only(
                                              bottomRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cornersTemp[3].toString() + '℃',
                                              style: TextStyle(
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
