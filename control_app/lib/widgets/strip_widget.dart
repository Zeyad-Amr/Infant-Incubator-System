import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Strip extends StatelessWidget {
  const Strip({
    Key? key,
    required this.labelBackgroundcolor,
    required this.inputBackgroundcolor,
    required this.label,
    required this.inputWidget,
    required this.labelColor,
  }) : super(key: key);
  final Color? labelBackgroundcolor;
  final Color? inputBackgroundcolor;
  final Color? labelColor;
  final String label;
  final Widget inputWidget;

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
    return SizedBox(
      height: widths * 0.2,
      width: widths * 0.82,
      child: Stack(
        children: [
          Positioned(
            left: widths * 0.02,
            top: widths * 0.01,
            child: Container(
              decoration: BoxDecoration(
                color: labelBackgroundcolor,
                borderRadius: BorderRadius.circular(30),
              ),
              width: widths * 0.8,
              height: widths * 0.16,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 23, color: labelColor),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              width: widths * 0.18,
              height: widths * 0.18,
              decoration: BoxDecoration(
                color: inputBackgroundcolor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(child: inputWidget),
            ),
          ),
        ],
      ),
    );
  }
}
