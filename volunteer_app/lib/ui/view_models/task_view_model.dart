import 'package:flutter/foundation.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/repositories/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;

  List<TaskModel> _tasks = [];
  List<TaskModel> _myTasks = [];
  TaskModel? _selectedTask;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String _statusFilter = 'All';
  String _searchQuery = '';
  String _myTasksFilter = 'All'; // 'Upcoming', 'Accepted', 'Completed', 'Cancelled', 'All'

  List<TaskModel> get tasks => _tasks;
  List<TaskModel> get myTasks => _myTasks;
  TaskModel? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  String get myTasksFilter => _myTasksFilter;

  TaskViewModel(this._taskRepository);

  void setStatusFilter(String filter) {
    if (_statusFilter != filter) {
      _statusFilter = filter;
      loadTasks();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadTasks();
  }

  void setMyTasksFilter(String filter) {
    if (_myTasksFilter != filter) {
      _myTasksFilter = filter;
      loadMyTasks();
    }
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getTasks(
        status: _statusFilter,
        search: _searchQuery,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskDetails(int taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTask = await _taskRepository.getTaskDetails(taskId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyForTask(int taskId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.applyTask(taskId);
      // Reload both selected task and task list
      await loadTaskDetails(taskId);
      await loadTasks();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRegistration(int taskId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.cancelTaskRegistration(taskId);
      if (_selectedTask?.taskId == taskId) {
        await loadTaskDetails(taskId);
      }
      await loadTasks();
      await loadMyTasks();
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myTasks = await _taskRepository.getMyTasks(status: _myTasksFilter);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
