// lib/screens/payment_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiver/async.dart';
import 'package:smart_carts/routes/routes.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({Key? key}) : super(key: key);

  @override
  _PaymentConfirmationScreenState createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with WidgetsBindingObserver {
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CountdownTimer? _countdownTimer;
  bool _isTimerCompleted = false;
  bool _isLocked = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("PaymentConfirmationScreen initialized and observer added.");
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    print("PaymentConfirmationScreen disposed and observer removed.");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("AppLifecycleState changed to: $state");
    if (state == AppLifecycleState.paused) {
      _startCountdownTimer();
      setState(() {
        _isLocked = true; 
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_isTimerCompleted) {
        print("Countdown completed. Logging out and navigating to HomeScreen.");
        _logoutAndNavigateHome();
      } else {
        print("Countdown not completed. Cancelling logout.");
        _countdownTimer?.cancel();
        _isTimerCompleted = false;
        setState(() {
          _isLocked = false; 
        });
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _isTimerCompleted = false;
    
    _countdownTimer = CountdownTimer(
      const Duration(seconds: 60), 
      const Duration(seconds: 1),
    );

    _countdownTimer!.listen(null, onDone: () {
      _isTimerCompleted = true;
      print("Countdown Timer completed.");
    });
    
    print("Countdown Timer started for 60 seconds.");
  }

  Future<void> _logoutAndNavigateHome() async {
    try {
      await _auth.signOut();
      print("User signed out successfully.");
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } catch (e) {
      print("Error during sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  void _onBackToHomePressed() {
    if (_isLocked) return;
    
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isLocked,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pago Confirmado'),
          backgroundColor: Colors.red,
          automaticallyImplyLeading: !_isLocked, 
        ),
        body: AbsorbPointer(
          absorbing: _isLocked, 
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      const Text(
                        '¡Gracias por tu compra!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onBackToHomePressed,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Volver al inicio'),
                      ),
                  ],
                ),
              ),
              if (_isLocked)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Sesión bloqueada. Cerrando sesión en breve...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
