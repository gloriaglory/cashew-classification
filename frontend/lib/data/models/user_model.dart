class UserModel {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['id'] as int? ?? 0,
        fullName:  json['full_name'] as String? ?? '',
        username:  json['username'] as String? ?? '',
        email:     json['email'] as String? ?? '',
        phone:     json['phone'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'full_name':  fullName,
        'username':   username,
        'email':      email,
        'phone':      phone,
        'created_at': createdAt,
      };

  UserModel copyWith({
    String? fullName,
    String? phone,
  }) =>
      UserModel(
        id:        id,
        fullName:  fullName ?? this.fullName,
        username:  username,
        email:     email,
        phone:     phone ?? this.phone,
        createdAt: createdAt,
      );
}
