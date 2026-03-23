import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  const CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.novelId,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
    this.chapterId,
  });

  final String id;
  final String userId;
  final String username;
  final String novelId;
  final String content;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? chapterId;

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        username: json['username'] as String? ?? 'User',
        novelId: json['novelId'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        avatarUrl: json['avatarUrl'] as String?,
        chapterId: json['chapterId'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
