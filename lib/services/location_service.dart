import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/location_model.dart';

class LocationService {
  static LocationData? _locationData;
  
  static Future<LocationData> getLocationData() async {
    if (_locationData != null) {
      return _locationData!;
    }
    // Load from assets
    String jsonString = await rootBundle.loadString('assets/location_data.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);
    _locationData = LocationData.fromJson(jsonData);
    return _locationData!;
  }
  
  static List<String> getStateNames(LocationData locationData, String language) {
    return locationData.states.map((state) =>
      language == 'ta' ? state.taName : state.enName
    ).toList();
  }
  
  static List<String> getDistrictNames(
    LocationData locationData,
    String selectedState,
    String language,
  ) {
    StateData state = locationData.states.firstWhere(
      (s) => language == 'ta' ? s.taName == selectedState : s.enName == selectedState,
      orElse: () => StateData(enName: '', taName: ''),
    );
   
    if (state.districts == null) return [];
   
    final List<String> districts = state.districts!.map((district) =>
      language == 'ta' ? district.taName : district.enName
    ).toList();
    
    final Set<String> uniqueDistricts = districts.toSet();
    
    return uniqueDistricts.toList();
  }
  
  static List<String> getBlockNames(
    LocationData locationData,
    String selectedState,
    String selectedDistrict,
    String language,
  ) {
    StateData state = locationData.states.firstWhere(
      (s) => language == 'ta' ? s.taName == selectedState : s.enName == selectedState,
      orElse: () => StateData(enName: '', taName: ''),
    );
   
    if (state.districts == null) return [];
   
    DistrictData district = state.districts!.firstWhere(
      (d) => language == 'ta' ? d.taName == selectedDistrict : d.enName == selectedDistrict,
      orElse: () => DistrictData(enName: '', taName: ''),
    );
   
    if (district.blocks == null) return [];
   
    final List<String> blocks = district.blocks!.map((block) =>
      language == 'ta' ? block.taName : block.enName
    ).toList();
    
    final Set<String> uniqueBlocks = blocks.toSet();
    
    return uniqueBlocks.toList();
  }
  
  static List<String> getVillageNames(
    LocationData locationData,
    String selectedState,
    String selectedDistrict,
    String selectedBlock,
    String language,
  ) {
    StateData state = locationData.states.firstWhere(
      (s) => language == 'ta' ? s.taName == selectedState : s.enName == selectedState,
      orElse: () => StateData(enName: '', taName: ''),
    );
   
    if (state.districts == null) return [];
   
    DistrictData district = state.districts!.firstWhere(
      (d) => language == 'ta' ? d.taName == selectedDistrict : d.enName == selectedDistrict,
      orElse: () => DistrictData(enName: '', taName: ''),
    );
   
    if (district.blocks == null) return [];
   
    BlockData block = district.blocks!.firstWhere(
      (b) => language == 'ta' ? b.taName == selectedBlock : b.enName == selectedBlock,
      orElse: () => BlockData(enName: '', taName: ''),
    );
   
    if (block.villages == null) return [];
   
    final List<String> villages = block.villages!.map((village) =>
      language == 'ta' ? village.taName : village.enName
    ).toList();
    
    final Set<String> uniqueVillages = villages.toSet();
    
    return uniqueVillages.toList();
  }
}