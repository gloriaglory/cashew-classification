class DetectionModel {
  final int id;
  final String imagePath;
  final double confidenceScore;
  final bool isHealthy;
  final String diseaseName;
  final String? description;
  final String? symptoms;
  final String? prevention;
  final String? pesticideName;
  final String? dosage;
  final String? applicationMethod;
  final String? recommendation;
  final String? pesticideRecommended;
  final String detectionDate;

  const DetectionModel({
    required this.id,
    required this.imagePath,
    required this.confidenceScore,
    required this.isHealthy,
    required this.diseaseName,
    this.description,
    this.symptoms,
    this.prevention,
    this.pesticideName,
    this.dosage,
    this.applicationMethod,
    this.recommendation,
    this.pesticideRecommended,
    required this.detectionDate,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) => DetectionModel(
        id:                   json['id'] as int? ?? 0,
        imagePath:            json['image_path'] as String? ?? '',
        confidenceScore:      (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
        isHealthy:            json['is_healthy'] == true || json['is_healthy'] == 1,
        diseaseName:          json['disease_name'] as String? ?? 'Unknown',
        description:          json['description'] as String?,
        symptoms:             json['symptoms'] as String?,
        prevention:           json['prevention'] as String?,
        pesticideName:        json['pesticide_name'] as String?,
        dosage:               json['dosage'] as String?,
        applicationMethod:    json['application_method'] as String?,
        recommendation:       json['recommendation'] as String?,
        pesticideRecommended: json['pesticide_recommended'] as String?,
        detectionDate:        json['detection_date'] as String? ?? '',
      );

  factory DetectionModel.fromPrediction(Map<String, dynamic> json) => DetectionModel(
        id:                   json['detection_id'] as int? ?? 0,
        imagePath:            json['image_url'] as String? ?? '',
        confidenceScore:      (json['confidence'] as num?)?.toDouble() ?? 0.0,
        isHealthy:            json['is_healthy'] as bool? ?? false,
        diseaseName:          json['disease_name'] as String? ?? 'Unknown',
        description:          json['description'] as String?,
        symptoms:             json['symptoms'] as String?,
        prevention:           json['prevention'] as String?,
        pesticideName:        json['pesticide_name'] as String?,
        dosage:               json['dosage'] as String?,
        applicationMethod:    json['application_method'] as String?,
        recommendation:       json['recommendation'] as String?,
        pesticideRecommended: json['pesticide_name'] as String?,
        detectionDate:        DateTime.now().toIso8601String(),
      );
}
