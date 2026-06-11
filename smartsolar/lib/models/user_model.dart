class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'user'
  final String? token;
  final String? phoneNumber;
  final String? productCode; // SKU-WHL-XXXX, SKU-FSS-XXXX, SKU-MSS-XXXX
  final String? deviceId; // Unique device UID assigned to this user

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.phoneNumber,
    this.productCode,
    this.deviceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      token: token ?? json['token'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      productCode: json['product_code'] ?? json['productCode'],
      deviceId: json['device_id'] ?? json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': name,
      'email': email,
      'role': role,
      'token': token,
      'phoneNumber': phoneNumber,
      'product_code': productCode,
      'device_id': deviceId,
    };
  }

  bool get isAdmin => role == 'admin';

  // SKU helpers
  bool get isWapdaOnly => productCode?.toUpperCase().startsWith('SKU-WHL-') ?? false;
  bool get isFullSolar => productCode?.toUpperCase().startsWith('SKU-FSS-') ?? false;
  bool get isMediumSolar => productCode?.toUpperCase().startsWith('SKU-MSS-') ?? false;
}
