class Farmer {
  final String name;
  final String mobileNumber;
  final String state;
  final String district;
  final String block;
  final String village;
  final String language;
  final double latitude;
  final double longitude;

  Farmer({
    required this.name,
    required this.mobileNumber,
    required this.state,
    required this.district,
    required this.block,
    required this.village,
    required this.language,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  // Convert to Map for storing in SharedPreferences
  Map<String, dynamic> toJson() => {
        'name': name,
        'mobileNumber': mobileNumber,
        'state': state,
        'district': district,
        'block': block,
        'village': village,
        'language': language,
        'latitude': latitude,
        'longitude': longitude,
      };

  // Create Farmer from Map (from SharedPreferences)
  factory Farmer.fromJson(Map<String, dynamic> json) {
    final latValue = json['latitude'];
    final lonValue = json['longitude'];
    
    // Debug prints to verify coordinate values and types
    print('Farmer fromJson - Raw latitude: $latValue (${latValue.runtimeType})');
    print('Farmer fromJson - Raw longitude: $lonValue (${lonValue.runtimeType})');
    
    // Convert coordinates to double safely
    double latitude;
    double longitude;
    
    try {
      latitude = latValue?.toDouble() ?? 0.0;
      longitude = lonValue?.toDouble() ?? 0.0;
      print('Farmer fromJson - Parsed coordinates: $latitude, $longitude');
    } catch (e) {
      print('Farmer fromJson - Error parsing coordinates: $e');
      latitude = 0.0;
      longitude = 0.0;
    }
    
    return Farmer(
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      block: json['block'] ?? '',
      village: json['village'] ?? '',
      language: json['language'] ?? 'en',
      latitude: latitude,
      longitude: longitude,
    );
  }
}