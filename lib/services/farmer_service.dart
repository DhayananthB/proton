import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farmer_model.dart';

class FarmerService {
  static const String _farmerKey = 'farmer_data';

  // Save farmer data
  static Future<bool> saveFarmer(Farmer farmer) async {
    try {
      print('FarmerService.saveFarmer - Saving coordinates: ${farmer.latitude}, ${farmer.longitude}');
      
      final farmerJson = farmer.toJson();
      print('FarmerService.saveFarmer - JSON coordinates: ${farmerJson['latitude']}, ${farmerJson['longitude']}');
      
      final jsonString = jsonEncode(farmerJson);
      print('FarmerService.saveFarmer - Encoded JSON: $jsonString');
      
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_farmerKey, jsonString);
    } catch (e) {
      print('Error saving farmer data: $e');
      return false;
    }
  }

  // Get farmer data
  static Future<Farmer?> getFarmer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? farmerJson = prefs.getString(_farmerKey);
      
      print('FarmerService.getFarmer - Raw JSON from storage: $farmerJson');
      
      if (farmerJson != null && farmerJson.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(farmerJson);
        print('FarmerService.getFarmer - Decoded JSON: $jsonMap');
        print('FarmerService.getFarmer - JSON coordinates: ${jsonMap['latitude']}, ${jsonMap['longitude']}');
        
        return Farmer.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      print('Error getting farmer data: $e');
      return null;
    }
  }
}