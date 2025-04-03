import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  String? get error => _error;
  
  // Constructor - initialize the auth state
  AuthProvider() {
    _initAuthState();
  }
  
  // Initialize auth state by listening to Firebase auth changes
  void _initAuthState() {
    _isLoading = true;
    notifyListeners();
    
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      
      if (user != null) {
        // User is logged in, fetch user data from backend
        try {
          await _fetchUserData();
        } catch (e) {
          _error = e.toString();
        }
      } else {
        // User is logged out
        _user = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Fetch user data from backend
  Future<void> _fetchUserData() async {
    try {
      final userData = await _apiService.authenticatedGet('/users/me');
      _user = UserModel.fromJson(userData);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch user data: ${e.toString()}';
      throw Exception(_error);
    }
  }
  
  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Auth state listener will update _firebaseUser and fetch user data
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }
  
  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      // Auth state listener will update _firebaseUser and fetch user data
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signOut();
      // Auth state listener will update _firebaseUser and clear user data
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }
}