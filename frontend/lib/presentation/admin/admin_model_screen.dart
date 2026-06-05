import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminModelScreen extends StatefulWidget {
  const AdminModelScreen({super.key});
  @override
  State<AdminModelScreen> createState() => _AdminModelScreenState();
}

class _AdminModelScreenState extends State<AdminModelScreen> {
  String? _active;
  String? _selected;
  List<String> _classes = [];
  bool _loading = true;
  bool _saving  = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _message = null; });
    try {
      final res = await ApiService().getActiveModel();
      if (mounted && res['success'] == true) {
        setState(() {
          _active   = res['active_model'] as String?;
          _selected = _active;
          _classes  = List<String>.from(res['classes'] as List? ?? []);
          _loading  = false;
        });
      }
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    if (_selected == null || _selected == _active) return;
    setState(() { _saving = true; _message = null; });
    try {
      final res = await ApiService().switchModel(_selected!);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _active  = _selected;
          _message = 'Switched to ${_selected!.toUpperCase()} model successfully.';
          _messageIsError = false;
        });
        await _load();
      } else {
        setState(() {
          _message = res['message'] as String? ?? 'Switch failed.';
          _messageIsError = true;
        });
      }
    } on DioException catch (e) {
      if (mounted) setState(() {
        _message = e.response?.data?['message'] as String? ?? 'Switch failed. Check connection.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Config'),
        backgroundColor: AppColors.accent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActiveCard(),
                    const SizedBox(height: 16),
                    if (_message != null) _buildMessage(),
                    _buildSelectCard(),
                    const SizedBox(height: 16),
                    _buildClassesCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveCard() {
    final isTflite = _active == 'tflite';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isTflite ? AppColors.primary.withValues(alpha: 0.12) : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(isTflite ? '⚡' : '🧠', style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Model', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  Text(
                    (_active ?? '').toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isTflite ? AppColors.primary : AppColors.accent,
                    ),
                  ),
                  Text(
                    isTflite ? '5 classes · Fast · Edge-optimised' : '6 classes · Higher accuracy',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _messageIsError
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.healthy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _messageIsError
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.healthy.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _messageIsError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: _messageIsError ? AppColors.error : AppColors.healthy,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                fontSize: 13,
                color: _messageIsError ? AppColors.error : AppColors.healthy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Model', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 14),
            _ModelTile(
              modelKey: 'tflite',
              emoji: '⚡',
              title: 'TFLite',
              subtitle: 'Edge-optimised · 5 disease classes\nFaster inference · Lower memory',
              selected: _selected == 'tflite',
              isActive: _active == 'tflite',
              color: AppColors.primary,
              onTap: () => setState(() => _selected = 'tflite'),
            ),
            const SizedBox(height: 10),
            _ModelTile(
              modelKey: 'keras',
              emoji: '🧠',
              title: 'Keras',
              subtitle: 'TensorFlow .keras · 6 disease classes\nHigher accuracy · More memory',
              selected: _selected == 'keras',
              isActive: _active == 'keras',
              color: AppColors.accent,
              onTap: () => setState(() => _selected = 'keras'),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: _saving ? 'Switching…' : 'Apply Model Switch',
              onPressed: (_selected == _active || _saving) ? null : _apply,
              isLoading: _saving,
              icon: Icons.swap_horiz_rounded,
              color: (_selected == _active) ? AppColors.textLight : AppColors.primary,
            ),
            if (_selected == _active)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This model is already active.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Output Classes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 12),
            if (_classes.isEmpty)
              const Text('Could not load class list — check model file.',
                  style: TextStyle(fontSize: 13, color: AppColors.textLight))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _classes.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final String modelKey;
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ModelTile({
    required this.modelKey,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                          child: const Text('ACTIVE', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? color : AppColors.border,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
