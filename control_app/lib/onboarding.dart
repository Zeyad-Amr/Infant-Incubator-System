import 'package:control_app/services/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overboard/flutter_overboard.dart';

class OnBoarding extends StatelessWidget {
  OnBoarding({Key? key}) : super(key: key);
  final pages = [
    PageModel(
        color: Colors.white,
        imageAssetPath: 'assets/01.png',
        title: 'Helping Patients',
        titleColor: Colors.grey[900],
        bodyColor: Colors.grey[900],
        body:
            'We are a team of passionate people who are dedicated to helping patients get the right treatment.',
        doAnimateImage: true),
    PageModel(
        color: Colors.white,
        imageAssetPath: 'assets/02.png',
        title: 'First IOT Hemodialysis',
        titleColor: Colors.grey[900],
        bodyColor: Colors.grey[900],
        body: 'Now you can control your hemodialysis machine from your phone.',
        doAnimateImage: true),
    PageModel(
        color: Colors.white,
        imageAssetPath: 'assets/03.png',
        title: 'Dialysis Machine Control',
        titleColor: Colors.grey[900],
        bodyColor: Colors.grey[900],
        body: 'Get your dialysis machine ready and start dialysis.',
        doAnimateImage: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OverBoard(
        pages: pages,
        showBullets: true,
        buttonColor: Colors.blue,
        finishText: 'Get Started',
        skipCallback: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Services()));
        },
        finishCallback: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Services()));
        },
      ),
    );
  }
}
