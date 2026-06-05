class AppConstants {
  static const String appName = 'CashewCare';
  static const String appTagline = 'AI-Powered Cashew Disease Detection';

  // Django backend
  static const String baseUrl = 'http://192.168.100.180:8000/api';

  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  static const String isAdminKey = 'is_admin';
  static const String adminTokenKey = 'admin_jwt_token';

  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 60000;

  static const List<String> diseaseClasses = [
    'Anthracnose',
    'Die Back',
    'Gummosis',
    'Healthy',
    'Leaf Blight',
    'Powdery Mildew',
  ];
}
