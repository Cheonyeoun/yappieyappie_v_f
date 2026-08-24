import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _updatePresence(true);
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updatePresence(true);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updatePresence(bool isOnline) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    }).catchError((_) {}); // Ignore errors if not logged in or offline
  }

  @override
  void dispose() {
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startHeartbeat();
    } else {
      _stopHeartbeat();
      _updatePresence(false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
