import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats        = {};
  List<dynamic>        _monthly      = [];
  List<dynamic>        _distribution = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAdminStats();
      if (mounted && res['success'] == true) {
        setState(() {
          _stats        = (res['stats'] as Map<String, dynamic>?) ?? {};
          _monthly      = (res['monthly_detections'] as List<dynamic>?) ?? [];
          _distribution = (res['disease_distribution'] as List<dynamic>?) ?? [];
          _loading      = false;
        });
      }
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clearAdmin();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.accent,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    if (_distribution.isNotEmpty) ...[
                      _buildDiseaseChart(),
                      const SizedBox(height: 24),
                    ],
                    if (_monthly.isNotEmpty) _buildMonthlyChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    final items = [
      _DrawerItem('Dashboard',   Icons.dashboard_rounded,       '/admin/dashboard'),
      _DrawerItem('Users',       Icons.people_alt_rounded,      '/admin/users'),
      _DrawerItem('Activities',  Icons.list_alt_rounded,        '/admin/activities'),
      _DrawerItem('Diseases',    Icons.local_hospital_rounded,  '/admin/diseases'),
      _DrawerItem('Pesticides',  Icons.science_rounded,         '/admin/pesticides'),
      _DrawerItem('AI Model',    Icons.model_training_rounded,  '/admin/model'),
    ];
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.accent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 40, color: Colors.white),
                const SizedBox(height: 10),
                const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('CashewCare AI', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
          ),
          ...items.map((i) => ListTile(
            leading: Icon(i.icon, color: AppColors.accent),
            title: Text(i.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != i.route) {
                Navigator.pushNamed(context, i.route);
              }
            },
          )),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF92400E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('CashewCare AI Management', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final s = _stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        StatCard(label: 'Total Users',      value: '${s['total_users'] ?? 0}',      icon: Icons.people_alt_rounded,        color: AppColors.accent),
        StatCard(label: 'Total Detections', value: '${s['total_detections'] ?? 0}', icon: Icons.qr_code_scanner_rounded,   color: AppColors.primary),
        StatCard(label: 'Healthy Leaves',   value: '${s['healthy_leaves'] ?? 0}',   icon: Icons.check_circle_rounded,      color: AppColors.healthy),
        StatCard(label: 'Diseased Leaves',  value: '${s['diseased_leaves'] ?? 0}',  icon: Icons.warning_amber_rounded,     color: AppColors.diseased),
      ],
    );
  }

  Widget _buildDiseaseChart() {
    final total = _distribution.fold<int>(0, (s, e) => s + (e['count'] as int? ?? 0));
    if (total == 0) return const SizedBox.shrink();

    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.diseased, const Color(0xFF6366F1), AppColors.healthy];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disease Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(_distribution.length, (i) {
                    final item = _distribution[i];
                    final count = item['count'] as int? ?? 0;
                    return PieChartSectionData(
                      value: count.toDouble(),
                      title: '${(count / total * 100).toStringAsFixed(1)}%',
                      color: colors[i % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }),
                  sectionsSpace: 3,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(_distribution.length, (i) {
                final item = _distribution[i];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 6),
                    Text('${item['disease_name']} (${item['count']})', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthly.isEmpty) return const SizedBox.shrink();
    final reversed = _monthly.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Detections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(reversed.length, (i) {
                    final count = (reversed[i]['count'] as int? ?? 0).toDouble();
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: count, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4)),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= reversed.length) return const SizedBox.shrink();
                          final month = (reversed[idx]['month'] as String? ?? '').split('-');
                          return Text(month.length > 1 ? month[1] : '', style: const TextStyle(fontSize: 10, color: AppColors.textLight));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final IconData icon;
  final String route;
  const _DrawerItem(this.label, this.icon, this.route);
}
