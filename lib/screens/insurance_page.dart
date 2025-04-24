import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/language_provider.dart';
import '../models/insurance_model.dart';
import '../services/insurance_service.dart';
import '../services/farmer_service.dart';
import '../models/farmer_model.dart';
import '../utils/translations.dart';

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _farmerNameController = TextEditingController();
  final TextEditingController _landAreaController = TextEditingController();
  final TextEditingController _cropPriceController = TextEditingController();
  final TextEditingController _claimReasonController = TextEditingController();

  String? _selectedCropType;
  String? _selectedSeason;
  File? _cropImage;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Farmer? _farmer;
  Insurance? _existingInsurance;
  bool _showClaimForm = false;

  // Define crop types and seasons
  final List<String> _cropTypes = ['rice', 'wheat', 'sugarcane', 'cotton', 'vegetables', 'fruits'];
  final List<String> _seasons = ['kharif', 'rabi', 'zaid'];

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    try {
      final farmer = await FarmerService.getFarmer();
      final existingInsurance = await InsuranceService.getInsurance();
      
      setState(() {
        _farmer = farmer;
        _existingInsurance = existingInsurance;
        _isLoading = false;
        
        // Pre-fill farmer name if available
        if (_farmer != null) {
          _farmerNameController.text = _farmer!.name;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _cropImage = File(image.path);
        });
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final currentLanguage = Provider.of<LanguageProvider>(context, listen: false).language;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText('cropImage', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppTranslations.getText('takePicture', currentLanguage)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppTranslations.getText('chooseFromGallery', currentLanguage)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitInsuranceApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Show an initial "connecting" message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connecting to insurance API...'),
            duration: Duration(seconds: 2),
          ),
        );

        final insurance = await InsuranceService.applyForInsurance(
          farmerName: _farmerNameController.text.trim(),
          cropType: _selectedCropType!,
          season: _selectedSeason!,
          landArea: double.parse(_landAreaController.text),
          cropPrice: double.parse(_cropPriceController.text),
          cropImage: _cropImage,
        );

        setState(() {
          _existingInsurance = insurance;
          _isSubmitting = false;
        });

        if (mounted) {
          final currentLanguage = Provider.of<LanguageProvider>(context, listen: false).language;
          
          // Display whether data was saved locally or to API
          final bool isLocalData = insurance.id?.startsWith('INS') ?? true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isLocalData 
                    ? 'Application saved locally (API not available)'
                    : AppTranslations.getText('applicationSuccess', currentLanguage)
              ),
              backgroundColor: isLocalData ? Colors.orange : Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitClaim() async {
    if (_existingInsurance == null || _claimReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a reason for your claim'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Show an initial "connecting" message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing claim...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      final insuranceId = _existingInsurance!.id ?? '';
      final claimReason = _claimReasonController.text.trim();
      
      final updatedInsurance = await InsuranceService.fileClaim(
        insuranceId: insuranceId,
        claimReason: claimReason,
      );
      
      setState(() {
        _existingInsurance = updatedInsurance;
        _isSubmitting = false;
        _showClaimForm = false;
      });

      if (mounted) {
        final currentLanguage = Provider.of<LanguageProvider>(context, listen: false).language;
        
        // Display whether data was saved locally or to API
        final bool isLocalData = updatedInsurance.id?.startsWith('INS') ?? true;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLocalData 
                  ? 'Claim saved locally (API not available)'
                  : AppTranslations.getText('claimSuccess', currentLanguage)
            ),
            backgroundColor: isLocalData ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filing claim: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _clearInsuranceData() async {
    try {
      // Show a confirmation dialog before clearing
      if (!mounted) return;
      
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Clear Data'),
          content: Text('Are you sure you want to clear all insurance data?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldClear) return;
      if (!mounted) return;
      
      final success = await InsuranceService.clearInsuranceData();
      if (success) {
        // Important: Make sure we reset both the insurance object AND the form flag
        setState(() {
          _existingInsurance = null;
          _showClaimForm = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insurance data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _landAreaController.dispose();
    _cropPriceController.dispose();
    _claimReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.language;

    String getText(String key) {
      return AppTranslations.getText(key, currentLanguage);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
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

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // If showing claim form, go back to insurance details instead of leaving the page
                                  if (_showClaimForm) {
                                    setState(() {
                                      _showClaimForm = false;
                                      _claimReasonController.clear();
                                    });
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              Text(
                                getText('cropInsurance'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Logic for which screen to show
                          Builder(
                            builder: (context) {
                              // If no farmer, show registration message
                              if (_farmer == null) {
                                return _buildNoFarmerMessage(getText);
                              }
                              
                              // If showing claim form, show it (this takes precedence)
                              if (_showClaimForm) {
                                return _buildClaimForm(getText);
                              }
                              
                              // If there's existing insurance, show its details
                              if (_existingInsurance != null) {
                                return _buildInsuranceDetails(getText);
                              }
                              
                              // If neither, show the insurance application form
                              return _buildInsuranceForm(getText);
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFarmerMessage(String Function(String) getText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 40),
          const SizedBox(height: 16),
          Text(
            getText('farmerRegistration'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            getText('requiredField'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                getText('farmerRegistration'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceDetails(String Function(String) getText) {
    if (_existingInsurance == null) return const SizedBox.shrink();

    // Check if insurance data has an ID that starts with "INS" (local) or uses MongoDB ObjectId format
    final bool isLocalData = _existingInsurance!.id?.startsWith('INS') ?? true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column with title and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    getText('insuranceStatus'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add an indicator for data source
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLocalData ? Colors.orange.withAlpha(100) : Colors.green.withAlpha(100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLocalData ? 'Local' : 'API',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // No longer show retry button since API has no way to retrieve data
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _existingInsurance!.status == 'Claimed' 
                      ? Colors.orange.withAlpha(100)
                      : (_existingInsurance!.status == 'Approved' 
                          ? Colors.green.withAlpha(100) 
                          : Colors.blue.withAlpha(100)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getText(_existingInsurance!.status.toLowerCase()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Show the insurance ID
          Text(
            'ID: ${_existingInsurance!.id ?? 'Unknown'}',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
            ),
          ),
          if (isLocalData) ...[
            Text(
              'Note: This data is stored locally on your device only.',
              style: TextStyle(
                color: Colors.orange.withAlpha(200),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          
          // Continue with the rest of the details
          _buildDetailItem(getText('farmerName'), _existingInsurance!.farmerName),
          _buildDetailItem(getText('cropType'), getText(_existingInsurance!.cropType)),
          _buildDetailItem(getText('season'), getText(_existingInsurance!.season)),
          _buildDetailItem(getText('landArea'), '${_existingInsurance!.landArea} acres'),
          _buildDetailItem(getText('cropPrice'), '₹${_existingInsurance!.cropPrice}/unit'),
          
          if (_existingInsurance!.claimReason != null && _existingInsurance!.claimReason!.isNotEmpty)
            _buildDetailItem(getText('claimReason'), _existingInsurance!.claimReason!),
          
          // Display crop image if available
          if (_existingInsurance!.cropImage != null && _existingInsurance!.cropImage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              getText('cropImage'),
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final imageFile = File(_existingInsurance!.cropImage!);
              // Check if the file exists
              if (imageFile.existsSync()) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                );
              }
            }),
          ],
          
          const SizedBox(height: 20),
          
          if (_existingInsurance!.status != 'Claimed') ...[
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showClaimForm = true;
                      _claimReasonController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_late_outlined, color: Color(0xFF6A11CB)),
                        const SizedBox(width: 8),
                        Text(
                          getText('fileClaim'),
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A11CB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Show a disabled button if already claimed
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    getText('claimed'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          TextButton(
            onPressed: _clearInsuranceData,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Clear Data (Testing)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimForm(String Function(String) getText) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getText('fileClaim'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Claim reason
          _buildFormLabel(getText('claimReason')),
          TextFormField(
            controller: _claimReasonController,
            maxLines: 3,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: getText('enterClaimReason'),
              filled: true,
              fillColor: Colors.white.withAlpha(230),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return getText('requiredField');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 30),
          
          // Submit button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showClaimForm = false;
                      _claimReasonController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(getText('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () {
                    if (_formKey.currentState!.validate()) {
                      _submitClaim();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A11CB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          getText('submit'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceForm(String Function(String) getText) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getText('applyForInsurance'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Farmer name
          _buildFormLabel(getText('farmerName')),
          _buildFormField(
            controller: _farmerNameController,
            hintText: getText('enterName'),
            validator: (value) => value == null || value.trim().isEmpty 
                ? getText('requiredField') 
                : null,
          ),
          const SizedBox(height: 16),
          
          // Crop type
          _buildFormLabel(getText('cropType')),
          _buildDropdown(
            value: _selectedCropType,
            hint: getText('selectCropType'),
            items: _cropTypes.map((crop) {
              return DropdownMenuItem<String>(
                value: crop,
                child: Text(getText(crop)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCropType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Season
          _buildFormLabel(getText('season')),
          _buildDropdown(
            value: _selectedSeason,
            hint: getText('selectSeason'),
            items: _seasons.map((season) {
              return DropdownMenuItem<String>(
                value: season,
                child: Text(getText(season)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSeason = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Land area
          _buildFormLabel(getText('landArea')),
          _buildFormField(
            controller: _landAreaController,
            hintText: getText('enterLandArea'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return getText('requiredField');
              }
              if (double.tryParse(value) == null) {
                return getText('invalid_number');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Crop price
          _buildFormLabel(getText('cropPrice')),
          _buildFormField(
            controller: _cropPriceController,
            hintText: getText('enterCropPrice'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return getText('requiredField');
              }
              if (double.tryParse(value) == null) {
                return getText('invalid_number');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Crop image (optional)
          _buildFormLabel(getText('cropImage')),
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withAlpha(100),
                  width: 1,
                ),
              ),
              child: _cropImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _cropImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo,
                          color: Colors.grey,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getText('chooseFromGallery'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitInsuranceApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Text(
                      getText('apply'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white.withAlpha(230),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, overflow: TextOverflow.ellipsis),
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(color: Colors.black),
        dropdownColor: Colors.white,
        items: items,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppTranslations.getText(
              'requiredField',
              Provider.of<LanguageProvider>(context, listen: false).language,
            );
          }
          return null;
        },
      ),
    );
  }
} 