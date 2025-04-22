import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/chat_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _histories = [];

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final histories = await _chatService.getAllChatHistories();
      if (mounted) {
        setState(() {
          _histories = histories;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat histories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat histories')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectChat(String chatId) async {
    await _chatService.saveChatId(chatId);
    if (mounted) {
      Navigator.pop(context, chatId);
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isTamil = languageProvider.language == 'ta';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'உரையாடல் வரலாறு' : 'Chat History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? Center(
                  child: Text(
                    isTamil
                        ? 'வரலாறு இல்லை'
                        : 'No chat history found',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistories,
                  child: ListView.builder(
                    itemCount: _histories.length,
                    itemBuilder: (context, index) {
                      final history = _histories[index];
                      
                      return ListTile(
                        title: Text(
                          isTamil && history['language'] == 'tamil'
                              ? 'தமிழ் உரையாடல்'
                              : 'Chat ${index + 1}',
                        ),
                        subtitle: Text(
                          '${_formatDate(history['created_at'])} • ${history['message_count']} messages',
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => _selectChat(history['chat_id']),
                      );
                    },
                  ),
                ),
    );
  }
}