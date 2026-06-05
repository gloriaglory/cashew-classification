import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _userCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _userCtrl, _phoneCtrl, _emailCtrl, _passCtrl, _confCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService().register({
        'full_name': _nameCtrl.text.trim(),
        'username':  _userCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
        'password':  _passCtrl.text,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        await StorageService.saveToken(res['token'] as String);
        final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await StorageService.saveUser(user.toJson());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created!'), backgroundColor: AppColors.secondary));
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError(res['message'] as String? ?? 'Registration failed.');
      }
    } on DioException catch (e) {
      if (mounted) _showError(e.response?.data?['message'] as String? ?? 'Registration failed. Check connection.');
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
      appBar: AppBar(title: const Text('Create Account'), leading: const BackButton()),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildIcon(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(gradient: AppColors.greenGradient, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.person_add_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text('Join Cashew AI App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const Text('Create your farmer account', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter full name' : null),
              _gap(),
              _field(ctrl: _userCtrl, label: 'Username', icon: Icons.alternate_email_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter username';
                  if (v.trim().length < 3) return 'Minimum 3 characters';
                  return null;
                }),
              _gap(),
              _field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined,
                type: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null),
              _gap(),
              _field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                }),
              _gap(),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter password';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              _gap(),
              TextFormField(
                controller: _confCtrl,
                obscureText: _obscureConf,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConf = !_obscureConf),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm your password';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Create Account', onPressed: _register, isLoading: _loading, icon: Icons.check_circle_outline_rounded),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textMedium)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
        textInputAction: TextInputAction.next,
      );

  Widget _gap() => const SizedBox(height: 14);
}
