class Insurance {
  final String? id;
  final String farmerName;
  final String cropType;
  final String season;
  final double landArea;
  final double cropPrice;
  final String? cropImage;
  final String? claimReason;
  final String status;

  Insurance({
    this.id,
    required this.farmerName,
    required this.cropType,
    required this.season,
    required this.landArea,
    required this.cropPrice,
    this.cropImage,
    this.claimReason,
    this.status = 'Pending',
  });

  factory Insurance.fromJson(Map<String, dynamic> json) {
    // Handle various possible ID field names
    String? id = json['id'] ?? json['_id'];
    
    // Handle if ID is nested in an object (common in MongoDB responses)
    if (id == null && json['_id'] is Map) {
      // Access it as a string since we don't know the exact format
      id = json['_id'].toString();
    }
    
    // Handle landArea parsing
    dynamic landArea = json['landArea'];
    double parsedLandArea;
    
    if (landArea is String) {
      parsedLandArea = double.parse(landArea);
    } else if (landArea is int) {
      parsedLandArea = landArea.toDouble();
    } else {
      parsedLandArea = landArea?.toDouble() ?? 0.0;
    }
    
    // Handle cropPrice parsing
    dynamic cropPrice = json['cropPrice'];
    double parsedCropPrice;
    
    if (cropPrice is String) {
      parsedCropPrice = double.parse(cropPrice);
    } else if (cropPrice is int) {
      parsedCropPrice = cropPrice.toDouble();
    } else {
      parsedCropPrice = cropPrice?.toDouble() ?? 0.0;
    }
    
    return Insurance(
      id: id,
      farmerName: json['farmerName'] ?? '',
      cropType: json['cropType'] ?? '',
      season: json['season'] ?? '',
      landArea: parsedLandArea,
      cropPrice: parsedCropPrice,
      cropImage: json['cropImage'],
      claimReason: json['claimReason'],
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerName': farmerName,
      'cropType': cropType,
      'season': season,
      'landArea': landArea,
      'cropPrice': cropPrice,
      'cropImage': cropImage,
      'claimReason': claimReason,
      'status': status,
    };
  }
} 