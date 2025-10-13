import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

import '../config/api_config.dart';

class ApiService {
  static String get currentUrl => ApiConfig.baseUrl;

  // Send question to RAG backend
  static Future<RAGResponse> askQuestion(String question) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/generate');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Your API returns {"data": "answer"} format
        return RAGResponse(
          answer: jsonData["data"] ?? "No answer received",
          sources: null,
          sourceUrl: null,
          confidence: null,
          metadata: jsonData,
        );
      } else {
        throw ApiException(
          'Server error: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  // Test connection to the backend
  static Future<bool> testConnection() async {
    try {
      // Test with a simple question to verify the API is working
      final url = Uri.parse('${ApiConfig.baseUrl}/generate');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": "test"}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get available models/info from backend
  static Future<Map<String, dynamic>> getBackendInfo() async {
    try {
      // Since your API doesn't have an /info endpoint, we'll return basic info
      return {
        "status": "connected",
        "endpoint": ApiConfig.baseUrl,
        "supported_languages": ["English", "Malayalam"],
        "features": ["RAG", "Translation", "Hybrid Retrieval"]
      };
    } catch (e) {
      throw ApiException('Error getting backend info: $e', 0);
    }
  }


  // Get current connection type
  static String get connectionType => ApiConfig.connectionType;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
