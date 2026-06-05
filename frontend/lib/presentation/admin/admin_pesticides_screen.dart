import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/pesticide_model.dart';
import '../../data/models/disease_model.dart';
import '../../widgets/common_widgets.dart';

class AdminPesticidesScreen extends StatefulWidget {
  const AdminPesticidesScreen({super.key});
  @override
  State<AdminPesticidesScreen> createState() => _AdminPesticidesScreenState();
}

class _AdminPesticidesScreenState extends State<AdminPesticidesScreen> {
  List<PesticideModel> _pesticides = [];
  List<DiseaseModel>   _diseases   = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getAdminPesticides(),
        ApiService().getAdminDiseases(),
      ]);
      if (!mounted) return;
      final pRaw = (results[0]['pesticides'] as List<dynamic>?) ?? [];
      final dRaw = (results[1]['diseases'] as List<dynamic>?) ?? [];
      setState(() {
        _pesticides = pRaw.map((e) => PesticideModel.fromJson(e as Map<String, dynamic>)).toList();
        _diseases   = dRaw.map((e) => DiseaseModel.fromJson(e as Map<String, dynamic>)).toList();
        _loading    = false;
      });
    } on DioException { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _delete(PesticideModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pesticide'),
        content: Text('Delete "${p.pesticideName}"?'),
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
      await ApiService().deletePesticide(p.id);
      _load();
    }
  }

  void _showForm({PesticideModel? pesticide}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PesticideForm(pesticide: pesticide, diseases: _diseases, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pesticides'), backgroundColor: AppColors.accent),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Pesticide', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _pesticides.isEmpty
              ? EmptyState(
                  message: 'No pesticides found.',
                  icon: Icons.science_outlined,
                  onAction: () => _showForm(),
                  actionLabel: 'Add Pesticide',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _pesticides.length,
                    itemBuilder: (_, i) => _PesticideCard(
                      pesticide: _pesticides[i],
                      onEdit:   () => _showForm(pesticide: _pesticides[i]),
                      onDelete: () => _delete(_pesticides[i]),
                    ),
                  ),
                ),
    );
  }
}

class _PesticideCard extends StatelessWidget {
  final PesticideModel pesticide;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PesticideCard({required this.pesticide, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.science_rounded, color: AppColors.accent, size: 22),
        ),
        title: Text(pesticide.pesticideName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
        subtitle: Text('For: ${pesticide.diseaseName}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block('Dosage', pesticide.dosage, AppColors.primary),
                const SizedBox(height: 8),
                _block('Application Method', pesticide.applicationMethod, AppColors.secondary),
                const SizedBox(height: 8),
                _block('Recommendation', pesticide.recommendation, AppColors.accent),
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

  Widget _block(String title, String content, Color color) {
    return Container(
      width: double.infinity,
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

class _PesticideForm extends StatefulWidget {
  final PesticideModel? pesticide;
  final List<DiseaseModel> diseases;
  final VoidCallback onSaved;
  const _PesticideForm({this.pesticide, required this.diseases, required this.onSaved});

  @override
  State<_PesticideForm> createState() => _PesticideFormState();
}

class _PesticideFormState extends State<_PesticideForm> {
  final _formKey   = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.pesticide?.pesticideName ?? '');
  late final _doseCtrl = TextEditingController(text: widget.pesticide?.dosage ?? '');
  late final _appCtrl  = TextEditingController(text: widget.pesticide?.applicationMethod ?? '');
  late final _recCtrl  = TextEditingController(text: widget.pesticide?.recommendation ?? '');
  int? _selectedDiseaseId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDiseaseId = widget.pesticide?.diseaseId ?? (widget.diseases.isNotEmpty ? widget.diseases.first.id : null);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _doseCtrl, _appCtrl, _recCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiseaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a disease.')));
      return;
    }
    setState(() => _loading = true);
    final data = {
      'disease_id':         _selectedDiseaseId,
      'pesticide_name':     _nameCtrl.text.trim(),
      'dosage':             _doseCtrl.text.trim(),
      'application_method': _appCtrl.text.trim(),
      'recommendation':     _recCtrl.text.trim(),
    };
    try {
      final api = ApiService();
      final res = widget.pesticide != null
          ? await api.updatePesticide(widget.pesticide!.id, data)
          : await api.addPesticide(data);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.pesticide != null ? 'Pesticide updated!' : 'Pesticide added!'),
              backgroundColor: AppColors.secondary));
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
              Text(widget.pesticide != null ? 'Edit Pesticide' : 'Add New Pesticide',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: _selectedDiseaseId,
                decoration: const InputDecoration(labelText: 'Disease', prefixIcon: Icon(Icons.local_hospital_outlined)),
                items: widget.diseases.map((d) => DropdownMenuItem(value: d.id, child: Text(d.diseaseName))).toList(),
                onChanged: (v) => setState(() => _selectedDiseaseId = v),
                validator: (v) => v == null ? 'Select a disease' : null,
              ),
              const SizedBox(height: 14),
              _field(_nameCtrl, 'Pesticide Name', Icons.science_outlined),
              const SizedBox(height: 14),
              _field(_doseCtrl, 'Dosage', Icons.medication_outlined, maxLines: 2),
              const SizedBox(height: 14),
              _field(_appCtrl, 'Application Method', Icons.spa_outlined, maxLines: 3),
              const SizedBox(height: 14),
              _field(_recCtrl, 'Recommendation', Icons.recommend_outlined, maxLines: 3),
              const SizedBox(height: 20),
              AppButton(
                label: widget.pesticide != null ? 'Update Pesticide' : 'Add Pesticide',
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
}
