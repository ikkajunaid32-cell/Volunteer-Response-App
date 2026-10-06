import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:volunteer_app/data/models/registration_model.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/repositories/task_repository.dart';

class AdminTaskViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;

  List<TaskModel> _tasks = [];
  List<TaskRegistrationModel> _selectedTaskVolunteers = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _adminStatusFilter = 'All';

  List<TaskModel> get tasks => _tasks;
  List<TaskRegistrationModel> get selectedTaskVolunteers => _selectedTaskVolunteers;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get adminStatusFilter => _adminStatusFilter;

  // Stats
  int get totalCount => _tasks.length;
  int get availableCount => _tasks.where((t) => t.status == 'Available').length;
  int get inProgressCount => _tasks.where((t) => t.status == 'In Progress').length;
  int get completedCount => _tasks.where((t) => t.status == 'Completed').length;
  int get cancelledCount => _tasks.where((t) => t.status == 'Cancelled').length;

  AdminTaskViewModel(this._taskRepository);

  void setFilter(String filter) {
    if (_adminStatusFilter != filter) {
      _adminStatusFilter = filter;
      loadAdminTasks();
    }
  }

  Future<void> loadAdminTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getTasks(
        status: _adminStatusFilter,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVolunteersForTask(int taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTaskVolunteers = await _taskRepository.getTaskVolunteers(taskId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadImageFile(XFile file) async {
    try {
      return await _taskRepository.uploadImage(file);
    } catch (e) {
      _errorMessage = 'Image upload failed: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      return null;
    }
  }

  Future<bool> createTask({
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
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.createTask(
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
      await loadAdminTasks();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask({
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
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.updateTask(
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
      await loadAdminTasks();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.deleteTask(taskId);
      await loadAdminTasks();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
