class UserModel {
  final String userId;
  final String firebaseUid;
  final String username;
  final String email;

  UserModel({
    required this.userId,
    required this.firebaseUid,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'username': username,
      'email': email,
    };
  }
} 