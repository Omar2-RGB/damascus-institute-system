import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../admin/admin_home_screen.dart';
import '../../student/student_home_screen.dart';
import '../../../core/theme/app_colors.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true; 

  // --- دالة تعقيم رسائل الخطأ الأجنبية ---
  String _sanitizeError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('invalid login credentials') || str.contains('invalid_grant')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (str.contains('network') || str.contains('socket') || str.contains('failed host')) {
      return 'تأكد من اتصالك بالإنترنت وحاول مجدداً';
    }
    return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // إخفاء الكيبورد فوراً لإعطاء مساحة للأنيميشن
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (!mounted) return;

      final route = auth.isAdmin ? const AdminHomeScreen() : const StudentHomeScreen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => route),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_sanitizeError(e), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final fieldFillColor = isDark ? const Color(0xFF131C2E) : Colors.white;
    final fieldBorderColor = isDark ? const Color(0xFF222F4A) : Colors.grey.shade200;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. The University Crest ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12), blurRadius: 28, offset: const Offset(0, 12)),
                        ],
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.blue.shade50, width: 2),
                      ),
                      child: const Icon(Icons.account_balance_rounded, size: 54, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 2. Titles ---
                  Text(
                    'المعهد التقاني للحاسوب',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: const Text(
                        'جامعة دمشق • فرع درعا',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),

                  // --- 3. Email Field ---
                  TextFormField(
                    controller: _emailController,
                    textInputAction: TextInputAction.next, 
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary, size: 18),
                      filled: true, fillColor: fieldFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: fieldBorderColor, width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'البريد الإلكتروني مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- 4. Password Field with Toggle ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => auth.isLoading ? null : _login(), 
                    style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.lightTextMuted, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true, fillColor: fieldFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: fieldBorderColor, width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'كلمة المرور مطلوبة' : null,
                  ),
                  const SizedBox(height: 32),

                  // --- 5. Action Button ---
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      onPressed: auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('تسجيل الدخول', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'تواجه مشكلة في الدخول؟ راجع شؤون الطلاب في المعهد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted, fontWeight: FontWeight.w600),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}