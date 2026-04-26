class Airtime2CashModel {
  int? status;
  List<Datum>? data;
  String? message;

  Airtime2CashModel({
    this.status,
    this.data,
    this.message,
  });

  factory Airtime2CashModel.fromJson(Map<String, dynamic> json) => Airtime2CashModel(
    status: json["status"],
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
  };
}

class Datum {
  String? title;
  int? id;
  String? image;
  dynamic networkType;
  String? description;
  Products? products;

  Datum({
    this.title,
    this.id,
    this.image,
    this.networkType,
    this.description,
    this.products,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    title: json["title"],
    id: json["id"],
    image: json["image"],
    networkType: json["network_type"],
    description: json["description"],
    products: json["products"] == null ? null : Products.fromJson(json["products"]),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "id": id,
    "image": image,
    "network_type": networkType,
    "description": description,
    "products": products?.toJson(),
  };
}

class Products {
  int? commission;

  Products({
    this.commission,
  });

  factory Products.fromJson(Map<String, dynamic> json) => Products(
    commission: json["commission"],
  );

  Map<String, dynamic> toJson() => {
    "commission": commission,
  };
}