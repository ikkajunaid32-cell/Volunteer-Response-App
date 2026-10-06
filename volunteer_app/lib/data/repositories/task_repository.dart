import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:volunteer_app/data/models/registration_model.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/repositories/auth_repository.dart';
import 'package:volunteer_app/data/services/app_database.dart';

class TaskRepository {
  final AppDatabase _db = AppDatabase.instance;
  final AuthRepository _authRepository = AuthRepository();

  TaskRepository();

  Future<int?> _getCurrentUserId() async {
    final user = await _authRepository.getCachedUser();
    return user?.userId;
  }

  Future<List<TaskModel>> getTasks({String? status, String? search}) async {
    return await _db.getTasks(status: status, search: search);
  }

  Future<TaskModel> getTaskDetails(int taskId) async {
    return await _db.getTaskDetails(taskId);
  }

  Future<void> createTask({
    required String taskName,
    required String description,
    String? imageUrl,
    required String location,
    double? latitude,
    double? longitude,
    required String taskDate,
    required String startTime,
    String? endTime,
    required int volunteersRequired,
    String status = 'Available',
    List<String> additionalImages = const [],
  }) async {
    final userId = await _getCurrentUserId();
    await _db.createTask(
      taskName: taskName,
      description: description,
      imageUrl: imageUrl,
      location: location,
      latitude: latitude,
      longitude: longitude,
      taskDate: taskDate,
      startTime: startTime,
      endTime: endTime,
      volunteersRequired: volunteersRequired,
      status: status,
      additionalImages: additionalImages,
      createdBy: userId,
    );
  }

  Future<void> updateTask({
    required int taskId,
    String? taskName,
    String? description,
    String? imageUrl,
    String? location,
    double? latitude,
    double? longitude,
    String? taskDate,
    String? startTime,
    String? endTime,
    int? volunteersRequired,
    String? status,
    List<String>? additionalImages,
  }) async {
    await _db.updateTask(
      taskId: taskId,
      taskName: taskName,
      description: description,
      imageUrl: imageUrl,
      location: location,
      latitude: latitude,
      longitude: longitude,
      taskDate: taskDate,
      startTime: startTime,
      endTime: endTime,
      volunteersRequired: volunteersRequired,
      status: status,
      additionalImages: additionalImages,
    );
  }

  Future<void> deleteTask(int taskId) async {
    await _db.deleteTask(taskId);
  }

  Future<void> applyTask(int taskId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User session expired. Please sign in again.');
    }
    await _db.applyTask(taskId, userId);
  }

  Future<void> cancelTaskRegistration(int taskId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User session expired. Please sign in again.');
    }
    await _db.cancelTaskRegistration(taskId, userId);
  }

  Future<List<TaskModel>> getMyTasks({String? status}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return [];
    }
    return await _db.getUserTasks(userId, status: status);
  }

  Future<List<TaskRegistrationModel>> getTaskVolunteers(int taskId) async {
    return await _db.getTaskVolunteers(taskId);
  }

  Future<String> uploadImage(XFile imageFile) async {
    return await _db.saveImageLocally(File(imageFile.path));
  }
}
