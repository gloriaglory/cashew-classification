import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/disease_model.dart';
import '../../widgets/common_widgets.dart';

class AdminDiseasesScreen extends StatefulWidget {
  const AdminDiseasesScreen({super.key});
  @override
  State<AdminDiseasesScreen> createState() => _AdminDiseasesScreenState();
}

class _AdminDiseasesScreenState extends State<AdminDiseasesScreen> {
  List<DiseaseModel> _diseases = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAdminDiseases();
      if (mounted && res['success'] == true) {
        final raw = res['diseases'] as List<dynamic>? ?? [];
        setState(() {
          _diseases = raw.map((e) => DiseaseModel.fromJson(e as Map<String, dynamic>)).toList();
          _loading  = false;
        });
      }
    } on DioException { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _delete(DiseaseModel d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Disease'),
        content: Text('Delete "${d.diseaseName}"? This will also remove related pesticides and detections.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService().deleteDisease(d.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Disease deleted.'), backgroundColor: AppColors.secondary));
          _load();
        }
      } on DioException { /**/ }
    }
  }

  void _showForm({DiseaseModel? disease}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DiseaseForm(disease: disease, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Diseases'), backgroundColor: AppColors.accent),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Disease', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _diseases.isEmpty
              ? EmptyState(
                  message: 'No diseases found.',
                  icon: Icons.local_hospital_outlined,
                  onAction: () => _showForm(),
                  actionLabel: 'Add Disease',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _diseases.length,
                    itemBuilder: (_, i) => _DiseaseCard(
                      disease: _diseases[i],
                      onEdit:   () => _showForm(disease: _diseases[i]),
                      onDelete: () => _delete(_diseases[i]),
                    ),
                  ),
                ),
    );
  }
}

class _DiseaseCard extends StatelessWidget {
  final DiseaseModel disease;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DiseaseCard({required this.disease, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 22),
        ),
        title: Text(disease.diseaseName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
        subtitle: Text(disease.description, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBlock('Symptoms', disease.symptoms, AppColors.diseased),
                const SizedBox(height: 8),
                _infoBlock('Prevention', disease.prevention, AppColors.secondary),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4)),
        ],
      ),
    );
  }
}

class _DiseaseForm extends StatefulWidget {
  final DiseaseModel? disease;
  final VoidCallback onSaved;
  const _DiseaseForm({this.disease, required this.onSaved});

  @override
  State<_DiseaseForm> createState() => _DiseaseFormState();
}

class _DiseaseFormState extends State<_DiseaseForm> {
  final _formKey    = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.disease?.diseaseName ?? '');
  late final _descCtrl  = TextEditingController(text: widget.disease?.description ?? '');
  late final _sympCtrl  = TextEditingController(text: widget.disease?.symptoms ?? '');
  late final _prevCtrl  = TextEditingController(text: widget.disease?.prevention ?? '');
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _sympCtrl, _prevCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'disease_name': _nameCtrl.text.trim(),
      'description':  _descCtrl.text.trim(),
      'symptoms':     _sympCtrl.text.trim(),
      'prevention':   _prevCtrl.text.trim(),
    };
    try {
      final api = ApiService();
      final res = widget.disease != null
          ? await api.updateDisease(widget.disease!.id, data)
          : await api.addDisease(data);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.disease != null ? 'Disease updated!' : 'Disease added!'),
              backgroundColor: AppColors.secondary));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] as String? ?? 'Error.'), backgroundColor: AppColors.error));
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message'] as String? ?? 'Error.'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.disease != null ? 'Edit Disease' : 'Add New Disease',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 18),
              _field(_nameCtrl, 'Disease Name', Icons.local_hospital_outlined, maxLines: 1),
              _gap(),
              _field(_descCtrl, 'Description', Icons.description_outlined, maxLines: 3),
              _gap(),
              _field(_sympCtrl, 'Symptoms', Icons.medical_information_outlined, maxLines: 3),
              _gap(),
              _field(_prevCtrl, 'Prevention Measures', Icons.shield_outlined, maxLines: 3),
              const SizedBox(height: 20),
              AppButton(
                label: widget.disease != null ? 'Update Disease' : 'Add Disease',
                onPressed: _save,
                isLoading: _loading,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), alignLabelWithHint: maxLines > 1),
        validator: (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      );

  Widget _gap() => const SizedBox(height: 14);
}
