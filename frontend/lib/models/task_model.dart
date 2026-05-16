import 'dart:developer';

class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String createdAt;
  final String dueDate;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    log("TASK JSON => $json");

    return Task(
      // FIXED
      id: json['taskId'] ?? 0,

      title: json['title'] ?? '',

      description: json['description'] ?? '',

      status: json['status'] ?? 'TODO',

      priority: json['priority'] ?? 'MEDIUM',

      createdAt: json['createdAt'] ?? '',

      dueDate: json['dueDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': status,
    'priority': priority,
    'dueDate': dueDate,
  };

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? createdAt,
    String? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class PaginatedTasks {
  final List<Task> content;

  final int page;

  final int size;

  final int totalElements;

  final int totalPages;

  final bool last;

  const PaginatedTasks({
    required this.content,

    required this.page,

    required this.size,

    required this.totalElements,

    required this.totalPages,

    required this.last,
  });

  factory PaginatedTasks.fromJson(Map<String, dynamic> json) {
    return PaginatedTasks(
      content: (json['content'] as List).map((e) => Task.fromJson(e)).toList(),

      page: json['page'] ?? 0,

      size: json['size'] ?? 10,

      totalElements: json['totalElements'] ?? 0,

      totalPages: json['totalPages'] ?? 1,

      last: json['last'] ?? true,
    );
  }
}
