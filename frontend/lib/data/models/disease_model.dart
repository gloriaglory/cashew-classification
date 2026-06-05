class DiseaseModel {
  final int id;
  final String diseaseName;
  final String description;
  final String symptoms;
  final String prevention;
  final String? createdAt;

  const DiseaseModel({
    required this.id,
    required this.diseaseName,
    required this.description,
    required this.symptoms,
    required this.prevention,
    this.createdAt,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) => DiseaseModel(
        id:          json['id'] as int? ?? 0,
        diseaseName: json['disease_name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        symptoms:    json['symptoms'] as String? ?? '',
        prevention:  json['prevention'] as String? ?? '',
        createdAt:   json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'disease_name': diseaseName,
        'description':  description,
        'symptoms':     symptoms,
        'prevention':   prevention,
      };
}
