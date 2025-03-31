import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
    _checkAvailableLanguages(); // ✅ Check available languages
  }

  /// ✅ Check if Tamil is supported
  Future<void> _checkAvailableLanguages() async {
    await _speech.initialize();
    List<stt.LocaleName> locales = await _speech.locales();

    for (var locale in locales) {
      debugPrint('Locale: ${locale.localeId}, Name: ${locale.name}');
    }
  }

  /// ✅ Speech-to-Text with Tamil (`ta-IN`)
  Future<void> _listen() async {
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
          localeId: 'ta-IN', // ✅ Tamil Language Support
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamil ChatBot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'செய்தியை உள்ளிடவும்... (Type a message...)',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Message sent: ${_textController.text}');
                    _textController.clear(); // Clear input after sending
                  },
                  child: const Text('அனுப்பு (Send)'),
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

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatBotPage(),
  ));
}
