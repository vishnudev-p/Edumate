// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_pair.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QAPairAdapter extends TypeAdapter<QAPair> {
  @override
  final int typeId = 0;

  @override
  QAPair read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QAPair(
      id: fields[0] as String,
      question: fields[1] as String,
      answer: fields[2] as String,
      timestamp: fields[3] as DateTime,
      isOffline: fields[4] as bool,
      sourceUrl: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QAPair obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isOffline)
      ..writeByte(5)
      ..write(obj.sourceUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QAPairAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QAPair _$QAPairFromJson(Map<String, dynamic> json) => QAPair(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isOffline: json['isOffline'] as bool? ?? false,
      sourceUrl: json['sourceUrl'] as String?,
    );

Map<String, dynamic> _$QAPairToJson(QAPair instance) => <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answer': instance.answer,
      'timestamp': instance.timestamp.toIso8601String(),
      'isOffline': instance.isOffline,
      'sourceUrl': instance.sourceUrl,
    };
