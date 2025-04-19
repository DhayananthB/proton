import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farmer_model.dart';

class FarmerService {
  static const String _farmerKey = 'farmer_data';

  // Save farmer data
  static Future<bool> saveFarmer(Farmer farmer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_farmerKey, jsonEncode(farmer.toJson()));
    } catch (e) {
      // print('Error saving farmer data: $e');
      return false;
    }
  }

  // Get farmer data
  static Future<Farmer?> getFarmer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? farmerJson = prefs.getString(_farmerKey);
      
      if (farmerJson != null && farmerJson.isNotEmpty) {
        return Farmer.fromJson(jsonDecode(farmerJson));
      }
      return null;
    } catch (e) {
      // print('Error getting farmer data: $e');
      return null;
    }
  }
}