import 'package:hive/hive.dart';
import 'qa_pair.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 1)
class ChatSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<String> qaPairIds;

  @HiveField(4)
  final bool isActive;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.qaPairIds = const [],
    this.isActive = false,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<String>? qaPairIds,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      qaPairIds: qaPairIds ?? this.qaPairIds,
      isActive: isActive ?? this.isActive,
    );
  }
}
