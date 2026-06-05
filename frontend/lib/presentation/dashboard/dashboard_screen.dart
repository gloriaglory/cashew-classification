import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  Map<String, dynamic> _stats = {'total_scans': 0, 'healthy_leaves': 0, 'diseased_leaves': 0};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  void _loadUser() {
    final raw = StorageService.getUser();
    if (raw != null) setState(() => _user = UserModel.fromJson(raw));
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final res = await ApiService().getDashboardStats();
      if (mounted && res['success'] == true) {
        setState(() {
          _stats = (res['stats'] as Map<String, dynamic>?) ?? _stats;
          _loadingStats = false;
        });
      } else {
        if (mounted) setState(() => _loadingStats = false);
      }
    } on DioException {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.clearUser();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cashew AI App'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () => Navigator.pushNamed(context, '/profile').then((_) => _loadUser())),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcome(),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 28),
              _buildMenuGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome,', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                Text(_user?.fullName ?? 'Farmer', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Ready to scan your cashew leaves?', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Statistics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        if (_loadingStats)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              StatCard(label: 'Total Scans', value: '${_stats['total_scans'] ?? 0}', icon: Icons.qr_code_scanner_rounded, color: AppColors.primary),
              StatCard(label: 'Healthy', value: '${_stats['healthy_leaves'] ?? 0}', icon: Icons.check_circle_outline_rounded, color: AppColors.healthy),
              StatCard(label: 'Diseased', value: '${_stats['diseased_leaves'] ?? 0}', icon: Icons.warning_amber_rounded, color: AppColors.diseased),
            ],
          ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final items = [
      _MenuItem(label: 'Scan Leaf',    icon: Icons.camera_alt_rounded,     color: AppColors.primary,            route: '/scan'),
      _MenuItem(label: 'Upload Image', icon: Icons.upload_file_rounded,     color: AppColors.secondary,          route: '/scan', args: 'gallery'),
      _MenuItem(label: 'History',      icon: Icons.history_rounded,         color: AppColors.accent,             route: '/history'),
      _MenuItem(label: 'Profile',      icon: Icons.manage_accounts_rounded, color: const Color(0xFF6366F1),      route: '/profile'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.35,
          children: items.map((item) => _buildMenuCard(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route, arguments: item.args).then((_) => _loadStats()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: item.color)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final Object? args;
  const _MenuItem({required this.label, required this.icon, required this.color, required this.route, this.args});
}
