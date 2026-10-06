class TaskRegistrationModel {
  final int registrationId;
  final int? taskId;
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String registrationDate;
  final String status; // 'Accepted', 'Completed', 'Cancelled'

  TaskRegistrationModel({
    required this.registrationId,
    this.taskId,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.registrationDate,
    required this.status,
  });

  factory TaskRegistrationModel.fromJson(Map<String, dynamic> json) {
    return TaskRegistrationModel(
      registrationId: json['registrationId'] ?? json['RegistrationID'] ?? 0,
      taskId: json['taskId'] ?? json['TaskID'],
      userId: json['userId'] ?? json['UserID'] ?? 0,
      name: json['name'] ?? json['Name'] ?? 'Volunteer',
      email: json['email'] ?? json['Email'] ?? '',
      phone: json['phone'] ?? json['Phone'],
      registrationDate: json['registrationDate'] ?? json['RegistrationDate'] ?? '',
      status: json['registrationStatus'] ?? json['RegistrationStatus'] ?? json['status'] ?? json['Status'] ?? 'Accepted',
    );
  }
}
