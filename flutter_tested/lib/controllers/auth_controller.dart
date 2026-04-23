import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  final _service = AuthService();

  ParentModel? _currentParent;
  ChildModel? _selectedChild;
  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _errorMessage;

  ParentModel? get currentParent => _currentParent;
  ChildModel? get selectedChild => _selectedChild;
  List<ChildModel> get children => List.unmodifiable(_children);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentParent != null;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Called on app start to restore session.
  Future<bool> checkAuthState() async {
    _setLoading(true);
    try {
      if (!await _service.isLoggedIn) return false;
      _currentParent = await _service.getCurrentParent();
      _children = await _service.getChildren();
      notifyListeners();
      return true;
    } catch (_) {
      await _service.clearTokens();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentParent = await _service.login(email, password);
      _children = await _service.getChildren();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentParent = await _service.register(email, password, fullName);
      _children = await _service.getChildren();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _service.logout();
    _currentParent = null;
    _selectedChild = null;
    _children = [];
    _isLoading = false;
    notifyListeners();
  }

  void selectChild(ChildModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  Future<bool> addChild({
    required String name,
    required int age,
    required String grade,
    required String avatar,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final child = await _service.createChild(
        name: name,
        age: age,
        grade: grade,
        avatar: avatar,
      );
      _children = [..._children, child];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteChild(int id) async {
    try {
      await _service.deleteChild(id);
      _children = _children.where((c) => c.id != id).toList();
      if (_selectedChild?.id == id) _selectedChild = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
