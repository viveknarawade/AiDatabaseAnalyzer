import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

enum TaskStatus { initial, loading, loaded, error }

class TaskProvider extends ChangeNotifier {
  final _service = TaskService();

  List<Task> _tasks = [];
  TaskStatus _status = TaskStatus.initial;
  String _errorMessage = '';

  int _nextPage = 0;
  bool _isLastPage = false;
  bool _isFetchingMore = false;

  // ─── Getters ───────────────────────────────────────────────
  List<Task> get tasks => _tasks;
  TaskStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLastPage => _isLastPage;
  bool get isFetchingMore => _isFetchingMore;
  bool get isInitialLoading => _status == TaskStatus.loading && _tasks.isEmpty;

  // ─── Initial / Refresh load ─────────────────────────────────
  Future<void> fetchTasks({bool refresh = false}) async {
    if (_status == TaskStatus.loading) return;

    if (refresh) {
      _nextPage = 0;
      _isLastPage = false;
      _tasks = [];
    }

    _status = TaskStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final paginated = await _service.fetchTasks(page: _nextPage);
      _tasks = paginated.content;
      _isLastPage = paginated.last;
      _nextPage = paginated.page + 1;
      _status = TaskStatus.loaded;
    } catch (e) {
      _status = TaskStatus.error;
      _errorMessage = _friendlyError(e);
    }

    notifyListeners();
  }

  // ─── Infinite scroll: load next page ───────────────────────
  Future<void> fetchMoreTasks() async {
    if (_isLastPage || _isFetchingMore || _status == TaskStatus.loading) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final paginated = await _service.fetchTasks(page: _nextPage);
      _tasks = [..._tasks, ...paginated.content];
      _isLastPage = paginated.last;
      _nextPage = paginated.page + 1;
    } catch (_) {
      // Silently fail on pagination error; user can scroll up and try again
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  // ─── CRUD ──────────────────────────────────────────────────
  Future<String?> createTask(Map<String, dynamic> data) async {
    try {
      final task = await _service.createTask(data);
      _tasks = [task, ..._tasks];
      notifyListeners();
      return null; // null = success
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<String?> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateTask(id, data);
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _tasks = List.from(_tasks)..[idx] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<String?> deleteTask(int id) async {
    try {
      await _service.deleteTask(id);
      _tasks = _tasks.where((t) => t.id != id).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  void reset() {
    _tasks = [];
    _status = TaskStatus.initial;
    _nextPage = 0;
    _isLastPage = false;
    _isFetchingMore = false;
    _errorMessage = '';
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection.';
    }
    if (msg.contains('TimeoutException')) return 'Request timed out.';
    return msg.replaceFirst('Exception: ', '');
  }
}
