class TransactionModel {
  int? status;
  List<TransactionModelDatum>? data;
  String? message;

  TransactionModel({
    this.status,
    this.data,
    this.message,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    status: json["status"],
    data: json["data"] == null ? [] : List<TransactionModelDatum>.from(json["data"]!.map((x) => TransactionModelDatum.fromJson(x))),
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
  };
}

class TransactionModelDatum {
  int? id;
  Category? category;
  Subcategory? subcategory;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? txRef;
  dynamic paymentRef;
  dynamic customReference;
  String? plan;
  String? phoneNo;
  String? cardNo;
  String? description;
  String? amount;
  String? token;
  String? initialBalance;
  String? newBalance;
  String? channel;
  String? response;
  String? status;
  int? user;

  TransactionModelDatum({
    this.id,
    this.category,
    this.subcategory,
    this.createdAt,
    this.updatedAt,
    this.txRef,
    this.paymentRef,
    this.customReference,
    this.plan,
    this.phoneNo,
    this.cardNo,
    this.description,
    this.amount,
    this.token,
    this.initialBalance,
    this.newBalance,
    this.channel,
    this.response,
    this.status,
    this.user,
  });

  factory TransactionModelDatum.fromJson(Map<String, dynamic> json) => TransactionModelDatum(
    id: json["id"],
    category: json["category"] == null ? null : Category.fromJson(json["category"]),
    subcategory: json["subcategory"] == null ? null : Subcategory.fromJson(json["subcategory"]),
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    txRef: json["tx_ref"],
    paymentRef: json["payment_ref"],
    customReference: json["custom_reference"],
    plan: json["plan"],
    phoneNo: json["phone_no"],
    cardNo: json["card_no"],
    description: json["description"],
    amount: json["amount"],
    token: json["token"],
    initialBalance: json["initial_balance"],
    newBalance: json["new_balance"],
    channel: json["channel"],
    response: json["response"],
    status: json["status"],
    user: json["user"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "category": category?.toJson(),
    "subcategory": subcategory?.toJson(),
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "tx_ref": txRef,
    "payment_ref": paymentRef,
    "custom_reference": customReference,
    "plan": plan,
    "phone_no": phoneNo,
    "card_no": cardNo,
    "description": description,
    "amount": amount,
    "token": token,
    "initial_balance": initialBalance,
    "new_balance": newBalance,
    "channel": channel,
    "response": response,
    "status": status,
    "user": user,
  };
}

class Category {
  int? id;
  String? title;
  String? description;
  String? type;
  String? image;

  Category({
    this.id,
    this.title,
    this.description,
    this.type,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    title: json["title"],
    description: json["description"],
    type: json["type"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "type": type,
    "image": image,
  };
}

class Subcategory {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? title;
  String? description;
  String? image;
  String? telegramChatId;
  dynamic products;
  String? networkType;
  int? position;
  bool? status;
  int? apiPlug;
  int? category;

  Subcategory({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.title,
    this.description,
    this.image,
    this.telegramChatId,
    this.products,
    this.networkType,
    this.position,
    this.status,
    this.apiPlug,
    this.category,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
    id: json["id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    title: json["title"],
    description: json["description"],
    image: json["image"],
    telegramChatId: json["telegram_chat_id"],
    products: json["products"],
    networkType: json["network_type"],
    position: json["position"],
    status: json["status"],
    apiPlug: json["api_plug"],
    category: json["category"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "title": title,
    "description": description,
    "image": image,
    "telegram_chat_id": telegramChatId,
    "products": products,
    "network_type": networkType,
    "position": position,
    "status": status,
    "api_plug": apiPlug,
    "category": category,
  };
}

class Product {
  String? planId;
  List<ProductDatum>? data;

  Product({
    this.planId,
    this.data,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    planId: json["plan_id"],
    data: json["data"] == null ? [] : List<ProductDatum>.from(json["data"]!.map((x) => ProductDatum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "plan_id": planId,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class ProductDatum {
  String? code;
  String? plan;
  String? amount1;
  String? amount2;
  String? amount3;
  String? amount4;

  ProductDatum({
    this.code,
    this.plan,
    this.amount1,
    this.amount2,
    this.amount3,
    this.amount4,
  });

  factory ProductDatum.fromJson(Map<String, dynamic> json) => ProductDatum(
    code: json["code"],
    plan: json["plan"],
    amount1: json["amount1"],
    amount2: json["amount2"],
    amount3: json["amount3"],
    amount4: json["amount4"],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "plan": plan,
    "amount1": amount1,
    "amount2": amount2,
    "amount3": amount3,
    "amount4": amount4,
  };
}

class ProductsClass {
  double? amount1;
  double? amount2;
  double? amount3;
  double? amount4;
  int? planId;
  int? networkId;

  ProductsClass({
    this.amount1,
    this.amount2,
    this.amount3,
    this.amount4,
    this.planId,
    this.networkId,
  });

  factory ProductsClass.fromJson(Map<String, dynamic> json) => ProductsClass(
    amount1: json["amount1"]?.toDouble(),
    amount2: json["amount2"]?.toDouble(),
    amount3: json["amount3"]?.toDouble(),
    amount4: json["amount4"]?.toDouble(),
    planId: json["plan_id"],
    networkId: json["network_id"],
  );

  Map<String, dynamic> toJson() => {
    "amount1": amount1,
    "amount2": amount2,
    "amount3": amount3,
    "amount4": amount4,
    "plan_id": planId,
    "network_id": networkId,
  };
}