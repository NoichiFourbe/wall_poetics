import 'package:flutter/material.dart';

class accueil extends StatefulWidget {
  const accueil({Key? key}) : super(key: key);

  @override
  _accueilState createState() => _accueilState();
}

class _accueilState extends State<accueil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fullscreen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.3,
            child: Opacity(
              opacity: 0.6,
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Text(
                    'Bienvenue sur notre application de Street Art',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2487DC),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
