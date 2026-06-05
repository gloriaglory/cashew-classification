import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  late final Dio _adminDio;

  ApiService() {
    final opts = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    );

    _dio = Dio(opts)..interceptors.add(_AuthInterceptor(isAdmin: false));
    _adminDio = Dio(opts)..interceptors.add(_AuthInterceptor(isAdmin: true));
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/register', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/login', data: {'username': username, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try { await _dio.post('/logout'); } catch (_) {}
  }

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/profile', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword(String oldPw, String newPw) async {
    final res = await _dio.put('/change-password', data: {
      'old_password': oldPw,
      'new_password': newPw,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Detection ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> predict(File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path,
          filename: image.path.split('/').last),
    });
    final res = await _dio.post('/predict',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard-stats');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHistory({
    String search = '',
    String sort = 'desc',
    String filter = 'all',
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get('/history', queryParameters: {
      'search': search,
      'sort': sort,
      'filter': filter,
      'limit': limit,
      'offset': offset,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDetectionDetail(int id) async {
    final res = await _dio.get('/history/$id');
    return res.data as Map<String, dynamic>;
  }

  // ── Admin ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    final res = await _adminDio.post('/admin/login',
        data: {'username': username, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await _adminDio.get('/admin/statistics');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminUsers({String search = ''}) async {
    final res = await _adminDio.get('/admin/users', queryParameters: {'search': search});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminActivities({
    String search = '',
    String filter = '',
  }) async {
    final res = await _adminDio.get('/admin/activities',
        queryParameters: {'search': search, 'filter': filter});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminDiseases() async {
    final res = await _adminDio.get('/admin/diseases');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addDisease(Map<String, dynamic> data) async {
    final res = await _adminDio.post('/admin/add-disease', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDisease(int id, Map<String, dynamic> data) async {
    final res = await _adminDio.put('/admin/update-disease/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteDisease(int id) async {
    final res = await _adminDio.delete('/admin/delete-disease/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminPesticides() async {
    final res = await _adminDio.get('/admin/pesticides');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addPesticide(Map<String, dynamic> data) async {
    final res = await _adminDio.post('/admin/add-pesticide', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePesticide(int id, Map<String, dynamic> data) async {
    final res = await _adminDio.put('/admin/update-pesticide/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deletePesticide(int id) async {
    final res = await _adminDio.delete('/admin/delete-pesticide/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteActivity(int id) async {
    await _adminDio.delete('/admin/activities/$id');
  }

  Future<Map<String, dynamic>> getActiveModel() async {
    final res = await _adminDio.get('/admin/model');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> switchModel(String modelType) async {
    final res = await _adminDio.post('/admin/model/switch', data: {'model_type': modelType});
    return res.data as Map<String, dynamic>;
  }
}

class _AuthInterceptor extends Interceptor {
  final bool isAdmin;
  _AuthInterceptor({required this.isAdmin});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = isAdmin
        ? await StorageService.getAdminToken()
        : await StorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
