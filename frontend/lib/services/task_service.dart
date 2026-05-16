import 'dart:developer';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/task_model.dart';

class TaskService {
  Future<PaginatedTasks> fetchTasks({int page = 0, int size = 10}) async {
    final response = await ApiClient.get(
      ApiConstants.tasksPaged,
      queryParams: {'page': '$page', 'size': '$size'},
    );

    final body = ApiClient.decodeResponse(response);

    if (response.statusCode == 200 && body['success'] == true) {
      log("Tasks fetched successfully: ${body['message']}");
      return PaginatedTasks.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw ApiException(body['message'] as String? ?? 'Failed to fetch tasks');
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await ApiClient.post(ApiConstants.tasks, data);
    final body = ApiClient.decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      log("Task created successfully: ${body['message']}");
      return Task.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw ApiException(body['message'] as String? ?? 'Failed to create task');
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.put(ApiConstants.taskById(id), data);

    final body = ApiClient.decodeResponse(response);

    if (response.statusCode == 200) {
      log(
        "Task updated successfully: "
        "${body['message']}",
      );

      // Backend returns data:null
      // Build updated task locally

      return Task(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        status: data['status'] ?? 'TODO',
        priority: data['priority'] ?? 'MEDIUM',
        dueDate: data['dueDate'] ?? '',
        createdAt: '',
      );
    }

    throw ApiException(body['message'] ?? 'Update failed');
  }

  Future<void> deleteTask(int id) async {
    final response = await ApiClient.delete(ApiConstants.taskById(id));
    log("Task deleted successfully: ${response.body}");
    if (response.statusCode != 200) {
      final body = ApiClient.decodeResponse(response);
      throw ApiException(body['message'] as String? ?? 'Failed to delete task');
    }
  }
}
