import 'dart:convert';
import 'dart:developer' as developer;

import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Log {
  static int kLGCharMax = 16;
  static int kDot = 20;
  static bool logOn = kReleaseMode ? false : true;

  static void print(Object text, {String? title, String? name = kApp}) {
    if (logOn) {
      final f = DateFormat('HH:mm:SSS');

      String init;
      String end = ':';
      String comp = '.';
      String strLog;

      if (title == null) {
        init = f.format(DateTime.now()).toString();
      } else {
        init = title;
      }

      String nameText = name ?? kApp;
      int nameAdd = kLGCharMax - nameText.length - 1;

      int qtd = init.length;
      strLog = '$init${comp.padRight(kDot - qtd + nameAdd, '.')}$end $text';
      developer.log(strLog, name: nameText);
    }
  }

  static void printJson(Object object, {String? title, String? name = kApp}) {
    const jsonEnc = JsonEncoder();
    var encoded = jsonEnc.convert(object);

    if (logOn) {
      String init;
      String end = ':';
      String comp = '.';
      String strLog;

      if (title == null) {
        init = '';
      } else {
        init = title;
      }

      String nameText = name ?? kApp;
      int nameAdd = kLGCharMax - nameText.length - 1;

      int qtd = init.length;
      strLog = '$init${comp.padRight(kDot - qtd + nameAdd, '.')}$end $encoded';
      developer.log(strLog, name: nameText);
    }
  }
}
