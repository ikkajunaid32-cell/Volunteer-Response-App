import 'package:image_picker/image_picker.dart';
import 'package:volunteer_app/core/constants/api_constants.dart';
import 'package:volunteer_app/data/models/registration_model.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/services/api_service.dart';

class TaskRepository {
  final ApiService _apiService;

  TaskRepository(this._apiService);

  Future<List<TaskModel>> getTasks({String? status, String? search}) async {
    final queryParams = <String>[];
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search.trim())}');
    }

    String url = ApiConstants.tasks;
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final res = await _apiService.get(url);
    if (res['tasks'] is List) {
      return (res['tasks'] as List).map((json) => TaskModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<TaskModel> getTaskDetails(int taskId) async {
    final res = await _apiService.get(ApiConstants.taskDetails(taskId));
    return TaskModel.fromJson(res['task']);
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
    await _apiService.post(ApiConstants.tasks, {
      'taskName': taskName,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'taskDate': taskDate,
      'startTime': startTime,
      'endTime': endTime,
      'volunteersRequired': volunteersRequired,
      'status': status,
      'additionalImages': additionalImages,
    });
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
    await _apiService.put(ApiConstants.taskDetails(taskId), {
      'taskName': ?taskName,
      'description': ?description,
      'imageUrl': ?imageUrl,
      'location': ?location,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'taskDate': ?taskDate,
      'startTime': ?startTime,
      'endTime': ?endTime,
      'volunteersRequired': ?volunteersRequired,
      'status': ?status,
      'additionalImages': ?additionalImages,
    });
  }

  Future<void> deleteTask(int taskId) async {
    await _apiService.delete(ApiConstants.taskDetails(taskId));
  }

  Future<void> applyTask(int taskId) async {
    await _apiService.post(ApiConstants.applyTask(taskId), {});
  }

  Future<void> cancelTaskRegistration(int taskId) async {
    await _apiService.post(ApiConstants.cancelTask(taskId), {});
  }

  Future<List<TaskModel>> getMyTasks({String? status}) async {
    String url = ApiConstants.myTasks;
    if (status != null && status.isNotEmpty && status != 'All') {
      url += '?status=${Uri.encodeComponent(status)}';
    }

    final res = await _apiService.get(url);
    if (res['tasks'] is List) {
      return (res['tasks'] as List).map((json) => TaskModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<TaskRegistrationModel>> getTaskVolunteers(int taskId) async {
    final res = await _apiService.get(ApiConstants.taskVolunteers(taskId));
    if (res['volunteers'] is List) {
      return (res['volunteers'] as List).map((json) => TaskRegistrationModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<String> uploadImage(XFile imageFile) async {
    return await _apiService.uploadImage(imageFile);
  }
}
