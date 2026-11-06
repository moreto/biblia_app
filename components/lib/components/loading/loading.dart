import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<StatefulWidget> createState() => _BBLoading();
}

class _BBLoading extends State<Loading> with SingleTickerProviderStateMixin {
  String loadingPath = '';
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark, // Android: dark (black) icons
        statusBarBrightness: Brightness.light, // iOS: dark (black) icons
      ),
    );

    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Container(width: 200, alignment: Alignment.center, child: CircularProgressIndicator())],
        ),
      ),
    );
  }
}
