import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BaseLifecycleObserver extends StatefulWidget {
  final Widget child;

  const BaseLifecycleObserver({Key? key, required this.child}) : super(key: key);

  @override
  _BaseLifecycleObserverState createState() => _BaseLifecycleObserverState();
}

class _BaseLifecycleObserverState extends State<BaseLifecycleObserver> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _inactivityTimer;
  static const inactivityTimeout = Duration(minutes: 15); 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _logoutUser();
    } else if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, _handleInactivityTimeout);
  }

  void _handleInactivityTimeout() {
    _logoutUser();
  }

  Future<void> _logoutUser() async {
   print("Porque lo piden");
  }


  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      child: widget.child,
    );
  }
}
