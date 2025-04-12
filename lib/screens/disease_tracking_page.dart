import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class DiseaseTrackingPage extends StatefulWidget {
  const DiseaseTrackingPage({super.key});

  @override
  State<DiseaseTrackingPage> createState() => _DiseaseTrackingPageState();
}

class _DiseaseTrackingPageState extends State<DiseaseTrackingPage> {
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
      _result = null;
    });

    await _uploadImage(_image!);
  }

  Future<void> _uploadImage(File image) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).language;
    final url = Uri.parse('https://pestclassify.onrender.com/predict?lang=$lang');
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        setState(() {
          _result = json.decode(respStr);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        _showError();
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to get prediction. Try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'ta' ? 'நோய் கண்காணிப்பு' : 'Disease Tracking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator()
            else if (_result != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang == 'ta' ? 'நோய் பெயர்' : 'Disease'}: ${_result!['disease_name']}'),
                  const SizedBox(height: 8),
                  Text('${lang == 'ta' ? 'சிகிச்சை' : 'Remedy'}: ${_result!['remedy']}'),
                  const SizedBox(height: 8),
                  Text('${lang == 'ta' ? 'மருந்து' : 'Medicine'}: ${_result!['medicine']}'),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(lang == 'ta' ? 'கேமரா' : 'Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: Text(lang == 'ta' ? 'படம் பதிவேற்று' : 'Upload Image'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
