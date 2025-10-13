import 'package:hive_flutter/hive_flutter.dart';
import '../models/qa_pair.dart';

class DatabaseService {
  static const String _boxName = 'qa_pairs';
  static Box<QAPair>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QAPairAdapter());
    }
    
    _box = await Hive.openBox<QAPair>(_boxName);
  }

  static Box<QAPair> get box {
    if (_box == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() first.');
    }
    return _box!;
  }

  // Save a Q&A pair
  static Future<void> saveQAPair(QAPair qaPair) async {
    await box.put(qaPair.id, qaPair);
  }

  // Get a Q&A pair by ID
  static QAPair? getQAPair(String id) {
    return box.get(id);
  }

  // Search for Q&A pairs by question (fuzzy search)
  static List<QAPair> searchQAPairs(String query) {
    final allPairs = box.values.toList();
    final lowercaseQuery = query.toLowerCase();
    
    return allPairs.where((pair) {
      return pair.question.toLowerCase().contains(lowercaseQuery) ||
             pair.answer.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get all Q&A pairs
  static List<QAPair> getAllQAPairs() {
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Delete a Q&A pair
  static Future<void> deleteQAPair(String id) async {
    await box.delete(id);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await box.clear();
  }

  // Get count of stored pairs
  static int getCount() {
    return box.length;
  }

  // Check if a question exists
  static bool questionExists(String question) {
    return box.values.any((pair) => 
      pair.question.toLowerCase() == question.toLowerCase());
  }

  // Get similar questions (for better offline experience)
  static List<QAPair> getSimilarQuestions(String question, {int limit = 5}) {
    final allPairs = box.values.toList();
    final lowercaseQuestion = question.toLowerCase();
    
    // Simple similarity check - can be improved with more sophisticated algorithms
    final similarPairs = allPairs.where((pair) {
      final pairQuestion = pair.question.toLowerCase();
      return pairQuestion.contains(lowercaseQuestion) ||
             lowercaseQuestion.contains(pairQuestion) ||
             _calculateSimilarity(pairQuestion, lowercaseQuestion) > 0.6;
    }).toList();
    
    similarPairs.sort((a, b) => 
      _calculateSimilarity(b.question.toLowerCase(), lowercaseQuestion)
      .compareTo(_calculateSimilarity(a.question.toLowerCase(), lowercaseQuestion)));
    
    return similarPairs.take(limit).toList();
  }

  // Simple similarity calculation (Jaccard similarity)
  static double _calculateSimilarity(String str1, String str2) {
    final words1 = str1.split(' ').toSet();
    final words2 = str2.split(' ').toSet();
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  static Future<void> close() async {
    await _box?.close();
  }
}
