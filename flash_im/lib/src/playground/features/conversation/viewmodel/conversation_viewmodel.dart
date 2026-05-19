import 'package:flutter/material.dart';
import '../models/conversation_item.dart';
import '../services/conversation_service.dart';

class ConversationViewModel extends ChangeNotifier {
  final ConversationService _service;
  List<ConversationItem> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  ConversationViewModel({ConversationService? service})
      : _service = service ?? ConversationService();

  List<ConversationItem> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _conversations.isNotEmpty;
  bool get hasError => _errorMessage != null;

  Future<void> loadConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getConversationList();
      _conversations = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshConversations() async {
    await loadConversations();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversations.clear();
    super.dispose();
  }
}
