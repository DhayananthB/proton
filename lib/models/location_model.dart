class LocationData {
  final List<StateData> states;

  LocationData({required this.states});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    List<StateData> statesList = [];
    if (json['states'] != null) {
      statesList = List<StateData>.from(
          json['states'].map((state) => StateData.fromJson(state)));
    }
    return LocationData(states: statesList);
  }
}

class StateData {
  final String enName;
  final String taName;
  final List<DistrictData>? districts;

  StateData({required this.enName, required this.taName, this.districts});

  factory StateData.fromJson(Map<String, dynamic> json) {
    List<DistrictData>? districtsList;
    if (json['districts'] != null) {
      districtsList = List<DistrictData>.from(
          json['districts'].map((district) => DistrictData.fromJson(district)));
    }
    return StateData(
      enName: json['en'] ?? '',
      taName: json['ta'] ?? '',
      districts: districtsList,
    );
  }
}

class DistrictData {
  final String enName;
  final String taName;
  final List<BlockData>? blocks;

  DistrictData({required this.enName, required this.taName, this.blocks});

  factory DistrictData.fromJson(Map<String, dynamic> json) {
    List<BlockData>? blocksList;
    if (json['blocks'] != null) {
      blocksList = List<BlockData>.from(
          json['blocks'].map((block) => BlockData.fromJson(block)));
    }
    return DistrictData(
      enName: json['en'] ?? '',
      taName: json['ta'] ?? '',
      blocks: blocksList,
    );
  }
}

class BlockData {
  final String enName;
  final String taName;
  final List<VillageData>? villages;

  BlockData({required this.enName, required this.taName, this.villages});

  factory BlockData.fromJson(Map<String, dynamic> json) {
    List<VillageData>? villagesList;
    if (json['villages'] != null) {
      villagesList = List<VillageData>.from(
          json['villages'].map((village) => VillageData.fromJson(village)));
    }
    return BlockData(
      enName: json['en'] ?? '',
      taName: json['ta'] ?? '',
      villages: villagesList,
    );
  }
}

class VillageData {
  final String enName;
  final String taName;

  VillageData({required this.enName, required this.taName});

  factory VillageData.fromJson(Map<String, dynamic> json) {
    return VillageData(
      enName: json['en'] ?? '',
      taName: json['ta'] ?? '',
    );
  }
}