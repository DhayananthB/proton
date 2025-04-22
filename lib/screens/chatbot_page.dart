import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/language_provider.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../screens/chat_history_screen.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  ChatBotPageState createState() => ChatBotPageState();
}

class ChatBotPageState extends State<ChatBotPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Get saved chat ID from local storage if available
      final savedChatId = await _chatService.getSavedChatId();
      
      if (savedChatId != null) {
        _chatId = savedChatId;
        final history = await _chatService.getChatHistory(_chatId!);
        
        if (history.isNotEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(history);
          });
          
          // Scroll to bottom after loading messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Show error snackbar
      if (mounted) {
        _showSnackBar('Failed to load chat history');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  Future<void> _listen() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    String localeId = languageProvider.language == 'ta' ? 'ta_IN' : 'en_IN';

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textController.text = val.recognizedWords;
              });
            }
          },
          localeId: localeId,
        );
      } else {
        debugPrint('Microphone permissions denied.');
        if (mounted) {
          _showSnackBar('Microphone permissions denied');
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    
    final userMessage = _textController.text;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final language = languageProvider.language == 'ta' ? 'tamil' : 'english';
    
    // Add user message to UI immediately
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
      _isLoading = true;
    });
    
    // Scroll to bottom to show new message
    _scrollToBottom();
    
    try {
      // Call API
      final response = await _chatService.sendMessage(
        message: userMessage,
        chatId: _chatId,
        language: language,
      );
      
      // Update chatId if this is first message
      if (_chatId == null) {
        _chatId = response.chatId;
        // Save chat ID for future sessions
        await _chatService.saveChatId(_chatId!);
      }
      
      // Add assistant response to UI
      setState(() {
        _messages.add(ChatMessage(
          text: response.response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      // Scroll to show the response
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        _showSnackBar('Failed to send message. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _createNewChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _getLocalizedText('newChatTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(_getLocalizedText('newChatContent')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getLocalizedText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _chatService.clearCurrentChatId();
              setState(() {
                _chatId = null;
                _messages.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_getLocalizedText('newChat')),
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isTamil = languageProvider.language == 'ta';
    return localizedText[isTamil ? 'ta' : 'en']![key] ?? key;
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Define localized text map
  final Map<String, Map<String, String>> localizedText = {
    'en': {
      'title': 'ChatBot',
      'newChat': 'New Chat',
      'history': 'History',
      'typeMessage': 'Type a message...',
      'messageLoadFailed': 'Failed to load chat history',
      'sendFailed': 'Failed to send message. Please try again.',
      'micPermissionDenied': 'Microphone permissions denied',
      'newChatTitle': 'Start New Chat?',
      'newChatContent': 'This will create a new conversation. Your current chat history will still be available in the history section.',
      'cancel': 'Cancel',
      'send': 'Send',
      'loading': 'Loading messages...',
      'startChatting': 'Start a new conversation',
      'typing': 'Typing...',
      'startListening': 'Start voice input',
      'stopListening': 'Stop voice input',
    },
    'ta': {
      'title': 'சாட்பாட்',
      'newChat': 'புதிய அரட்டை',
      'history': 'வரலாறு',
      'typeMessage': 'செய்தியை உள்ளிடவும்...',
      'messageLoadFailed': 'அரட்டை வரலாற்றை ஏற்ற முடியவில்லை',
      'sendFailed': 'செய்தியை அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      'micPermissionDenied': 'மைக்ரோஃபோன் அனுமதிகள் மறுக்கப்பட்டன',
      'newChatTitle': 'புதிய அரட்டையைத் தொடங்கவா?',
      'newChatContent': 'இது ஒரு புதிய உரையாடலை உருவாக்கும். உங்கள் தற்போதைய அரட்டை வரலாறு வரலாற்று பிரிவில் கிடைக்கும்.',
      'cancel': 'ரத்து செய்',
      'send': 'அனுப்பு',
      'loading': 'செய்திகளை ஏற்றுகிறது...',
      'startChatting': 'புதிய உரையாடலைத் தொடங்கவும்',
      'typing': 'தட்டச்சு செய்கிறது...',
      'startListening': 'குரல் உள்ளீடு தொடங்க',
      'stopListening': 'குரல் உள்ளீடு நிறுத்து',
    }
  };

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isTamil = languageProvider.language == 'ta';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Text(
          _getLocalizedText('title'),
          style: TextStyle(
            fontFamily: 'Noto Sans Tamil',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              // Navigate to chat history list
              final selectedChatId = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
              
              // If a chat was selected, load it
              if (selectedChatId != null && selectedChatId != _chatId) {
                setState(() {
                  _chatId = selectedChatId;
                  _messages.clear();
                  _isLoading = true;
                });
                await _loadChatHistory();
              }
            },
            tooltip: _getLocalizedText('history'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChat,
            tooltip: _getLocalizedText('newChat'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50, // Light background color instead of image
        ),
        child: Column(
          children: [
            // Date chip at the top of conversation
            if (_messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153), // Equivalent to 0.6 opacity
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDate(_messages.first.timestamp),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            
            Expanded(
              child: _isLoading && _messages.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getLocalizedText('loading'),
                            style: TextStyle(
                              fontFamily: 'Noto Sans Tamil',
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getLocalizedText('startChatting'),
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Tamil',
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages.reversed.toList()[index];
                            final showTimestamp = index == 0 || 
                                _shouldShowTimestamp(
                                  _messages.reversed.toList()[index].timestamp,
                                  index > 0 ? _messages.reversed.toList()[index - 1].timestamp : DateTime.now(),
                                );
                                
                            return Column(
                              children: [
                                if (showTimestamp && index > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: Colors.black.withAlpha(153), // Equivalent to 0.6 opacity
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _formatDate(message.timestamp),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                _buildMessageBubble(message, isTamil),
                              ],
                            );
                          },
                        ),
            ),
            if (_isLoading && _messages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getLocalizedText('typing'),
                          style: TextStyle(
                            fontFamily: 'Noto Sans Tamil',
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13), // Equivalent to 0.05 opacity
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(13), // Equivalent to 0.05 opacity
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  hintText: _getLocalizedText('typeMessage'),
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontFamily: 'Noto Sans Tamil',
                                    color: Colors.grey.shade400,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Tamil',
                                  fontSize: 16,
                                ),
                                maxLines: 4,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none, 
                                color: _isListening ? Colors.red : Colors.grey.shade700,
                              ),
                              onPressed: _listen,
                              tooltip: _isListening ? _getLocalizedText('stopListening') : _getLocalizedText('startListening'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withAlpha(102), // Equivalent to 0.4 opacity
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _sendMessage,
                        tooltip: _getLocalizedText('send'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine if we should show a timestamp separator
  bool _shouldShowTimestamp(DateTime current, DateTime previous) {
    return current.difference(previous).inHours > 1 ||
           current.day != previous.day ||
           current.month != previous.month ||
           current.year != previous.year;
  }

  // Custom message bubble widget with proper Tamil font support and improved design
  Widget _buildMessageBubble(ChatMessage message, bool isTamil) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isUser ? 64 : 0,
            right: isUser ? 0 : 64,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser 
                ? Theme.of(context).primaryColor 
                : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isUser ? const Radius.circular(0) : null,
              bottomLeft: !isUser ? const Radius.circular(0) : null,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontFamily: 'Noto Sans Tamil', // Essential for Tamil rendering
                  fontSize: isTamil ? 16.0 : 15.0, // Slightly larger for Tamil
                  height: isTamil ? 1.5 : 1.4, // Better line height for Tamil
                ),
                textDirection: TextDirection.ltr, // LTR works for both English and Tamil
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}