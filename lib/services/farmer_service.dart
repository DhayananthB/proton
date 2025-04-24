import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farmer_model.dart';

class FarmerService {
  static const String _farmerKey = 'farmer_data';

  // Save farmer data
  static Future<bool> saveFarmer(Farmer farmer) async {
    try {
      final farmerJson = farmer.toJson();
      final jsonString = jsonEncode(farmerJson);
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_farmerKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  // Get farmer data
  static Future<Farmer?> getFarmer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? farmerJson = prefs.getString(_farmerKey);
      
      if (farmerJson != null && farmerJson.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(farmerJson);
        return Farmer.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}