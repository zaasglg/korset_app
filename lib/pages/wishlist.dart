import 'package:flutter/material.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "Избронное",
          style: TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          "Здесь пока ничего нет",
          style: TextStyle(
            fontFamily: "avenir",
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 162, 164, 169),
          ),
        ),
      ),
    );
  }
}
