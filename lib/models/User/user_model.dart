class UserModel {
  UserModel({
    this.status,
    this.data,
    this.message,
  });

  final int? status;
  final Data? data;
  final String? message;

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
      message: json["message"],
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": data?.toJson(),
    "message": message,
  };

}

class Data {
  Data({
    required this.id,
    required this.profilePicture,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNo,
    required this.walletBalance,
    required this.bonus,
    required this.referredBy,
    required this.dateJoined,
    required this.userLevel,
    required this.webhookUrl,
    required this.transactionPin,
    required this.bankAccount,
    required this.virtualAccount,
    required this.lowBalanceLimit,
    required this.notifyLowBalance,
    required this.enablePushNotification,
    required this.referralEarnings,
    required this.referralCount,
  });

  final int? id;
  final dynamic profilePicture;
  final String? username;
  final String? fullName;
  final String? email;
  final String? phoneNo;
  final String? walletBalance;
  final String? bonus;
  final dynamic referredBy;
  final DateTime? dateJoined;
  final String? userLevel;
  final String? webhookUrl;
  final String? transactionPin;
  final BankAccount? bankAccount;
  final VirtualAccount? virtualAccount;
  final String? lowBalanceLimit;
  final bool? notifyLowBalance;
  final bool? enablePushNotification;
  final String? referralEarnings;
  final int? referralCount;

  factory Data.fromJson(Map<String, dynamic> json){
    return Data(
      id: json["id"],
      profilePicture: json["profile_picture"],
      username: json["username"],
      fullName: json["full_name"],
      email: json["email"],
      phoneNo: json["phone_no"],
      walletBalance: json["wallet_balance"],
      bonus: json["bonus"],
      referredBy: json["referred_by"],
      dateJoined: DateTime.tryParse(json["date_joined"] ?? ""),
      userLevel: json["user_level"],
      webhookUrl: json["webhook_url"],
      transactionPin: json["transaction_pin"],
      bankAccount: json["bank_account"] == null ? null : BankAccount.fromJson(json["bank_account"]),
      virtualAccount: json["virtual_account"] == null ? null : VirtualAccount.fromJson(json["virtual_account"]),
      lowBalanceLimit: json["low_balance_limit"],
      notifyLowBalance: json["notify_low_balance"],
      enablePushNotification: json["enable_push_notification"],
      referralEarnings: json["referral_earnings"],
      referralCount: json["referral_count"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "profile_picture": profilePicture,
    "username": username,
    "full_name": fullName,
    "email": email,
    "phone_no": phoneNo,
    "wallet_balance": walletBalance,
    "bonus": bonus,
    "referred_by": referredBy,
    "date_joined": dateJoined?.toIso8601String(),
    "user_level": userLevel,
    "webhook_url": webhookUrl,
    "transaction_pin": transactionPin,
    "bank_account": bankAccount?.toJson(),
    "virtual_account": virtualAccount?.toJson(),
    "low_balance_limit": lowBalanceLimit,
    "notify_low_balance": notifyLowBalance,
    "enable_push_notification": enablePushNotification,
    "referral_earnings": referralEarnings,
    "referral_count": referralCount,
  };

}

class BankAccount {
  BankAccount({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
  });

  final dynamic accountName;
  final dynamic accountNumber;
  final dynamic bankName;

  factory BankAccount.fromJson(Map<String, dynamic> json){
    return BankAccount(
      accountName: json["account_name"],
      accountNumber: json["account_number"],
      bankName: json["bank_name"],
    );
  }

  Map<String, dynamic> toJson() => {
    "account_name": accountName,
    "account_number": accountNumber,
    "bank_name": bankName,
  };

}

class VirtualAccount {
  VirtualAccount({
    required this.palmpayAccount,
    required this.ninepaymentAccount,
  });

  final List<Account> palmpayAccount;
  final List<Account> ninepaymentAccount;

  factory VirtualAccount.fromJson(Map<String, dynamic> json){
    return VirtualAccount(
      palmpayAccount: json["palmpay_account"] == null ? [] : List<Account>.from(json["palmpay_account"]!.map((x) => Account.fromJson(x))),
      ninepaymentAccount: json["ninepayment_account"] == null ? [] : List<Account>.from(json["ninepayment_account"]!.map((x) => Account.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "palmpay_account": palmpayAccount.map((x) => x?.toJson()).toList(),
    "ninepayment_account": ninepaymentAccount.map((x) => x?.toJson()).toList(),
  };

}

class Account {
  Account({
    required this.bankCode,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
  });

  final String? bankCode;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;

  factory Account.fromJson(Map<String, dynamic> json){
    return Account(
      bankCode: json["bankCode"],
      bankName: json["bankName"],
      accountName: json["accountName"],
      accountNumber: json["accountNumber"],
    );
  }

  Map<String, dynamic> toJson() => {
    "bankCode": bankCode,
    "bankName": bankName,
    "accountName": accountName,
    "accountNumber": accountNumber,
  };

}
