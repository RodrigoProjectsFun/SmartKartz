// screens/payment_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiver/async.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:smart_carts/base_lifecycle_observer.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({Key? key}) : super(key: key);

  @override
  _PaymentConfirmationScreenState createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CountdownTimer? _countdownTimer;
  bool _isTimerCompleted = false;

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
    } else if (state == AppLifecycleState.resumed) {
      if (_isTimerCompleted) {
        print("Countdown completed. Logging out and navigating to HomeScreen.");
        _logoutAndNavigateHome();
      } else {
        print("Countdown not completed. Cancelling logout.");
        _countdownTimer?.cancel();
        _isTimerCompleted = false;
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
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (route) => false);
    } catch (e) {
      print("Error during sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLifecycleObserver(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pago Confirmado'),
          backgroundColor: Colors.red,
          automaticallyImplyLeading: false, 
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡Gracias por tu compra!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logoutAndNavigateHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, 
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Cerrar sesión y volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
