import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/insurance_model.dart';

class InsuranceService {
  // We'll use both remote API and local storage
  static const String localStorageKey = 'insurance_data';
  
  // Updated API URL
  static const String baseUrl = 'https://proton-insurance-1.onrender.com';

  // Apply for insurance with MongoDB API and local fallback
  static Future<Insurance> applyForInsurance({
    required String farmerName,
    required String cropType,
    required String season,
    required double landArea,
    required double cropPrice,
    File? cropImage,
  }) async {
    try {
      // First, create a new insurance object
      final insurance = Insurance(
        id: 'INS${DateTime.now().millisecondsSinceEpoch}',
        farmerName: farmerName,
        cropType: cropType,
        season: season,
        landArea: landArea,
        cropPrice: cropPrice,
        cropImage: cropImage?.path,
        status: 'Pending',
      );
      
      // Save locally first as a backup
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(insurance.toJson());
      await prefs.setString(localStorageKey, jsonData);

      // Try to connect to MongoDB API
      try {
        // Using the endpoint: /insurance/apply
        final apiUrl = '$baseUrl/insurance/apply';
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
        
        // Add text fields
        request.fields['farmerName'] = farmerName;
        request.fields['cropType'] = cropType;
        request.fields['season'] = season;
        request.fields['landArea'] = landArea.toString();
        request.fields['cropPrice'] = cropPrice.toString();
        
        // Add image if available
        if (cropImage != null) {
          final fileType = cropImage.path.split('.').last.toLowerCase();
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'cropImage',
              cropImage.path,
              contentType: MediaType('image', fileType),
            ),
          );
        }
        
        // Set timeout to handle slow connections
        final response = await request.send().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );
        
        final responseData = await response.stream.bytesToString();
        
        // Try to parse the response as JSON
        try {
          final jsonResponse = json.decode(responseData);
          
          if (response.statusCode == 201) {
            // Create a new insurance object with server-generated ID
            final serverInsurance = Insurance(
              id: jsonResponse['application']['_id'] ?? insurance.id,
              farmerName: farmerName,
              cropType: cropType, 
              season: season,
              landArea: landArea,
              cropPrice: cropPrice,
              cropImage: cropImage?.path,
              status: 'Pending',
            );
            
            // Update local storage with server ID
            await prefs.setString(localStorageKey, jsonEncode(serverInsurance.toJson()));
            return serverInsurance;
          } else {
            return insurance; // Return locally stored insurance as fallback
          }
        } catch (jsonError) {
          return insurance; // Return locally stored insurance as fallback
        }
      } catch (apiError) {
        // Return the local insurance object if API fails
        return insurance;
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  // Get insurance data from local storage only (no API endpoint for fetching applications)
  static Future<Insurance?> getInsurance({bool forceApiRefresh = false}) async {
    try {
      // Only retrieve from local storage as there's no API endpoint to get applications
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString(localStorageKey);
      
      if (localData != null && localData.isNotEmpty) {
        final localInsurance = Insurance.fromJson(jsonDecode(localData));
        return localInsurance;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // File claim with MongoDB API and local fallback
  static Future<Insurance> fileClaim({
    required String insuranceId,
    required String claimReason,
  }) async {
    try {
      // Validate inputs
      if (insuranceId.isEmpty) {
        throw Exception('Invalid insurance ID');
      }
      
      if (claimReason.isEmpty) {
        throw Exception('Claim reason is required');
      }
      
      // First update locally for immediate feedback
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(localStorageKey);
      
      if (jsonData == null || jsonData.isEmpty) {
        throw Exception('No insurance data found');
      }
      
      // Update local data first for immediate UI feedback
      final Map<String, dynamic> data = jsonDecode(jsonData);
      data['claimReason'] = claimReason;
      data['status'] = 'Claimed';
      
      // Save updated data locally
      await prefs.setString(localStorageKey, jsonEncode(data));
      
      final localInsurance = Insurance.fromJson(data);
      
      // Try to submit to API if we have a MongoDB ID (not a local ID)
      if (!insuranceId.startsWith('INS')) {
        try {
          // Using the endpoint: /insurance/claim/:id
          final apiUrl = '$baseUrl/insurance/claim/$insuranceId';
          
          // Prepare the request body
          final requestBody = jsonEncode({
            'claimReason': claimReason
          });
          
          // Send the API request
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          ).timeout(
            const Duration(seconds: 20), // Extended timeout for slow servers
            onTimeout: () {
              throw TimeoutException('Connection timeout while claiming');
            },
          );
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            try {
              final jsonResponse = jsonDecode(response.body);
              
              // Check if there's updated data in the response
              if (jsonResponse['updated'] != null) {
                final serverUpdated = Insurance.fromJson(jsonResponse['updated']);
                await prefs.setString(localStorageKey, jsonEncode(serverUpdated.toJson()));
                return serverUpdated;
              }
              
              // If no updated data in response, just return our local data
              return localInsurance;
            } catch (jsonError) {
              // Continue with local data if JSON parsing fails
              return localInsurance;
            }
          } else if (response.statusCode == 404) {
            throw Exception('Insurance application not found on server');
          } else {
            try {
              final jsonResponse = jsonDecode(response.body);
              final errorMessage = jsonResponse['message'] ?? 'Unknown server error';
              throw Exception('Server error: $errorMessage');
            } catch (e) {
              throw Exception('Failed to process server response');
            }
          }
        } catch (apiError) {
          // If this is a specific error we've thrown, rethrow it
          if (apiError is Exception) {
            rethrow;
          }
          // For network errors, fallback to local data
          return localInsurance;
        }
      } else {
        return localInsurance;
      }
    } catch (e) {
      throw Exception('Error filing claim: $e');
    }
  }
  
  // Clear insurance data (for testing)
  static Future<bool> clearInsuranceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(localStorageKey);
    } catch (e) {
      return false;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
} 