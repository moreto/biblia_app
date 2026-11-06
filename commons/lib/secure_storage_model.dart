class SecureStorageModel {
  SecureStorageModel(this.key, this.value);

  String key;
  dynamic value;

  @override
  String toString() => 'StorageItem(key: $key, value: $value)';
}
