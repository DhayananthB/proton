import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/language_provider.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

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
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat history')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permissions denied')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;
    
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
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Show error and roll back the user message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _createNewChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Chat?'),
        content: Text('This will create a new conversation. Your current chat history will still be available in the history section.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _chatService.clearCurrentChatId();
              setState(() {
                _chatId = null;
                _messages.clear();
              });
            },
            child: Text('New Chat'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isTamil = languageProvider.language == 'ta';

    // Define localized text map similar to DiseaseTrackingPage
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
      }
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedText[isTamil ? 'ta' : 'en']!['title']!,
          style: TextStyle(
            fontFamily: 'Noto Sans Tamil',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () async {
              // Navigate to chat history list
              // This would be implemented in a separate screen
            },
            tooltip: localizedText[isTamil ? 'ta' : 'en']!['history']!,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewChat,
            tooltip: localizedText[isTamil ? 'ta' : 'en']!['newChat']!,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages.reversed.toList()[index];
                      return _buildMessageBubble(message, isTamil);
                    },
                  ),
          ),
          if (_isLoading && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: localizedText[isTamil ? 'ta' : 'en']!['typeMessage']!,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: TextStyle(
                      fontFamily: 'Noto Sans Tamil', // Apply Tamil font globally
                      fontSize: 16,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none, 
                    color: _isListening ? Colors.red : Colors.black
                  ),
                  onPressed: _listen,
                  tooltip: _isListening ? 'Stop' : 'Speak',
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom message bubble widget with proper Tamil font support
  Widget _buildMessageBubble(ChatMessage message, bool isTamil) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? Colors.blueAccent 
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
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
                color: message.isUser ? Colors.white : Colors.black,
                fontFamily: 'Noto Sans Tamil', // Essential for Tamil rendering
                fontSize: isTamil ? 16.0 : 15.0, // Slightly larger for Tamil
                height: isTamil ? 1.5 : 1.4, // Better line height for Tamil
              ),
              textDirection: TextDirection.ltr, // LTR works for both English and Tamil
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}