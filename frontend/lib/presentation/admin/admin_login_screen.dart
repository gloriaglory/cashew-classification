import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService().adminLogin(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (res['success'] == true) {
        await StorageService.saveAdminToken(res['token'] as String);
        await StorageService.setIsAdmin(true);
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else {
        _showError(res['message'] as String? ?? 'Login failed.');
      }
    } on DioException catch (e) {
      if (mounted) _showError(e.response?.data?['message'] as String? ?? 'Login failed. Check connection.');
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF78350F), Color(0xFF92400E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('Admin Portal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Cashew AI App', style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Staff accounts only',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _userCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Admin Username',
                                prefixIcon: Icon(Icons.manage_accounts_rounded),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              label: 'Admin Sign In',
                              onPressed: _login,
                              isLoading: _loading,
                              icon: Icons.login_rounded,
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('← Back to User Login',
                                  style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
