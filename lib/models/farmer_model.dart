class Farmer {
  final String name;
  final String mobileNumber;
  final String state;
  final String district;
  final String block;
  final String village;
  final String language;

  Farmer({
    required this.name,
    required this.mobileNumber,
    required this.state,
    required this.district,
    required this.block,
    required this.village,
    required this.language,
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
      };

  // Create Farmer from Map (from SharedPreferences)
  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      block: json['block'] ?? '',
      village: json['village'] ?? '',
      language: json['language'] ?? 'en',
    );
  }
}