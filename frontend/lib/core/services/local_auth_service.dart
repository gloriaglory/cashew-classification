import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const _usersKey = 'local_users';
  static const _adminUsername = 'admin';
  static const _adminPassword = 'admin123';

  static String _detKey(String username) => 'detections_$username';

  // ── Auth ──────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    final users = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    if (users.any((u) => u['username'] == username)) {
      return {'success': false, 'message': 'Username already taken'};
    }

    final user = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'created_at': DateTime.now().toIso8601String(),
    };

    users.add(user);
    await prefs.setString(_usersKey, jsonEncode(users));

    final publicUser = Map<String, dynamic>.from(user)..remove('password');
    return {'success': true, 'token': username, 'user': publicUser};
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {'success': false, 'message': 'No account found. Please register first.'};

    final users = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    final matches = users.where((u) =>
        u['username'] == username && u['password'] == password);

    if (matches.isEmpty) return {'success': false, 'message': 'Invalid username or password'};

    final user = Map<String, dynamic>.from(matches.first)..remove('password');
    return {'success': true, 'token': username, 'user': user};
  }

  static Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    if (username == _adminUsername && password == _adminPassword) {
      return {'success': true, 'token': 'admin_token'};
    }
    return {'success': false, 'message': 'Invalid admin credentials'};
  }

  // ── Detections ────────────────────────────────────────────────────────────────

  static Future<void> saveDetection(Map<String, dynamic> result, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _detKey(username);
    final raw = prefs.getString(key);
    final list = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    final id = DateTime.now().millisecondsSinceEpoch;
    list.insert(0, {
      'id': id,
      'detection_id': id,
      'image_path': result['image_path'] ?? '',
      'image_url': result['image_url'] ?? '',
      'is_healthy': result['is_healthy'] as bool? ?? false,
      'disease_name': result['disease_name'] as String? ?? '',
      'confidence_score': result['confidence'],
      'description': result['description'] ?? '',
      'symptoms': result['symptoms'] ?? '',
      'prevention': result['prevention'] ?? '',
      'pesticide_name': result['pesticide_name'] ?? '',
      'dosage': result['dosage'] ?? '',
      'application_method': result['application_method'] ?? '',
      'recommendation': result['recommendation'] ?? '',
      'detection_date': DateTime.now().toIso8601String(),
    });

    await prefs.setString(key, jsonEncode(list));
  }

  static Future<Map<String, dynamic>> getHistory(
    String username, {
    String search = '',
    String filter = 'all',
    String sort = 'desc',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_detKey(username));
    var list = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    if (search.isNotEmpty) {
      list = list.where((d) {
        final name = (d['disease_name'] as String? ?? '').toLowerCase();
        return name.contains(search.toLowerCase());
      }).toList();
    }
    if (filter == 'healthy') {
      list = list.where((d) => d['is_healthy'] == true).toList();
    } else if (filter == 'diseased') {
      list = list.where((d) => d['is_healthy'] != true).toList();
    }
    if (sort == 'asc') list = list.reversed.toList();

    return {'success': true, 'history': list, 'total': list.length};
  }

  static Future<Map<String, dynamic>> getDashboardStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_detKey(username));
    final list = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    final healthy = list.where((d) => d['is_healthy'] == true).length;
    return {
      'success': true,
      'stats': {
        'total_scans': list.length,
        'healthy_leaves': healthy,
        'diseased_leaves': list.length - healthy,
      },
    };
  }

  // ── Admin helpers ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    final users = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    int total = 0, healthy = 0;
    for (final u in users) {
      final dr = prefs.getString(_detKey(u['username'] as String));
      if (dr != null) {
        final dets = List<Map<String, dynamic>>.from(jsonDecode(dr) as List);
        total += dets.length;
        healthy += dets.where((d) => d['is_healthy'] == true).length;
      }
    }

    return {
      'success': true,
      'statistics': {
        'total_users': users.length,
        'total_detections': total,
        'healthy_count': healthy,
        'diseased_count': total - healthy,
      },
    };
  }

  static Future<Map<String, dynamic>> getAdminUsers({String search = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    var users = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw) as List)
        : <Map<String, dynamic>>[];

    if (search.isNotEmpty) {
      users = users.where((u) {
        final name = (u['full_name'] as String? ?? '').toLowerCase();
        final un = (u['username'] as String? ?? '').toLowerCase();
        return name.contains(search.toLowerCase()) || un.contains(search.toLowerCase());
      }).toList();
    }

    final sanitized = users.map((u) => Map<String, dynamic>.from(u)..remove('password')).toList();
    return {'success': true, 'users': sanitized};
  }
}
