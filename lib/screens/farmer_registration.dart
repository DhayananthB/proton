import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/language_provider.dart';
import '../models/farmer_model.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/farmer_service.dart';
import '../utils/translations.dart';

class FarmerRegistrationPage extends StatefulWidget {
  final Farmer? initialFarmer;

  const FarmerRegistrationPage({super.key, this.initialFarmer});

  @override
  State<FarmerRegistrationPage> createState() => _FarmerRegistrationPageState();
}

class _FarmerRegistrationPageState extends State<FarmerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  LocationData? _locationData;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedBlock;
  String? _selectedVillage;
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  Farmer? _existingFarmer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _locationData = await LocationService.getLocationData();
      
      // Request location permission and get coordinates automatically
      _getCurrentLocation();
      
      if (widget.initialFarmer != null) {
        _existingFarmer = widget.initialFarmer;

        _nameController.text = _existingFarmer!.name;
        _mobileController.text = _existingFarmer!.mobileNumber;
        _latitudeController.text = _existingFarmer!.latitude.toString();
        _longitudeController.text = _existingFarmer!.longitude.toString();

        // Initialize in the next frame to ensure language provider is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeLocationSelections();
        });
      } else {
        _existingFarmer = await FarmerService.getFarmer();

        if (_existingFarmer != null) {
          _nameController.text = _existingFarmer!.name;
          _mobileController.text = _existingFarmer!.mobileNumber;
          _latitudeController.text = _existingFarmer!.latitude.toString();
          _longitudeController.text = _existingFarmer!.longitude.toString();

          // Initialize in the next frame to ensure language provider is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeLocationSelections();
          });
        }
      }
    } catch (e) {
      // print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to get the current location using Geolocator
  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
      });
    }
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.getText(
                'locationServicesDisabled', 
                Provider.of<LanguageProvider>(context, listen: false).language
              )),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppTranslations.getText(
                  'locationPermissionDenied', 
                  Provider.of<LanguageProvider>(context, listen: false).language
                )),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.getText(
                'locationPermissionPermanentlyDenied', 
                Provider.of<LanguageProvider>(context, listen: false).language
              )),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15)
        )
      );
      
      // Update the text fields
      if (mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
          _isLoadingLocation = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.getText(
              'locationObtained', 
              Provider.of<LanguageProvider>(context, listen: false).language
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.getText(
              'locationError', 
              Provider.of<LanguageProvider>(context, listen: false).language
            )),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _initializeLocationSelections() {
    if (_existingFarmer == null || !mounted) return;

    final currentLanguage =
        Provider.of<LanguageProvider>(context, listen: false).language;

    // Find matching state in the current language context
    if (_locationData != null && _existingFarmer!.state.isNotEmpty) {
      final stateNames = LocationService.getStateNames(
        _locationData!,
        currentLanguage,
      );
      // Try to find a direct match first
      if (stateNames.contains(_existingFarmer!.state)) {
        _selectedState = _existingFarmer!.state;
      } else {
        // Look for a state that might match in the other language
        for (var state in _locationData!.states) {
          String stateName =
              currentLanguage == 'ta' ? state.taName : state.enName;
          String otherLangName =
              currentLanguage == 'ta' ? state.enName : state.taName;

          if (stateName == _existingFarmer!.state ||
              otherLangName == _existingFarmer!.state) {
            _selectedState = stateName;
            break;
          }
        }
      }
    }

    // Only proceed with district if state was found
    if (_selectedState != null && _existingFarmer!.district.isNotEmpty) {
      final districtNames = LocationService.getDistrictNames(
        _locationData!,
        _selectedState!,
        currentLanguage,
      );

      if (districtNames.contains(_existingFarmer!.district)) {
        _selectedDistrict = _existingFarmer!.district;
      } else {
        // Look for a matching district in the current language context
        StateData? state = _findStateByName(_selectedState!, currentLanguage);
        if (state?.districts != null) {
          for (var district in state!.districts!) {
            String districtName =
                currentLanguage == 'ta' ? district.taName : district.enName;
            String otherLangName =
                currentLanguage == 'ta' ? district.enName : district.taName;

            if (districtName == _existingFarmer!.district ||
                otherLangName == _existingFarmer!.district) {
              _selectedDistrict = districtName;
              break;
            }
          }
        }
      }
    }

    // Only proceed with block if district was found
    if (_selectedState != null &&
        _selectedDistrict != null &&
        _existingFarmer!.block.isNotEmpty) {
      final blockNames = LocationService.getBlockNames(
        _locationData!,
        _selectedState!,
        _selectedDistrict!,
        currentLanguage,
      );

      if (blockNames.contains(_existingFarmer!.block)) {
        _selectedBlock = _existingFarmer!.block;
      } else {
        // Look for a matching block in the current language context
        DistrictData? district = _findDistrictByName(
          _selectedState!,
          _selectedDistrict!,
          currentLanguage,
        );
        if (district?.blocks != null) {
          for (var block in district!.blocks!) {
            String blockName =
                currentLanguage == 'ta' ? block.taName : block.enName;
            String otherLangName =
                currentLanguage == 'ta' ? block.enName : block.taName;

            if (blockName == _existingFarmer!.block ||
                otherLangName == _existingFarmer!.block) {
              _selectedBlock = blockName;
              break;
            }
          }
        }
      }
    }

    // Only proceed with village if block was found
    if (_selectedState != null &&
        _selectedDistrict != null &&
        _selectedBlock != null &&
        _existingFarmer!.village.isNotEmpty) {
      final villageNames = LocationService.getVillageNames(
        _locationData!,
        _selectedState!,
        _selectedDistrict!,
        _selectedBlock!,
        currentLanguage,
      );

      if (villageNames.contains(_existingFarmer!.village)) {
        _selectedVillage = _existingFarmer!.village;
      } else {
        // Look for a matching village in the current language context
        BlockData? block = _findBlockByName(
          _selectedState!,
          _selectedDistrict!,
          _selectedBlock!,
          currentLanguage,
        );
        if (block?.villages != null) {
          for (var village in block!.villages!) {
            String villageName =
                currentLanguage == 'ta' ? village.taName : village.enName;
            String otherLangName =
                currentLanguage == 'ta' ? village.enName : village.taName;

            if (villageName == _existingFarmer!.village ||
                otherLangName == _existingFarmer!.village) {
              _selectedVillage = villageName;
              break;
            }
          }
        }
      }
    }

    // Update UI with the found values
    if (mounted) {
      setState(() {});
    }
  }

  StateData? _findStateByName(String stateName, String language) {
    if (_locationData == null) return null;

    try {
      return _locationData!.states.firstWhere(
        (s) => language == 'ta' ? s.taName == stateName : s.enName == stateName,
      );
    } catch (e) {
      return null;
    }
  }

  DistrictData? _findDistrictByName(
    String stateName,
    String districtName,
    String language,
  ) {
    StateData? state = _findStateByName(stateName, language);
    if (state?.districts == null) return null;

    try {
      return state!.districts!.firstWhere(
        (d) =>
            language == 'ta'
                ? d.taName == districtName
                : d.enName == districtName,
      );
    } catch (e) {
      return null;
    }
  }

  BlockData? _findBlockByName(
    String stateName,
    String districtName,
    String blockName,
    String language,
  ) {
    DistrictData? district = _findDistrictByName(
      stateName,
      districtName,
      language,
    );
    if (district?.blocks == null) return null;

    try {
      return district!.blocks!.firstWhere(
        (b) => language == 'ta' ? b.taName == blockName : b.enName == blockName,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Text(
                                  getText('farmerRegistration'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormLabel(getText('name')),
                                  _buildFormField(
                                    controller: _nameController,
                                    hintText: getText('enterName'),
                                    validator:
                                        (value) =>
                                            value == null ||
                                                    value.trim().isEmpty
                                                ? getText('requiredField')
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildFormLabel(getText('mobileNumber')),
                                  _buildFormField(
                                    controller: _mobileController,
                                    hintText: getText('enterMobile'),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return getText('requiredField');
                                      }
                                      if (value.length != 10) {
                                        return getText('invalidMobile');
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Farmland location coordinates
                                  _buildFormLabel(getText('farmlandLocation')),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: Text(
                                                  '${getText('latitude')}: ${_latitudeController.text}\n${getText('longitude')}: ${_longitudeController.text}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            // Hidden form fields for validation
                                            Opacity(
                                              opacity: 0,
                                              child: SizedBox(
                                                height: 0,
                                                child: TextFormField(
                                                  controller: _latitudeController,
                                                  validator: (value) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return getText('requiredField');
                                                    }
                                                    final latitude = double.tryParse(value);
                                                    if (latitude == null) {
                                                      return getText('invalidLatitude');
                                                    }
                                                    if (latitude < -90 || latitude > 90) {
                                                      return getText('latitudeRange');
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ),
                                            Opacity(
                                              opacity: 0,
                                              child: SizedBox(
                                                height: 0,
                                                child: TextFormField(
                                                  controller: _longitudeController,
                                                  validator: (value) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return getText('requiredField');
                                                    }
                                                    final longitude = double.tryParse(value);
                                                    if (longitude == null) {
                                                      return getText('invalidLongitude');
                                                    }
                                                    if (longitude < -180 || longitude > 180) {
                                                      return getText('longitudeRange');
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.my_location, size: 20),
                                        label: Text(getText('updateLocation')),
                                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF6A11CB),
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        
                                      ),
                                    ],
                                  ),
                                  if (_isLoadingLocation)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            getText('gettingLocation'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),

                                  _buildFormLabel(getText('state')),
                                  _buildDropdown(
                                    value: _selectedState,
                                    hint: getText('selectState'),
                                    items: _getStateItems(currentLanguage),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedState = value;
                                        _selectedDistrict = null;
                                        _selectedBlock = null;
                                        _selectedVillage = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  if (_selectedState != null) ...[
                                    _buildFormLabel(getText('district')),
                                    _buildDropdown(
                                      value: _selectedDistrict,
                                      hint: getText('selectDistrict'),
                                      items: _getDistrictItems(currentLanguage),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDistrict = value;
                                          _selectedBlock = null;
                                          _selectedVillage = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  if (_selectedState != null &&
                                      _selectedDistrict != null) ...[
                                    _buildFormLabel(getText('block')),
                                    _buildDropdown(
                                      value: _selectedBlock,
                                      hint: getText('selectBlock'),
                                      items: _getBlockItems(currentLanguage),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBlock = value;
                                          _selectedVillage = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  if (_selectedState != null &&
                                      _selectedDistrict != null &&
                                      _selectedBlock != null) ...[
                                    _buildFormLabel(getText('village')),
                                    _buildDropdown(
                                      value: _selectedVillage,
                                      hint: getText('selectVillage'),
                                      items: _getVillageItems(currentLanguage),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedVillage = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  const SizedBox(height: 24),
                                  _buildSaveButton(currentLanguage),
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
    );
  }

  // Helper method to create state dropdown items
  List<DropdownMenuItem<String>> _getStateItems(String currentLanguage) {
    if (_locationData == null || _locationData!.states.isEmpty) {
      return [];
    }

    final stateNames = LocationService.getStateNames(
      _locationData!,
      currentLanguage,
    );

    return stateNames.map((stateName) {
      return DropdownMenuItem<String>(value: stateName, child: Text(stateName));
    }).toList();
  }

  // Helper method to create district dropdown items
  List<DropdownMenuItem<String>> _getDistrictItems(String currentLanguage) {
    if (_locationData == null || _selectedState == null) {
      return [];
    }

    final districts = LocationService.getDistrictNames(
      _locationData!,
      _selectedState!,
      currentLanguage,
    );

    return districts.map((district) {
      return DropdownMenuItem<String>(value: district, child: Text(district));
    }).toList();
  }

  // Helper method to create block dropdown items
  List<DropdownMenuItem<String>> _getBlockItems(String currentLanguage) {
    if (_locationData == null ||
        _selectedState == null ||
        _selectedDistrict == null) {
      return [];
    }

    final blocks = LocationService.getBlockNames(
      _locationData!,
      _selectedState!,
      _selectedDistrict!,
      currentLanguage,
    );

    return blocks.map((block) {
      return DropdownMenuItem<String>(value: block, child: Text(block));
    }).toList();
  }

  // Helper method to create village dropdown items
  List<DropdownMenuItem<String>> _getVillageItems(String currentLanguage) {
    if (_locationData == null ||
        _selectedState == null ||
        _selectedDistrict == null ||
        _selectedBlock == null) {
      return [];
    }

    final villages = LocationService.getVillageNames(
      _locationData!,
      _selectedState!,
      _selectedDistrict!,
      _selectedBlock!,
      currentLanguage,
    );

    return villages.map((village) {
      return DropdownMenuItem<String>(value: village, child: Text(village));
    }).toList();
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
        fillColor: Colors.white.withAlpha(230), // Changed from withOpacity(0.9)
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
        color: Colors.white.withAlpha(230), // Changed from withOpacity(0.9)
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
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

  Widget _buildSaveButton(String currentLanguage) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveFarmerData(currentLanguage),
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
          AppTranslations.getText('save', currentLanguage),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveFarmerData(String currentLanguage) async {
    if (_formKey.currentState!.validate() &&
        _selectedState != null &&
        _selectedDistrict != null &&
        _selectedBlock != null &&
        _selectedVillage != null) {
      
      try {
        final latitude = double.parse(_latitudeController.text);
        final longitude = double.parse(_longitudeController.text);
        
        // Validate coordinate ranges
        if (latitude < -90 || latitude > 90) {
          throw Exception('Latitude must be between -90 and 90');
        }
        if (longitude < -180 || longitude > 180) {
          throw Exception('Longitude must be between -180 and 180');
        }
        
        print('Saving farmer with coordinates: $latitude, $longitude');
        
        final Farmer farmer = Farmer(
          name: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          state: _selectedState!,
          district: _selectedDistrict!,
          block: _selectedBlock!,
          village: _selectedVillage!,
          language: currentLanguage,
          latitude: latitude,
          longitude: longitude,
        );

        bool saved = await FarmerService.saveFarmer(farmer);

        if (saved && mounted) {
          print('Farmer data saved successfully with coordinates: $latitude, $longitude');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _existingFarmer != null
                    ? AppTranslations.getText('profileUpdated', currentLanguage)
                    : AppTranslations.getText(
                      'savedSuccessfully',
                      currentLanguage,
                    ),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.getText('errorSaving', currentLanguage),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error saving farmer data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
