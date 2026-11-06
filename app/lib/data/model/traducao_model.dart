// To parse this JSON data, do
//
//     final traducaoModel = traducaoModelFromJson(jsonString);

import 'dart:convert';

List<TraducaoModel> traducaoModelFromJson(String str) =>
    List<TraducaoModel>.from(json.decode(str).map((x) => TraducaoModel.fromJson(x)));

String traducaoModelToJson(List<TraducaoModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TraducaoModel {
  final String tradChave;
  final String tradPtBr;
  final String tradEsEs;
  final String tradEnUs;

  TraducaoModel({required this.tradChave, required this.tradPtBr, required this.tradEsEs, required this.tradEnUs});

  factory TraducaoModel.fromJson(Map<String, dynamic> json) => TraducaoModel(
    tradChave: json['tradChave'],
    tradPtBr: json['tradPtBr'],
    tradEsEs: json['tradEsEs'],
    tradEnUs: json['tradEnUs'],
  );

  Map<String, dynamic> toJson() => {
    'tradChave': tradChave,
    'tradPtBr': tradPtBr,
    'tradEsEs': tradEsEs,
    'tradEnUs': tradEnUs,
  };
}
