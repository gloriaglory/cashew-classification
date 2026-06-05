

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminActivitiesScreen extends StatefulWidget {
  const AdminActivitiesScreen({super.key});
  @override
  State<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends State<AdminActivitiesScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';
  List<dynamic> _activities = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAdminActivities(
        search: _searchCtrl.text.trim(),
        filter: _filter,
      );
      if (mounted && res['success'] == true) {
        setState(() { _activities = res['activities'] as List<dynamic>? ?? []; _loading = false; });
      }
    } on DioException { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _deleteActivity(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Remove this activity record?'),
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
      await ApiService().deleteActivity(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activities'),
        backgroundColor: AppColors.accent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) { setState(() => _filter = v == 'ALL' ? '' : v); _load(); },
            itemBuilder: (_) => ['ALL', 'LOGIN', 'LOGOUT', 'REGISTER', 'DETECTION']
                .map((t) => PopupMenuItem(value: t, child: Text(t))).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by user name or username…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
              onChanged: (_) => Future.delayed(const Duration(milliseconds: 500), _load),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['', 'DETECTION', 'LOGIN', 'LOGOUT', 'REGISTER'].map((f) {
                  final label = f.isEmpty ? 'All' : f;
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _filter = f); _load(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accent : AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withOpacity(selected ? 1 : 0.3)),
                        ),
                        child: Text(label, style: TextStyle(
                          color: selected ? Colors.white : AppColors.accent,
                          fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${_activities.length} records', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _activities.isEmpty
                    ? const EmptyState(message: 'No activities found.', icon: Icons.list_alt_rounded)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _activities.length,
                          itemBuilder: (_, i) {
                            final a = _activities[i] as Map<String, dynamic>;
                            return _ActivityCard(
                              activity: a,
                              onDelete: () => _deleteActivity(a['id'] as int),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onDelete;
  const _ActivityCard({required this.activity, required this.onDelete});

  static const _typeColors = {
    'DETECTION': AppColors.primary,
    'LOGIN':     AppColors.secondary,
    'LOGOUT':    AppColors.textLight,
    'REGISTER':  Color(0xFF6366F1),
  };

  static const _typeIcons = {
    'DETECTION': Icons.qr_code_scanner_rounded,
    'LOGIN':     Icons.login_rounded,
    'LOGOUT':    Icons.logout_rounded,
    'REGISTER':  Icons.person_add_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final type  = activity['activity_type'] as String? ?? '';
    final color = _typeColors[type] ?? AppColors.textLight;
    final icon  = _typeIcons[type] ?? Icons.info_outline_rounded;
    String ts = '';
    try {
      ts = DateFormat('dd MMM yyyy  •  hh:mm a').format(DateTime.parse(activity['timestamp'] as String? ?? ''));
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(activity['user_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(activity['description'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text(ts, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  if ((activity['disease_name'] as String?)?.isNotEmpty == true)
                    Text('Disease: ${activity['disease_name']}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
