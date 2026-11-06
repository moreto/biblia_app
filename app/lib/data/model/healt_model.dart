// To parse this JSON data, do
//
//     final healtModel = healtModelFromJson(jsonString);

import 'dart:convert';

HealtModel healtModelFromJson(String str) => HealtModel.fromJson(json.decode(str));

String healtModelToJson(HealtModel data) => json.encode(data.toJson());

class HealtModel {
  final String name;
  final String description;
  final String version;
  final String host;
  final String email;
  final String? dataBaseStatus;

  HealtModel({
    required this.name,
    required this.description,
    required this.version,
    required this.host,
    required this.email,
    this.dataBaseStatus,
  });

  factory HealtModel.fromJson(Map<String, dynamic> json) => HealtModel(
    name: json['name'],
    description: json['description'],
    version: json['version'],
    host: json['host'],
    email: json['email'],
    dataBaseStatus: json['dataBaseStatus'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'version': version,
    'host': host,
    'email': email,
    'dataBaseStatus': dataBaseStatus,
  };
}
