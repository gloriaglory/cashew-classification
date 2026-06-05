import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAdminUsers(search: _searchCtrl.text.trim());
      if (mounted && res['success'] == true) {
        setState(() { _users = res['users'] as List<dynamic>? ?? []; _loading = false; });
      }
    } on DioException { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users'), backgroundColor: AppColors.accent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, username or email…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
              onChanged: (_) => Future.delayed(const Duration(milliseconds: 500), _load),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_users.length} user${_users.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _users.isEmpty
                    ? const EmptyState(message: 'No users found.', icon: Icons.people_outline_rounded)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _users.length,
                          itemBuilder: (_, i) => _UserCard(user: _users[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = (user['is_active'] as int?) == 1;
    final name = user['full_name'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    String createdAt = '';
    try {
      createdAt = DateFormat('dd MMM yyyy').format(DateTime.parse(user['created_at'] as String? ?? ''));
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accent.withOpacity(0.15),
              child: Text(initial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.healthy.withOpacity(0.12) : AppColors.diseased.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(isActive ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.healthy : AppColors.diseased)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text('@${user['username'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                  Text(user['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${user['total_detections'] ?? 0} scans',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(createdAt, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
