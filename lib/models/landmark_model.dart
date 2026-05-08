class LandmarkModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String category;
  final String? address;

  LandmarkModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
    this.address,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) {
    return LandmarkModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category']?.toString() ?? 'landmark',
      address: json['address']?.toString(),
    );
  }

  String get colorHex {
    switch (category) {
      case 'hospital': return '#F44336';
      case 'school': return '#42A5F5';
      case 'church': return '#BA68C8';
      case 'gov': return '#90A4AE';
      case 'terminal': return '#FF9800';
      case 'airport': return '#00BCD4';
      case 'mall': return '#E91E63';
      case 'bank': return '#66BB6A';
      case 'market': return '#FF7043';
      case 'park': return '#8BC34A';
      default: return '#9575CD';
    }
  }
}
