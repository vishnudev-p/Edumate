// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RAGResponse _$RAGResponseFromJson(Map<String, dynamic> json) => RAGResponse(
      answer: json['answer'] as String,
      sources:
          (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sourceUrl: json['sourceUrl'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RAGResponseToJson(RAGResponse instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'sources': instance.sources,
      'sourceUrl': instance.sourceUrl,
      'confidence': instance.confidence,
      'metadata': instance.metadata,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      error: json['error'] as String,
      message: json['message'] as String?,
      statusCode: (json['statusCode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'message': instance.message,
      'statusCode': instance.statusCode,
    };
