import 'package:flutter/material.dart';
import '../models/qa_pair.dart';
import '../models/chat_session.dart';
import '../services/qna_service.dart';

class QNAProvider extends ChangeNotifier {
  final QNAService _qnaService = QNAService();
  
  List<QAPair> _qaPairs = [];
  List<ChatSession> _chatSessions = [];
  String? _activeChatId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = false;

  List<QAPair> get qaPairs => _qaPairs;
  List<ChatSession> get chatSessions => _chatSessions;
  String? get activeChatId => _activeChatId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  QNAProvider() {
    _initialize();
  }

  void _initialize() {
    // Load existing Q&A pairs
    _loadQAPairs();
    _loadChatSessions();
    
    // Listen to connection changes
    _qnaService.connectionStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });
  }

  void _loadQAPairs() {
    _qaPairs = _qnaService.getAllQAPairs();
    notifyListeners();
  }

  void _loadChatSessions() {
    // Load from database or create default
    if (_chatSessions.isEmpty) {
      _createNewChat();
    } else {
      // Set first chat as active if none is active
      final activeChat = _chatSessions.firstWhere(
        (chat) => chat.isActive,
        orElse: () => _chatSessions.first,
      );
      setActiveChat(activeChat.id);
    }
  }

  void createNewChat() {
    _createNewChat();
  }

  void _createNewChat() {
    final newChat = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      createdAt: DateTime.now(),
    );
    
    // Deactivate all other chats
    for (int i = 0; i < _chatSessions.length; i++) {
      _chatSessions[i] = _chatSessions[i].copyWith(isActive: false);
    }
    
    _chatSessions.insert(0, newChat);
    _activeChatId = newChat.id;
    _qaPairs = [];
    notifyListeners();
  }

  void setActiveChat(String chatId) {
    print('Setting active chat: $chatId');
    print('Available chats: ${_chatSessions.map((c) => c.id).toList()}');
    
    // Deactivate all chats
    for (int i = 0; i < _chatSessions.length; i++) {
      _chatSessions[i] = _chatSessions[i].copyWith(isActive: false);
    }
    
    // Activate selected chat
    final index = _chatSessions.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      _chatSessions[index] = _chatSessions[index].copyWith(isActive: true);
      _activeChatId = chatId;
      _loadQAPairsForChat(chatId); // Load Q&A pairs for this specific chat
      print('Chat activated: ${_chatSessions[index].title}');
    } else {
      print('Chat not found: $chatId');
    }
    notifyListeners();
  }

  void _loadQAPairsForChat(String chatId) {
    // For now, load all Q&A pairs. In a real app, you'd filter by chatId
    _qaPairs = _qnaService.getAllQAPairs();
    notifyListeners();
  }

  void deleteChatSession(String chatId) {
    _chatSessions.removeWhere((chat) => chat.id == chatId);
    if (_activeChatId == chatId) {
      if (_chatSessions.isNotEmpty) {
        setActiveChat(_chatSessions.first.id);
      } else {
        _createNewChat();
      }
    }
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _qnaService.askQuestion(question);
      
      if (result.isSuccess && result.qaPair != null) {
        _qaPairs.insert(0, result.qaPair!);
        notifyListeners();
      } else if (result.hasSimilarQuestions && result.similarQuestions != null) {
        _setError('Similar questions found. Please try one of these:');
        // You might want to show similar questions in UI
      } else if (result.isOfflineNoMatch) {
        _setError(result.errorMessage ?? 'No offline answer found');
      } else if (result.isError) {
        _setError(result.errorMessage ?? 'An error occurred');
      }
    } catch (e) {
      _setError('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteQAPair(String id) async {
    await _qnaService.deleteQAPair(id);
    _qaPairs.removeWhere((pair) => pair.id == id);
    notifyListeners();
  }

  List<QAPair> searchQAPairs(String query) {
    return _qnaService.searchQAPairs(query);
  }

  List<QAPair> getSimilarQuestions(String question) {
    return _qnaService.getSimilarQuestions(question);
  }

  void clearError() {
    _clearError();
  }
}
