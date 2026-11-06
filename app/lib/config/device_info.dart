// import 'dart:io';

// import 'package:android_id/android_id.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/foundation.dart';

// class DeviceInfo {
//   DeviceInfo._();

//   static final DeviceInfo instance = DeviceInfo._();

//   final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
//   final AndroidId _androidId = const AndroidId();

//   Future<void>? _initialization;
//   String? _deviceId;
//   String? _name;
//   String? _operatingSystem;

//   String get deviceId => _deviceId ?? _notInitialized('deviceId');
//   String get name => _name ?? _notInitialized('name');
//   String get operatingSystem => _operatingSystem ?? _notInitialized('operatingSystem');

//   Future<void> initialize() {
//     return _initialization ??= _loadDeviceInfo();
//   }

//   Future<void> _loadDeviceInfo() async {
//     try {
//       if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
//         throw UnsupportedError('Device information is supported only on Android and iOS.');
//       }

//       if (Platform.isAndroid) {
//         final info = await _deviceInfoPlugin.androidInfo;
//         final id = await _androidId.getId();
//         if (id == null || id.isEmpty) {
//           throw StateError('Could not retrieve the Android device ID.');
//         }

//         _deviceId = id;
//         _name = info.name;
//         _operatingSystem = 'Android ${info.version.release}';
//       } else {
//         final info = await _deviceInfoPlugin.iosInfo;
//         final id = info.identifierForVendor;
//         if (id == null || id.isEmpty) {
//           throw StateError('Could not retrieve the iOS device ID.');
//         }

//         _deviceId = id;
//         _name = info.name;
//         _operatingSystem = '${info.systemName} ${info.systemVersion}';
//       }
//     } catch (_) {
//       _initialization = null;
//       rethrow;
//     }
//   }

//   Never _notInitialized(String property) {
//     throw StateError('DeviceInfo.initialize() must complete before reading $property.');
//   }
// }
