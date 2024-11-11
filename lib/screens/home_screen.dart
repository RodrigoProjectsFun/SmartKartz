import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_carts/routes/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final isNarrow = screenWidth < 400;

    double buttonSpacing = isPortrait ? screenWidth * 0.05 : screenWidth * 0.02;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Container(
                color: Colors.red, 
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: constraints.maxHeight * 0.3, 
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 50),
                        
                        Wrap(
                          spacing: buttonSpacing, 
                          runSpacing: buttonSpacing, 
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.register);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.red, 
                                backgroundColor: Colors.white, 
                                side: const BorderSide(color: Colors.red, width: 2), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isPortrait ? screenWidth * 0.05 : screenWidth * 0.02,
                                  vertical: 15,
                                ),
                                elevation: 5, 
                              ),
                              child: const Text(
                                'REGISTRAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.login);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.red, 
                                backgroundColor: Colors.white, 
                                side: const BorderSide(color: Colors.red, width: 2), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0), 
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isPortrait ? screenWidth * 0.06 : screenWidth * 0.02,
                                  vertical: 15,
                                ),
                                elevation: 5, 
                              ),
                              child: const Text(
                                'INGRESAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
