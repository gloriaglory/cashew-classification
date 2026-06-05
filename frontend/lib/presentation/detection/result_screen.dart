import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const ResultScreen({super.key, required this.result});

  bool get _isHealthy => result['is_healthy'] as bool? ?? false;
  String get _diseaseName => result['disease_name'] as String? ?? 'Unknown';
  double get _confidence => (result['confidence'] as num?)?.toDouble() ?? 0.0;

  void _share(BuildContext context) {
    final text = '''
Cashew AI App – Detection Result
━━━━━━━━━━━━━━━━━━━━
Disease: $_diseaseName
Confidence: ${_confidence.toStringAsFixed(1)}%
Status: ${_isHealthy ? 'Healthy ✅' : 'Disease Detected ⚠️'}

Symptoms:
${result['symptoms'] ?? ''}

Pesticide: ${result['pesticide_name'] ?? 'N/A'}
Frequency: ${result['dosage'] ?? 'N/A'}
Best Time: ${result['application_method'] ?? 'N/A'}

Prevention:
${result['prevention'] ?? ''}

Detected on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}
━━━━━━━━━━━━━━━━━━━━
Powered by CashewCare AI Server
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detection Result'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => _share(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildImage(),
            const SizedBox(height: 16),
            _buildDiseaseInfo(),
            const SizedBox(height: 12),
            if (!_isHealthy) ...[
              _buildPesticideInfo(),
              const SizedBox(height: 12),
            ],
            _buildPrevention(),
            const SizedBox(height: 12),
            _buildTimestamp(),
            const SizedBox(height: 24),
            _buildActions(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _isHealthy ? AppColors.healthy : AppColors.diseased;
    final icon  = _isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final label = _isHealthy ? 'Leaf is Healthy' : 'Disease Detected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text(_diseaseName,
                    style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ConfidenceBadge(confidence: _confidence),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final localPath = result['image_path'] as String?;
    if (localPath == null || localPath.isEmpty) return const SizedBox.shrink();
    final file = File(localPath);
    if (!file.existsSync()) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(file, height: 220, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildDiseaseInfo() {
    return SectionCard(
      title: 'Disease Information',
      titleIcon: Icons.info_outline_rounded,
      titleColor: _isHealthy ? AppColors.healthy : AppColors.diseased,
      children: [
        if ((result['description'] as String?)?.isNotEmpty == true)
          InfoRow(icon: Icons.description_outlined, title: 'Description', content: result['description'] as String),
        if ((result['symptoms'] as String?)?.isNotEmpty == true && !_isHealthy)
          InfoRow(icon: Icons.medical_information_outlined, title: 'Symptoms', content: result['symptoms'] as String, iconColor: AppColors.diseased),
      ],
    );
  }

  Widget _buildPesticideInfo() {
    return SectionCard(
      title: 'Pesticide Recommendation',
      titleIcon: Icons.science_outlined,
      titleColor: AppColors.accent,
      children: [
        if ((result['pesticide_name'] as String?)?.isNotEmpty == true)
          InfoRow(icon: Icons.local_pharmacy_outlined, title: 'Pesticide', content: result['pesticide_name'] as String, iconColor: AppColors.accent),
        if ((result['dosage'] as String?)?.isNotEmpty == true)
          InfoRow(icon: Icons.medication_outlined, title: 'Frequency', content: result['dosage'] as String, iconColor: AppColors.primary),
        if ((result['application_method'] as String?)?.isNotEmpty == true)
          InfoRow(icon: Icons.access_time_outlined, title: 'Best Time', content: result['application_method'] as String, iconColor: AppColors.secondary),
        if ((result['recommendation'] as String?)?.isNotEmpty == true)
          InfoRow(icon: Icons.recommend_outlined, title: 'All Options', content: result['recommendation'] as String),
      ],
    );
  }

  Widget _buildPrevention() {
    final prevention = result['prevention'] as String?;
    if (prevention == null || prevention.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Prevention Measures',
      titleIcon: Icons.shield_outlined,
      titleColor: AppColors.secondary,
      children: [
        InfoRow(icon: Icons.verified_outlined, title: 'How to Prevent', content: prevention, iconColor: AppColors.secondary),
      ],
    );
  }

  Widget _buildTimestamp() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.cloud_rounded, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'CashewCare AI  •  ${DateFormat('dd MMM yyyy  •  hh:mm a').format(DateTime.now())}',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Scan Again',
          onPressed: () => Navigator.pushReplacementNamed(context, '/scan'),
          icon: Icons.camera_alt_rounded,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Back to Dashboard'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
