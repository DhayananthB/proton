import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// Add this for text encoding support

class DiseaseTrackingPage extends StatefulWidget {
  const DiseaseTrackingPage({super.key});
  
  @override
  State<DiseaseTrackingPage> createState() => _DiseaseTrackingPageState();
}

class _DiseaseTrackingPageState extends State<DiseaseTrackingPage> {
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  final ImagePicker _picker = ImagePicker();
  
  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(tempDir.path, 
                               'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,        // Very aggressive compression
      minWidth: 800,      // Limit the dimensions
      minHeight: 800,
      rotate: 0,
    );
    
    return File(result!.path);
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,  // First level compression through the picker
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _loading = true;
      });
      
      // Get the picked file
      File imageFile = File(pickedFile.path);
      
      // Apply second level compression
      final compressedFile = await _compressImage(imageFile);
      
      setState(() {
        _image = compressedFile;
      });
      
      await _uploadImage(compressedFile);
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError('Error processing image: $e');
    }
  }
  
  Future<void> _uploadImage(File image) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).language;
    final url = Uri.parse('https://pestclassify.onrender.com/predict?lang=$lang');
    
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        // Create a multipart request
        var request = http.MultipartRequest('POST', url);
        
        // Add file to request
        var fileStream = http.ByteStream(image.openRead());
        var fileLength = await image.length();
        
        var multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        request.files.add(multipartFile);
        
        // Set headers for UTF-8 encoding
        request.headers['Accept-Charset'] = 'utf-8';
        
        // Send request with a timeout
        var streamedResponse = await request.send()
            .timeout(const Duration(seconds: 30));
        var response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          // Use UTF-8 decoder explicitly
          Map<String, dynamic> decodedResponse = json.decode(utf8.decode(response.bodyBytes));
          
          setState(() {
            _result = decodedResponse;
            _loading = false;
          });
          return;
        } else if (response.statusCode == 502 && retryCount < maxRetries) {
          // Wait before retry
          retryCount++;
          await Future.delayed(Duration(seconds: 3));
          continue;
        } else {
          setState(() {
            _loading = false;
          });
          _showError('Server error: ${response.statusCode}');
          return;
        }
      } catch (e) {
        setState(() {
          _loading = false;
        });
        _showError('Network error: Please check your connection');
        return;
      }
    }
  }
  
  void _showError([String message = 'Failed to get prediction. Try again.']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // Helper method to safely display Tamil text
  String _sanitizeText(String text) {
    // If text appears garbled, you might need to handle specific replacements
    // or encoding issues here
    return text;
  }
  
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;
    
    // Localized text map
    final Map<String, Map<String, String>> localizedText = {
      'en': {
        'title': 'Disease Tracking',
        'disease': 'Disease',
        'remedy': 'Remedy',
        'medicine': 'Medicine',
        'camera': 'Camera',
        'upload': 'Upload Image',
        'loading': 'Processing...',
      },
      'ta': {
        'title': 'நோய் கண்காணிப்பு',
        'disease': 'நோய் பெயர்',
        'remedy': 'சிகிச்சை',
        'medicine': 'மருந்து',
        'camera': 'கேமரா',
        'upload': 'படம் பதிவேற்று',
        'loading': 'செயலாக்கம்...',
      }
    };
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedText[lang]!['title']!,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_image != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _image!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (_loading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      localizedText[lang]!['loading']!,
                    ),
                  ],
                )
              else if (_result != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizedText[lang]!['disease']}: ${_sanitizeText(_result!['disease_name'])}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Noto Sans Tamil', // Add Tamil font
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${localizedText[lang]!['remedy']}: ${_sanitizeText(_result!['remedy'])}',
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Tamil', // Add Tamil font
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${localizedText[lang]!['medicine']}: ${_sanitizeText(_result!['medicine'])}',
                          style: const TextStyle(
                            fontFamily: 'Noto Sans Tamil', // Add Tamil font
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      localizedText[lang]!['camera']!,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: Text(
                      localizedText[lang]!['upload']!,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}