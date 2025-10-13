import 'dart:math';
import '../models/qa_pair.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class QNAService {
  static final QNAService _instance = QNAService._internal();
  factory QNAService() => _instance;
  QNAService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  // Ask a question - handles both online and offline scenarios
  Future<QAResult> askQuestion(String question) async {
    if (question.trim().isEmpty) {
      return QAResult.error('Please enter a question');
    }

    // Check if we're online and can reach the backend
    if (_connectivityService.isOnline && await _connectivityService.canReachBackend()) {
      return await _askOnline(question);
    } else {
      return await _askOffline(question);
    }
  }

  // Handle online question asking
  Future<QAResult> _askOnline(String question) async {
    try {
      // First check if we already have this question in local storage
      final existingPair = _findExistingQuestion(question);
      if (existingPair != null) {
        return QAResult.success(existingPair, isFromCache: true);
      }

      // Ask the backend
      final response = await ApiService.askQuestion(question);
      
      // Create Q&A pair
      final qaPair = QAPair(
        id: _generateId(),
        question: question,
        answer: response.answer,
        timestamp: DateTime.now(),
        isOffline: false,
        sourceUrl: response.sourceUrl,
      );

      // Save to local database
      await DatabaseService.saveQAPair(qaPair);

      return QAResult.success(qaPair, isFromCache: false);
    } catch (e) {
      // If online request fails, try offline
      return await _askOffline(question);
    }
  }

  // Handle offline question asking
  Future<QAResult> _askOffline(String question) async {
    // Look for exact match first
    final exactMatch = _findExistingQuestion(question);
    if (exactMatch != null) {
      return QAResult.success(exactMatch, isFromCache: true);
    }

    // Look for similar questions
    final similarQuestions = DatabaseService.getSimilarQuestions(question);
    if (similarQuestions.isNotEmpty) {
      return QAResult.similarQuestions(similarQuestions);
    }

    // No matches found
    return QAResult.offlineNoMatch();
  }

  // Find existing question in database
  QAPair? _findExistingQuestion(String question) {
    final allPairs = DatabaseService.getAllQAPairs();
    final lowercaseQuestion = question.toLowerCase().trim();
    
    for (final pair in allPairs) {
      if (pair.question.toLowerCase().trim() == lowercaseQuestion) {
        return pair;
      }
    }
    return null;
  }

  // Get all Q&A pairs
  List<QAPair> getAllQAPairs() {
    return DatabaseService.getAllQAPairs();
  }

  // Search Q&A pairs
  List<QAPair> searchQAPairs(String query) {
    return DatabaseService.searchQAPairs(query);
  }

  // Delete a Q&A pair
  Future<void> deleteQAPair(String id) async {
    await DatabaseService.deleteQAPair(id);
  }

  // Get similar questions for suggestions
  List<QAPair> getSimilarQuestions(String question) {
    return DatabaseService.getSimilarQuestions(question);
  }

  // Generate unique ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'qa_${timestamp}_$random';
  }

  // Get connection status
  bool get isOnline => _connectivityService.isOnline;

  // Get connection stream
  Stream<bool> get connectionStream => _connectivityService.connectionStream;
}

// Result class for Q&A operations
class QAResult {
  final QAResultType type;
  final QAPair? qaPair;
  final List<QAPair>? similarQuestions;
  final String? errorMessage;
  final bool isFromCache;

  QAResult._({
    required this.type,
    this.qaPair,
    this.similarQuestions,
    this.errorMessage,
    this.isFromCache = false,
  });

  factory QAResult.success(QAPair qaPair, {bool isFromCache = false}) {
    return QAResult._(
      type: QAResultType.success,
      qaPair: qaPair,
      isFromCache: isFromCache,
    );
  }

  factory QAResult.similarQuestions(List<QAPair> similarQuestions) {
    return QAResult._(
      type: QAResultType.similarQuestions,
      similarQuestions: similarQuestions,
    );
  }

  factory QAResult.offlineNoMatch() {
    return QAResult._(
      type: QAResultType.offlineNoMatch,
      errorMessage: 'No matching answer found offline. Please connect to the internet to ask new questions.',
    );
  }

  factory QAResult.error(String message) {
    return QAResult._(
      type: QAResultType.error,
      errorMessage: message,
    );
  }

  bool get isSuccess => type == QAResultType.success;
  bool get hasSimilarQuestions => type == QAResultType.similarQuestions;
  bool get isOfflineNoMatch => type == QAResultType.offlineNoMatch;
  bool get isError => type == QAResultType.error;
}

enum QAResultType {
  success,
  similarQuestions,
  offlineNoMatch,
  error,
}
