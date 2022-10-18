import 'dart:convert';
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
  Readings? readings = Readings();
  double humRefe = 50;
  double tempRefe = 37;
  bool isOn = false;
  BluetoothConnection? connection;
  String prevString = '';
  String _messageBuffer = '';
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;
  bool isDisconnecting = false;
  List<String> dataList = [];
  Color msgColor = Colors.blue;
  String msg() {
    if (!isAdjusting && !isOn) {
      setState(() {
        msgColor = Colors.grey;
      });
      return 'Incubator is Off';
    } else if (readings!.mode == 2 && isOn && isAdjusting) {
      setState(() {
        msgColor = Colors.blue;
      });
      return 'Adusting Temperature in baby mode ...';
    } else if (readings!.mode == 3 && isOn && isAdjusting) {
      setState(() {
        msgColor = Colors.blue;
      });
      return 'Adusting Temperature in air mode ...';
    } else {
      if (selectedMode[0]) {
        /// baby mode
        if (readings!.tempBaby! < tempRefe!) {
          setState(() {
            msgColor = Colors.orange;
          });
          return 'Incubator needs for adjusting!';
        } else {
          setState(() {
            msgColor = Colors.green;
          });
          return 'Incubator is ready Now';
        }
      } else {
        if (((readings!.tempTR! +
                    readings!.tempTL! +
                    readings!.tempBL! +
                    readings!.tempBR!) /
                4) <
            tempRefe!) {
          setState(() {
            msgColor = Colors.orange;
          });
          return 'Incubator needs for adjusting!';
        } else {
          setState(() {
            msgColor = Colors.green;
          });
          return 'Incubator is ready Now';
        }
      }
    }
  }

  sendMessage(String text, connection) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;
      } catch (e) {
        setState(() {});
      }
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

        // dataList.isNotEmpty
        //     ? debugPrint('data ${dataList.join().split("#").last}')
        //     : debugPrint('');
        debugPrint(dataList.toString());
        try {
          String x = dataList.join().split("#").last;
          List<String> data = x.split(',');
          // debugPrint('data Length ${data.length}');
          if (data.length == 6) {
            setState(() {
              readings = Readings(
                tempTR: double.parse(data[0]),
                tempTL: double.parse(data[1]),
                tempBR: double.parse(data[2]),
                tempBL: double.parse(data[3]),
                tempBaby: double.parse(data[4]),
                humidity: double.parse(data[5]),
              );
              debugPrint(readings.toString());
            });
          } else {
            // debugPrint("Waiting ....");
            // debugPrint(x.toString());
          }
        } catch (e) {
          debugPrint('error ${e}');
        }

        // if (isDisconnecting) {
        //   debugPrint('Disconnecting locally!');
        // } else {
        //   debugPrint('Disconnected remotely!');
        // }
        if (mounted) {
          setState(() {});
        }
      });
      setState(() {});
    }).catchError((error) {
      debugPrint('Cannot connect, exception occured');
      // debugPrint(error);
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

  Color? getCornerColor(double tempVal) {
    List<double> temps = [];
    temps.addAll([
      readings!.tempTR!,
      readings!.tempTL!,
      readings!.tempBR!,
      readings!.tempBL!
    ]);
    temps.sort();
    if (tempVal == temps[0]) {
      return Colors.red[100];
    }
    if (tempVal == temps[1]) {
      if (temps[0] == temps[1]) {
        return Colors.red[100];
      } else {
        return Colors.red[200];
      }
    }
    if (tempVal == temps[2]) {
      if (temps[0] == temps[2] && temps[1] == temps[2]) {
        return Colors.red[100];
      } else if (temps[1] == temps[2]) {
        return Colors.red[200];
      } else {
        return Colors.red[300];
      }
    }
    if (tempVal == temps[3]) {
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

  /// Start UI Variables ///
  // bool modeSwitchValue = false;
  List<bool> selectedMode = [false, true];
  bool isAdjusting = false;

  /// End UI Variables ///

  /// Start Dialog Variables ///

  final formGlobalKey = GlobalKey<FormState>();

  /// End Dialog Variables ///
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
                  isOn = true;
                  isAdjusting = !isAdjusting;
                  if (!isAdjusting) {
                    readings!.mode = 1;
                  } else {
                    readings!.mode = selectedMode[0] ? 2 : 3;
                  }
                });
                sendMessage(
                    '${readings!.mode}${(tempRefe! * 10).toInt()}${(humRefe! * 10).toInt()}',
                    connection);
              },
            ),
          ),
          Form(
            key: formGlobalKey,
            child: Padding(
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
                      if (formGlobalKey.currentState!.validate()) {
                        // sendMessage(
                        //     '${readings!.mode!}${(tempRefe! * 10).toInt()}${(humRefe! * 10).toInt()}',
                        //     connection);
                      }
                    },
                    buttonsBorderRadius: BorderRadius.circular(15),
                    buttonsTextStyle: TextStyle(fontSize: 18),
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
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          child: TextFormField(
                            initialValue: tempRefe.toString(),
                            onChanged: (val) {
                              setState(() {
                                if (val != '') {
                                  tempRefe = double.parse(
                                      double.parse(val).toStringAsFixed(1));
                                } else {
                                  tempRefe = 0.0;
                                }
                              });
                              debugPrint(tempRefe.toString());
                            },
                            validator: (value) {
                              if (double.parse(double.parse(
                                              value == '' ? '0' : value!)
                                          .toStringAsFixed(1)) <
                                      34 ||
                                  double.parse(double.parse(
                                              value == '' ? '0' : value!)
                                          .toStringAsFixed(1)) >
                                      38) {
                                return "Temperature isn't valid - (Range 34℃ - 38℃)";
                              } else {
                                return null;
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
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
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          child: TextFormField(
                            initialValue: humRefe.toString(),
                            onChanged: (val) {
                              setState(() {
                                if (val != '') {
                                  humRefe = double.parse(val);
                                } else {
                                  humRefe = 0;
                                }
                              });
                              debugPrint(humRefe.toString());
                            },
                            validator: (value) {
                              if (double.parse(value == '' ? '0' : value!) >
                                      80 ||
                                  double.parse(value == '' ? '0' : value!) <
                                      40) {
                                return "Humidty isn't valid - (Range 40% - 80%)";
                              } else {
                                return null;
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
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
                                prefixIcon:
                                    Icon(Icons.water_drop, color: Colors.blue),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0),
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
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView(
          children: [
            Container(
              child: Center(
                  child:
                      Text(msg(), style: const TextStyle(color: Colors.white))),
              color: msgColor,
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
                          readings!.mode = index == 1
                              ? 3
                              : index == 0
                                  ? 2
                                  : 1;
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
                        readings!.humidity.toString(),
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
                        (readings!.mode == 3
                                ? ((readings!.tempTR! +
                                            readings!.tempTL! +
                                            readings!.tempBR! +
                                            readings!.tempBL!) /
                                        4)
                                    .toStringAsFixed(1)
                                : readings!.tempBaby.toString()) +
                            "℃",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  selectedMode[0]
                      ? Container(
                          height: widths * 0.6,
                          child: Center(
                            child: Image(
                              width: widths * 0.4,
                              image: AssetImage(
                                'assets/baby.png',
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: DottedBorder(
                              color: Colors.black,
                              strokeWidth: 1,
                              dashPattern: [10, 10],
                              borderType: BorderType.RRect,
                              radius: Radius.circular(20),
                              child: Stack(
                                children: [
                                  Positioned(
                                    child: Container(
                                      height: widths * 0.6,
                                      child: Center(
                                        child: Image(
                                          width: widths * 0.4,
                                          image: AssetImage(
                                            'assets/baby.png',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: widths * 0.3,
                                              decoration: BoxDecoration(
                                                color: getCornerColor(
                                                        readings!.tempTL!)!
                                                    .withOpacity(0.85),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  readings!.tempTL.toString() +
                                                      '℃',
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
                                                color: getCornerColor(
                                                        readings!.tempTR!)!
                                                    .withOpacity(0.85),
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(20),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  readings!.tempTR.toString() +
                                                      '℃',
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
                                                color: getCornerColor(
                                                        readings!.tempBL!)!
                                                    .withOpacity(0.85),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(20),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  readings!.tempBL.toString() +
                                                      '℃',
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
                                                color: getCornerColor(
                                                        readings!.tempBR!)!
                                                    .withOpacity(0.85),
                                                borderRadius: BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(20),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  readings!.tempBR.toString() +
                                                      '℃',
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
                                  ),
                                ],
                              )),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
