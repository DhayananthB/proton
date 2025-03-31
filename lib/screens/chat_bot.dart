import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/language_provider.dart';
import 'language_selection.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  ChatBotPageState createState() => ChatBotPageState();
}

class ChatBotPageState extends State<ChatBotPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.language == 'ta' ? 'சாட்பாட்' : 'ChatBot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
              );
              setState(() {}); // Refresh UI after returning
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: languageProvider.language == 'ta' ? 'செய்தியை உள்ளிடவும்...' : 'Type a message...',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Message sent: ${_textController.text}');
                    _textController.clear();
                  },
                  child: Text(languageProvider.language == 'ta' ? 'அனுப்பு' : 'Send'),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.black,
                  ),
                  onPressed: _listen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
