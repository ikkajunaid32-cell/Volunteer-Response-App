class UserModel {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'admin' or 'volunteer'
  final String? createdDate;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.createdDate,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isVolunteer => role.toLowerCase() == 'volunteer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['UserID'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['Phone'],
      role: (json['role'] ?? json['Role'] ?? 'volunteer').toString(),
      createdDate: json['createdDate'] ?? json['CreatedDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdDate': createdDate,
    };
  }
}
