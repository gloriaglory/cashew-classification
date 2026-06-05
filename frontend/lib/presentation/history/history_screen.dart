import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/detection_model.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _sort   = 'desc';
  String _filter = 'all';
  List<DetectionModel> _items = [];
  bool _loading = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getHistory(
        search: _searchCtrl.text.trim(),
        sort:   _sort,
        filter: _filter,
      );
      if (mounted && res['success'] == true) {
        final raw = res['history'] as List<dynamic>? ?? [];
        setState(() {
          _items = raw.map((e) => DetectionModel.fromJson(e as Map<String, dynamic>)).toList();
          _total = res['total'] as int? ?? _items.length;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) { setState(() => _sort = v); _load(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'desc', child: Text('Newest First')),
              const PopupMenuItem(value: 'asc',  child: Text('Oldest First')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) { setState(() => _filter = v); _load(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all',      child: Text('All')),
              const PopupMenuItem(value: 'healthy',  child: Text('Healthy Only')),
              const PopupMenuItem(value: 'diseased', child: Text('Diseased Only')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by disease name…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
              onChanged: (_) => Future.delayed(const Duration(milliseconds: 500), _load),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text('$_total result${_total != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                const Spacer(),
                _FilterChip(label: 'All',      selected: _filter == 'all',      onTap: () { setState(() => _filter = 'all');      _load(); }),
                const SizedBox(width: 6),
                _FilterChip(label: 'Healthy',  selected: _filter == 'healthy',  onTap: () { setState(() => _filter = 'healthy');  _load(); }, color: AppColors.healthy),
                const SizedBox(width: 6),
                _FilterChip(label: 'Diseased', selected: _filter == 'diseased', onTap: () { setState(() => _filter = 'diseased'); _load(); }, color: AppColors.diseased),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        message: 'No detections found.\nScan a cashew leaf to get started.',
                        onAction: () => Navigator.pushNamed(context, '/scan'),
                        actionLabel: 'Scan Now',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _items.length,
                          itemBuilder: (_, i) => _HistoryCard(
                            item: _items[i],
                            onTap: () => _showDetail(_items[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetail(DetectionModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DetailSheet(item: item),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DetectionModel item;
  final VoidCallback onTap;

  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.isHealthy ? AppColors.healthy : AppColors.diseased;
    final icon  = item.isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.diseaseName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    ConfidenceBadge(confidence: item.confidenceScore),
                    const SizedBox(height: 4),
                    Text(_formatDate(item.detectionDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _DetailSheet extends StatelessWidget {
  final DetectionModel item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (item.imagePath.isNotEmpty && File(item.imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(item.imagePath), height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  item.isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: item.isHealthy ? AppColors.healthy : AppColors.diseased,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.diseaseName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConfidenceBadge(confidence: item.confidenceScore),
            const SizedBox(height: 16),
            if (item.description?.isNotEmpty == true)
              InfoRow(icon: Icons.info_outline_rounded, title: 'Description', content: item.description!),
            if (item.symptoms?.isNotEmpty == true && !item.isHealthy)
              InfoRow(icon: Icons.medical_information_outlined, title: 'Symptoms', content: item.symptoms!, iconColor: AppColors.diseased),
            if (item.pesticideName?.isNotEmpty == true && !item.isHealthy)
              InfoRow(icon: Icons.science_outlined, title: 'Pesticide', content: item.pesticideName!, iconColor: AppColors.accent),
            if (item.dosage?.isNotEmpty == true && !item.isHealthy)
              InfoRow(icon: Icons.medication_outlined, title: 'Frequency', content: item.dosage!, iconColor: AppColors.primary),
            if (item.prevention?.isNotEmpty == true)
              InfoRow(icon: Icons.shield_outlined, title: 'Prevention', content: item.prevention!, iconColor: AppColors.secondary),
            const SizedBox(height: 8),
            AppButton(label: 'Close', onPressed: () => Navigator.pop(context), color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
