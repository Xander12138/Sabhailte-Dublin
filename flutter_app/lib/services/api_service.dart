import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Backend API URL - replace with your actual backend URL in production
  final String _baseUrl = 'http://170.106.106.90:8001';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the current user's ID token
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }
  
  // Make authenticated GET request
  Future<Map<String, dynamic>> authenticatedGet(String endpoint) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode} - ${response.body}');
    }
  }
  
  // Make authenticated POST request
  Future<Map<String, dynamic>> authenticatedPost(String endpoint, Map<String, dynamic> data) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit data: ${response.statusCode} - ${response.body}');
    }
  }
  
  // Make authenticated PUT request
  Future<Map<String, dynamic>> authenticatedPut(String endpoint, Map<String, dynamic> data) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update data: ${response.statusCode} - ${response.body}');
    }
  }
  
  // Make authenticated DELETE request
  Future<Map<String, dynamic>> authenticatedDelete(String endpoint) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete data: ${response.statusCode} - ${response.body}');
    }
  }
} 