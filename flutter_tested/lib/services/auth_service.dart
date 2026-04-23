import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_config.dart';

// ---------- Models ----------

class ParentModel {
  final int id;
  final String email;
  final String fullName;

  ParentModel({required this.id, required this.email, required this.fullName});

  factory ParentModel.fromJson(Map<String, dynamic> j) => ParentModel(
        id: j['id'],
        email: j['email'],
        fullName: j['full_name'],
      );
}

class ChildModel {
  final int id;
  final String name;
  final int age;
  final String grade;
  final String avatar;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.avatar,
  });

  factory ChildModel.fromJson(Map<String, dynamic> j) => ChildModel(
        id: j['id'],
        name: j['name'],
        age: j['age'],
        grade: j['grade'],
        avatar: j['avatar'] ?? 'fox',
      );
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// ---------- Service ----------

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  late final Dio _dio;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
          await clearTokens();
        }
        handler.next(error);
      },
    ));
  }

  // ---------- Token helpers ----------

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<bool> get isLoggedIn async => (await getAccessToken()) != null;

  Future<void> _saveTokens(String access, String refresh) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}${ApiConfig.authRefresh}',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      await Future.wait([
        _storage.write(key: _accessKey, value: response.data['access_token']),
        _storage.write(key: _refreshKey, value: response.data['refresh_token']),
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- Auth ----------

  Future<ParentModel> login(String email, String password) async {
    try {
      final res = await _dio.post(ApiConfig.authLogin, data: {
        'email': email,
        'password': password,
      });
      await _saveTokens(res.data['access_token'], res.data['refresh_token']);
      return await getCurrentParent();
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  // Register returns ParentOut (no tokens) — login immediately after.
  Future<ParentModel> register(String email, String password, String fullName) async {
    try {
      await _dio.post(ApiConfig.authRegister, data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      return await login(email, password);
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(ApiConfig.authLogout, data: {'refresh_token': refreshToken});
      }
    } catch (_) {}
    await clearTokens();
  }

  Future<ParentModel> getCurrentParent() async {
    try {
      final res = await _dio.get(ApiConfig.authMe);
      return ParentModel.fromJson(res.data);
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  // ---------- Children ----------

  Future<List<ChildModel>> getChildren() async {
    try {
      final res = await _dio.get(ApiConfig.children);
      return (res.data as List).map((e) => ChildModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  Future<ChildModel> createChild({
    required String name,
    required int age,
    required String grade,
    required String avatar,
  }) async {
    try {
      final res = await _dio.post(ApiConfig.children, data: {
        'name': name,
        'age': age,
        'grade': grade,
        'avatar': avatar,
      });
      return ChildModel.fromJson(res.data);
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  Future<void> deleteChild(int id) async {
    try {
      await _dio.delete('${ApiConfig.children}/$id');
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  // ---------- Error parsing ----------

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.first['msg']?.toString() ?? 'An error occurred';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    return 'Connection error. Please check your internet.';
  }
}
