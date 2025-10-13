import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Map to store messages for each chat
  final Map<String, List<String>> _chatMessages = {};

  // List of chat IDs for the sidebar
  final List<String> _chatIds = [];

  // Currently active chat ID
  String? _currentChatId;

  // Text controller for message input
  final TextEditingController _messageController = TextEditingController();

  void _startNewChat() {
    String newChatId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _chatIds.add(newChatId);
      _chatMessages[newChatId] = [];
      _currentChatId = newChatId;
    });
  }

  void _selectChat(String chatId) {
    setState(() {
      _currentChatId = chatId;
    });
  }

  void _sendMessage() {
    if (_currentChatId == null || _messageController.text.trim().isEmpty) return;
    setState(() {
      _chatMessages[_currentChatId]!.add(_messageController.text.trim());
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(child: Text('Chats')),
            Expanded(
              child: ListView.builder(
                itemCount: _chatIds.length,
                itemBuilder: (context, index) {
                  String chatId = _chatIds[index];
                  return ListTile(
                    title: Text('Chat ${index + 1}'),
                    selected: _currentChatId == chatId,
                    onTap: () => _selectChat(chatId),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
              ),
            )
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(_currentChatId == null
            ? 'No Chat Selected'
            : 'Chat ${_chatIds.indexOf(_currentChatId!) + 1}'),
      ),
      body: _currentChatId == null
          ? const Center(child: Text('Select or start a new chat'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatMessages[_currentChatId]!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_chatMessages[_currentChatId]![index]),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
