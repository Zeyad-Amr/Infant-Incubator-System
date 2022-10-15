import 'package:flutter/material.dart';
import 'package:splash_screen_view/SplashScreenView.dart';
import 'onboarding.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          SplashScreenView(
            navigateRoute: OnBoarding(),
            duration: 4000,
            imageSize: 350,
            imageSrc: "assets/logo.png",
            text: 'Smart Pre-Dialyzer',
            textType: TextType.TyperAnimatedText,
            textStyle: const TextStyle(
              fontSize: 30.0,
            ),
            backgroundColor: Colors.white,
          ),
          Positioned(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Powered by Akwa Mix'),
                Text('Team 16'),
              ],
            ),
            bottom: 50,
          )
        ],
      ),
    );
  }
}
