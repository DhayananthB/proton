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
      quality: 40,
      minWidth: 800,
      minHeight: 800,
      rotate: 0,
    );
    
    return File(result!.path);
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _loading = true;
      });
      
      File imageFile = File(pickedFile.path);
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
    final url = Uri.parse('https://diseaseclassify-ae904721d0f8.herokuapp.com/predict?lang=$lang');
    
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        var request = http.MultipartRequest('POST', url);
        
        var fileStream = http.ByteStream(image.openRead());
        var fileLength = await image.length();
        
        var multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        request.files.add(multipartFile);
        request.headers['Accept-Charset'] = 'utf-8';
        
        var streamedResponse = await request.send()
            .timeout(const Duration(seconds: 30));
        var response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          Map<String, dynamic> decodedResponse = json.decode(utf8.decode(response.bodyBytes));
          
          setState(() {
            _result = decodedResponse;
            _loading = false;
          });
          return;
        } else if (response.statusCode == 502 && retryCount < maxRetries) {
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  String _sanitizeText(String text) {
    return text;
  }
  
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;
    
    final Map<String, Map<String, String>> localizedText = {
      'en': {
        'title': 'Disease Tracking',
        'disease': 'Disease',
        'remedy': 'Remedy',
        'medicine': 'Medicine',
        'camera': 'Camera',
        'upload': 'Gallery',
        'loading': 'Processing...',
        'instructions': 'Take or upload a plant image to identify disease',
      },
      'ta': {
        'title': 'நோய் கண்காணிப்பு',
        'disease': 'நோய் பெயர்',
        'remedy': 'சிகிச்சை',
        'medicine': 'மருந்து',
        'camera': 'கேமரா',
        'upload': 'படம்',
        'loading': 'செயலாக்கம்...',
        'instructions': 'நோயை அடையாளம் காண தாவர படத்தை எடுக்கவும் அல்லது பதிவேற்றவும்',
      }
    };
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
              ),
            ),
          ),
          
          // Background patterns
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizedText[lang]!['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Instructions text
                          if (_image == null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24, top: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizedText[lang]!['instructions']!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Image preview
                          if (_image != null)
                            Container(
                              height: 240,
                              margin: const EdgeInsets.only(bottom: 24, top: 16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(40),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            
                          // Loading indicator
                          if (_loading)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(51),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizedText[lang]!['loading']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            
                          // Result card
                          else if (_result != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Disease name section
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0BA360).withAlpha(26),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.verified,
                                            color: Color(0xFF0BA360),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localizedText[lang]!['disease']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                _sanitizeText(_result!['disease_name']),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Noto Sans Tamil',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const Divider(height: 32),
                                    
                                    // Remedy section
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withAlpha(26),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.healing,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localizedText[lang]!['remedy']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _sanitizeText(_result!['remedy']),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Noto Sans Tamil',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Medicine section
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withAlpha(26),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.medication,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localizedText[lang]!['medicine']!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _sanitizeText(_result!['medicine']),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Noto Sans Tamil',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Camera and gallery buttons
                          Container(
                            margin: EdgeInsets.only(top: 16, bottom: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _loading ? null : () => _pickImage(ImageSource.camera),
                                    child: Container(
                                      height: 56,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF4CAF50).withAlpha(77),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            localizedText[lang]!['camera']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _loading ? null : () => _pickImage(ImageSource.gallery),
                                    child: Container(
                                      height: 56,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(51),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.photo_library, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            localizedText[lang]!['upload']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}