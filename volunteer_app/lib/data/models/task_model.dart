class TaskModel {
  final int taskId;
  final String taskName;
  final String description;
  final String? imageUrl;
  final List<String> images;
  final String location;
  final double? latitude;
  final double? longitude;
  final String taskDate;
  final String startTime;
  final String? endTime;
  final int volunteersRequired;
  final int registeredCount;
  final String status; // 'Available', 'In Progress', 'Completed', 'Cancelled'
  final int? createdBy;
  final String? creatorName;
  final String? createdDate;
  final bool isUserRegistered;
  final String? userRegistrationStatus; // 'Accepted', 'Cancelled', 'Completed'

  TaskModel({
    required this.taskId,
    required this.taskName,
    required this.description,
    this.imageUrl,
    this.images = const [],
    required this.location,
    this.latitude,
    this.longitude,
    required this.taskDate,
    required this.startTime,
    this.endTime,
    required this.volunteersRequired,
    this.registeredCount = 0,
    required this.status,
    this.createdBy,
    this.creatorName,
    this.createdDate,
    this.isUserRegistered = false,
    this.userRegistrationStatus,
  });

  bool get isFull => registeredCount >= volunteersRequired;
  int get spotsRemaining => (volunteersRequired - registeredCount).clamp(0, volunteersRequired);
  double get progressRatio => volunteersRequired > 0 
      ? (registeredCount / volunteersRequired).clamp(0.0, 1.0) 
      : 0.0;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['ImageURL'] != null && json['ImageURL'].toString().isNotEmpty) {
      parsedImages = [json['ImageURL'].toString()];
    }

    return TaskModel(
      taskId: json['taskId'] ?? json['TaskID'] ?? 0,
      taskName: json['taskName'] ?? json['TaskName'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['ImageURL'],
      images: parsedImages,
      location: json['location'] ?? json['Location'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : (json['Latitude'] != null ? (json['Latitude'] as num).toDouble() : null),
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : (json['Longitude'] != null ? (json['Longitude'] as num).toDouble() : null),
      taskDate: json['taskDate'] ?? json['TaskDate'] ?? '',
      startTime: json['startTime'] ?? json['StartTime'] ?? '',
      endTime: json['endTime'] ?? json['EndTime'],
      volunteersRequired: json['volunteersRequired'] ?? json['VolunteersRequired'] ?? 1,
      registeredCount: json['registeredCount'] ?? json['RegisteredCount'] ?? 0,
      status: json['status'] ?? json['Status'] ?? 'Available',
      createdBy: json['createdBy'] ?? json['CreatedBy'],
      creatorName: json['creatorName'] ?? json['CreatorName'],
      createdDate: json['createdDate'] ?? json['CreatedDate'],
      isUserRegistered: json['isUserRegistered'] == true || json['isUserRegistered'] == 1,
      userRegistrationStatus: json['userRegistrationStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'taskDate': taskDate,
      'startTime': startTime,
      'endTime': endTime,
      'volunteersRequired': volunteersRequired,
      'registeredCount': registeredCount,
      'status': status,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdDate': createdDate,
      'isUserRegistered': isUserRegistered,
      'userRegistrationStatus': userRegistrationStatus,
    };
  }
}
