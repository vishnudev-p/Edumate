import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qa_pair.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class QAPair {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String question;

  @HiveField(2)
  final String answer;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isOffline;

  @HiveField(5)
  final String? sourceUrl;

  QAPair({
    required this.id,
    required this.question,
    required this.answer,
    required this.timestamp,
    this.isOffline = false,
    this.sourceUrl,
  });

  factory QAPair.fromJson(Map<String, dynamic> json) => _$QAPairFromJson(json);
  Map<String, dynamic> toJson() => _$QAPairToJson(this);

  QAPair copyWith({
    String? id,
    String? question,
    String? answer,
    DateTime? timestamp,
    bool? isOffline,
    String? sourceUrl,
  }) {
    return QAPair(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      timestamp: timestamp ?? this.timestamp,
      isOffline: isOffline ?? this.isOffline,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }
}
