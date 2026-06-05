import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _analyzing = false;
  final _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == 'gallery' && _selectedImage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromGallery());
    }
  }

  Future<void> _pickFromCamera() async {
    final xf = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1024);
    if (xf != null) setState(() => _selectedImage = File(xf.path));
  }

  Future<void> _pickFromGallery() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (xf != null) setState(() => _selectedImage = File(xf.path));
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _analyzing = true);
    try {
      final res = await ApiService().predict(_selectedImage!);
      if (!mounted) return;
      if (res['success'] == true) {
        final result = Map<String, dynamic>.from(res['result'] as Map<String, dynamic>);
        result['image_path'] = _selectedImage!.path;
        Navigator.pushNamed(context, '/result', arguments: result);
      } else {
        _showError(res['message'] as String? ?? 'Analysis failed.');
      }
    } on DioException catch (e) {
      if (mounted) _showError(e.response?.data?['message'] as String? ?? 'Analysis failed. Check connection.');
    } catch (e) {
      if (mounted) _showError('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _analyzing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan Cashew Leaf')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(child: _buildImageArea()),
                  const SizedBox(height: 24),
                  _buildSourceButtons(),
                  const SizedBox(height: 16),
                  if (_selectedImage != null) ...[
                    AppButton(
                      label: 'Analyze with AI',
                      onPressed: _analyzeImage,
                      isLoading: _analyzing,
                      icon: Icons.biotech_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text('Clear Image', style: TextStyle(color: AppColors.textLight)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(_selectedImage!, fit: BoxFit.cover),
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.healthy, size: 16),
                    SizedBox(width: 6),
                    Text('Ready to analyze', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No image selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Take a photo or upload from gallery\nto detect cashew leaf diseases',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_rounded, size: 14, color: AppColors.secondary),
                SizedBox(width: 6),
                Text('AI powered by CashewCare server',
                    style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(label: 'Camera', icon: Icons.camera_alt_rounded, color: AppColors.primary, onTap: _pickFromCamera),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SourceButton(label: 'Gallery', icon: Icons.photo_library_rounded, color: AppColors.secondary, onTap: _pickFromGallery),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
