import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String username;
  final String role;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    debugPrint('User.fromJson: Received raw data: $json');

    // Handle different response structures.
    final token = json['token'] ?? '';
    final user = json['user'] ?? json;

    debugPrint('User.fromJson: Token extracted: $token');
    debugPrint('User.fromJson: User data extracted: $user');

    return User(
      id: user['id'],
      username: user['username'],
      role: user['role'],
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'token': token,
    };
  }
}
