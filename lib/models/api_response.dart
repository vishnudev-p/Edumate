import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable()
class RAGResponse {
  final String answer;
  final List<String>? sources;
  final String? sourceUrl;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  RAGResponse({
    required this.answer,
    this.sources,
    this.sourceUrl,
    this.confidence,
    this.metadata,
  });

  factory RAGResponse.fromJson(Map<String, dynamic> json) => _$RAGResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RAGResponseToJson(this);
}

@JsonSerializable()
class ErrorResponse {
  final String error;
  final String? message;
  final int? statusCode;

  ErrorResponse({
    required this.error,
    this.message,
    this.statusCode,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);
}
