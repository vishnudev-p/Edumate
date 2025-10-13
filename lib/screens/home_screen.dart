import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/qna_provider.dart';
import '../widgets/connection_status.dart';
import '../widgets/qa_message.dart';
import '../widgets/loading_indicator.dart';
import 'settings_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _askQuestion() {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      context.read<QNAProvider>().askQuestion(question);
      _questionController.clear();
      
      // Scroll to top to show new question
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Edumate',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F0F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Consumer<QNAProvider>(
            builder: (context, provider, child) {
              return ConnectionStatus(
                isOnline: provider.isOnline,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<QNAProvider>().createNewChat();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edumate',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your AI Learning Assistant',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E8E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<QNAProvider>(
                builder: (context, provider, child) {
                  return ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add, color: Colors.white),
                        title: const Text(
                          'New Chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          provider.createNewChat();
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(color: Color(0xFF404040)),
                      ...provider.chatSessions.map((chat) => ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        title: Text(
                          chat.title,
                          style: TextStyle(
                            color: chat.isActive ? const Color(0xFF6366F1) : Colors.white,
                            fontWeight: chat.isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${chat.qaPairIds.length} messages • ${chat.createdAt.day}/${chat.createdAt.month}',
                          style: const TextStyle(color: Color(0xFF8E8E8E)),
                        ),
                        onTap: () {
                          provider.setActiveChat(chat.id);
                          Navigator.pop(context);
                        },
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              provider.deleteChatSession(chat.id);
                            }
                          },
                        ),
                      )),
                    ],
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF404040)),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error message
          Consumer<QNAProvider>(
            builder: (context, provider, child) {
              if (provider.errorMessage != null) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5C1A1A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => provider.clearError(),
                        color: const Color(0xFFFF6B6B),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Q&A List - This takes up most of the space
          Expanded(
            child: Consumer<QNAProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.qaPairs.isEmpty) {
                  return const LoadingIndicator(
                    message: 'Thinking...',
                  );
                }

                if (provider.qaPairs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome to Edumate',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your AI Learning Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8E8E8E),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF404040)),
                          ),
                          child: const Text(
                            'Ask me anything to get started!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E8E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.qaPairs.length,
                  itemBuilder: (context, index) {
                    final qaPair = provider.qaPairs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: QAMessage(
                        qaPair: qaPair,
                        onDelete: () => _showDeleteDialog(qaPair.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input field at the BOTTOM - like ChatGPT
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F0F),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF404040), width: 1),
                    ),
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Message Edumate...',
                        hintStyle: TextStyle(color: Color(0xFF8E8E8E)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _askQuestion(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Consumer<QNAProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: provider.isLoading 
                            ? const Color(0xFF404040)
                            : const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: provider.isLoading ? null : _askQuestion,
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String qaPairId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question and answer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<QNAProvider>().deleteQAPair(qaPairId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}