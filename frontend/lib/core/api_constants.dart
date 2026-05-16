class ApiConstants {

  static const String baseUrl =
      'http://10.20.224.128:8081';

  static const String login =
      '/api/v1/auth/login';

  static const String signup =
      '/api/v1/auth/signup';

  static const String logout =
      '/api/v1/auth/logout';

  static const String deleteAccount =
      '/api/v1/auth/delete-account';

  static const String tasks =
      '/api/v1/task/create';

  static const String tasksPaged =
      '/api/v1/task/page';

  static String taskById(int id) =>
      '/api/v1/task/$id';
}