import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Backend API URL - replace with your actual backend URL in production
  final String _backendUrl = 'http://170.106.106.90:8001';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Sync with PostgreSQL after successful Firebase auth
    await syncWithPostgres(credential.user!);

    return credential;
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Sync with PostgreSQL after successful Firebase auth
    await syncWithPostgres(credential.user!);

    return credential;
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    // The existing Google sign-in logic will remain in the LoginPage for now
    // but the sync functionality will be called from there
    throw UnimplementedError('Implement in LoginPage');
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Sync Firebase user with PostgreSQL database
  Future<String?> syncWithPostgres(User user) async {
    try {
      // Get the ID token
      final idToken = await user.getIdToken();

      // Send to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/firebase'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user_id'];
      } else {
        print('Failed to sync user with PostgreSQL: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error syncing user with PostgreSQL: $e');
      return null;
    }
  }

  // Get user info from backend
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final idToken = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$_backendUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get user info: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
