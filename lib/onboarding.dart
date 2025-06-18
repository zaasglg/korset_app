import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:korset_app/navigation.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.scale(
      backgroundColor: const Color(0xff183B4E),
      childWidget: SizedBox(
        height: 50,
        child: SvgPicture.asset(
          "./assets/images/logo-white.svg",
          height: 50.0,
        ),
      ),
      duration: const Duration(milliseconds: 2500),
      animationDuration: const Duration(milliseconds: 1000),
      onAnimationEnd: () => debugPrint("On Scale End"),
      nextScreen: const NavigationMenu(),
    );
  }
}
