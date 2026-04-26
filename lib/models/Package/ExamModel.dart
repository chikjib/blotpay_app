class ExamModel {
  int? status;
  List<Datum>? data;
  String? message;

  ExamModel({
    this.status,
    this.data,
    this.message,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) => ExamModel(
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
  List<Product>? products;

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
    products: json["products"] == null ? [] : List<Product>.from(json["products"]!.map((x) => Product.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "id": id,
    "image": image,
    "network_type": networkType,
    "description": description,
    "products": products == null ? [] : List<dynamic>.from(products!.map((x) => x.toJson())),
  };
}

class Product {
  String? code;
  dynamic airtimeNgPackageCode;
  String? title;
  String? amount;

  Product({
    this.code,
    this.airtimeNgPackageCode,
    this.title,
    this.amount,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    code: json["code"],
    airtimeNgPackageCode: json["airtime_ng_package_code"],
    title: json["title"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "airtime_ng_package_code": airtimeNgPackageCode,
    "title": title,
    "amount": amount,
  };
}
