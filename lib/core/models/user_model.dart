import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.image,
    this.role = 'USER',
  });

  final String id;
  final String email;
  final String? name;
  final String? image;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        image: json['image'] as String?,
        role: json['role'] as String? ?? 'USER',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'image': image,
        'role': role,
      };

  @override
  List<Object?> get props => [id, email];
}
