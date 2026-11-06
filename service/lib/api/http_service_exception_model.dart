// To parse this JSON data, do
//
//     final httpServiceExceptionModel = httpServiceExceptionModelFromJson(jsonString);

import 'dart:convert';

HttpServiceExceptionModel httpServiceExceptionModelFromJson(String str) =>
    HttpServiceExceptionModel.fromJson(json.decode(str));

String httpServiceExceptionModelToJson(HttpServiceExceptionModel data) => json.encode(data.toJson());

class HttpServiceExceptionModel {
  final int? status;
  final String? debugMessage;
  final String? message;
  final Data? data;

  HttpServiceExceptionModel({this.status, this.debugMessage, this.message, this.data});

  factory HttpServiceExceptionModel.fromJson(Map<String, dynamic> json) => HttpServiceExceptionModel(
    status: json['status'],
    debugMessage: json['debugMessage'],
    message: json['message'],
    data: json['data'] == null ? null : Data.fromJson(json['data']),
  );

  Map<String, dynamic> toJson() => {
    'status': status,
    'debugMessage': debugMessage,
    'message': message,
    'data': data?.toJson(),
  };
}

class Data {
  Data();

  factory Data.fromJson(Map<String, dynamic> json) => Data();

  Map<String, dynamic> toJson() => {};
}
