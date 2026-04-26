class BeneficiaryModel {
  BeneficiaryModel({
    this.status,
    this.data,
    this.message,
  });

  final int? status;
  final List<BeneficiaryData>? data;
  final String? message;

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      status: json["status"],
      data: json["data"] == null
          ? []
          : List<BeneficiaryData>.from(
          json["data"]!.map((x) => BeneficiaryData.fromJson(x))),
      message: json["message"],
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data?.map((x) => x.toJson()).toList(),
    "message": message,
  };
}

class BeneficiaryData {
  BeneficiaryData({
    required this.id,
    required this.phoneNo,
    required this.networkType,
    required this.category,
    required this.name,
    required this.createdAt,
  });

  final int? id;
  final String? phoneNo;
  final String? networkType;
  final int? category;
  final String? name;
  final DateTime? createdAt;

  factory BeneficiaryData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryData(
      id: json["id"],
      phoneNo: json["phone_no"],
      networkType: json["network_type"],
      category: json["category"],
      name: json["name"],
      createdAt: DateTime.tryParse(json["created_at"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "phone_no": phoneNo,
    "network_type": networkType,
    "category": category,
    "name": name,
    "created_at": createdAt?.toIso8601String(),
  };
}