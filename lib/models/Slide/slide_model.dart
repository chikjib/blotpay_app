// To parse this JSON data, do
//
//     final slideModel = slideModelFromJson(jsonString);

import 'dart:convert';

SlideModel slideModelFromJson(String str) => SlideModel.fromJson(json.decode(str));

String slideModelToJson(SlideModel data) => json.encode(data.toJson());

class SlideModel {
  int? statusCode;
  List<Datum>? data;
  String? message;

  SlideModel({
    this.statusCode,
    this.data,
    this.message,
  });

  factory SlideModel.fromJson(Map<String, dynamic> json) => SlideModel(
    statusCode: json["status_code"],
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
  };
}

class Datum {
  int? id;
  String? title;
  String? image;

  Datum({
    this.id,
    this.title,
    this.image,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    title: json["title"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
  };
}
