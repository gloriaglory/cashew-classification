class PesticideModel {
  final int id;
  final int? diseaseId;
  final String diseaseName;
  final String pesticideName;
  final String dosage;
  final String applicationMethod;
  final String recommendation;
  final String? createdAt;

  const PesticideModel({
    required this.id,
    this.diseaseId,
    required this.diseaseName,
    required this.pesticideName,
    required this.dosage,
    required this.applicationMethod,
    required this.recommendation,
    this.createdAt,
  });

  factory PesticideModel.fromJson(Map<String, dynamic> json) => PesticideModel(
        id:                json['id'] as int? ?? 0,
        diseaseId:         json['disease_id'] as int?,
        diseaseName:       json['disease_name'] as String? ?? '',
        pesticideName:     json['pesticide_name'] as String? ?? '',
        dosage:            json['dosage'] as String? ?? '',
        applicationMethod: json['application_method'] as String? ?? '',
        recommendation:    json['recommendation'] as String? ?? '',
        createdAt:         json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'disease_id':         diseaseId,
        'pesticide_name':     pesticideName,
        'dosage':             dosage,
        'application_method': applicationMethod,
        'recommendation':     recommendation,
      };
}
