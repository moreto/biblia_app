import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'commons.dart';

class BBSecureStorage {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> writeSecureData(SecureStorageModel newItem) async {
    try {
      await _secureStorage.write(key: newItem.key, value: newItem.value, aOptions: _getAndroidOptions());
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
    }
  }

  Future<void> writeListSecureData(List<SecureStorageModel> newItens) async {
    try {
      await Future.forEach(newItens, (element) => writeSecureData(element));
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
    }
  }

  Future<String?> readSecureData(String key) async {
    try {
      var readData = await _secureStorage.read(key: key, aOptions: _getAndroidOptions());
      return readData;
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
      return kVazio;
    }
  }

  Future<void> deleteSecureData(SecureStorageModel item) async {
    try {
      await deleteSecureDataByKey(item.key);
      // await _secureStorage.delete(key: item.key, aOptions: _getAndroidOptions());
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
    }
  }

  Future<void> deleteSecureDataByKey(String key) async {
    try {
      await _secureStorage.delete(key: key, aOptions: _getAndroidOptions());
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
    }
  }

  Future<bool> containsKeyInSecureData(String key) async {
    try {
      var containsKey = await _secureStorage.containsKey(key: key, aOptions: _getAndroidOptions());
      return containsKey;
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
      return false;
    }
  }

  Future<List<String>> readAllSecureData() async {
    List<String> list = [];
    try {
      var allData = await _secureStorage.readAll(aOptions: _getAndroidOptions());
      list = allData.entries.map((e) => e.key).toList();
      return list;
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
      return list;
    }
  }

  Future<void> deleteAllSecureData() async {
    try {
      await _secureStorage.deleteAll(aOptions: _getAndroidOptions());
    } catch (ex) {
      // BBLog.print(ex.toString(), name: 'AAI Cmn', title: kErro);
    }
  }

  // AndroidOptions _getAndroidOptions() => const AndroidOptions(encryptedSharedPreferences: true);
  AndroidOptions _getAndroidOptions() => const AndroidOptions();
}
